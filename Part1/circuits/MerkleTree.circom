pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template LevelParser(nodeCount) {
    signal input nodes[nodeCount];
    signal output parent[nodeCount/2];

    component poseidon = Poseidon(2);
    for(var i=0; i<nodeCount; i+=2) {
        poseidon.inputs[0] <== nodes[i];
        poseidon.inputs[1] <== nodes[i+1];
        parent[i/2] <== poseidon.out;
    }
}

template CheckRootRecursive(n) { // compute the root of a MerkleTree of n Levels 
    // This is a recursive implementation, this is discarded in favour of the implementation of 'CheckRoot' provided below. 
    signal input leaves[2**n];
    signal output root;

    component levelParser = LevelParser(2**n);
    component checkParentRoots = CheckRoot(n/2);
    signal parentLevel[2**(n-1)];
    for(var i=0; i<2**n; i++) {
        levelParser.nodes[i] <== leaves[i];
    }
    parentLevel = levelParser.parent;

    if(n==1) {
        root === parentLevel[0];
    } else {
        for(var i=0; i<2**n-1; i++) {
            checkParentRoots.leaves[i] <== parentLevel[i];
        }
        root === checkParentRoots.root;
    }
}

template CheckRoot(n) {  // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var numLeafNodes = 2**n;
    var numNonLeafNodes = (2**n) - 1;
    var numTotalNodes = numLeafNodes + numNonLeafNodes;
    var i = 0;

    component poseidonHasher[numNonLeafNodes] = Poseidon(2);
    signal treeBuffer[numNonLeafNodes];
    
    for(i=0; i<numLeafNodes; i++) {             // process all leaf nodes into hasher and assign their output to treeBuffer(0-7)
        poseidonHasher[i].inputs[0] <== leaves[i*2];
        poseidonHasher[i].inputs[1] <== leaves[i*2+1];
        treeBuffer[i] <== poseidonHasher[i].out;
    }

    for(var p=0; p<numNonLeafNodes; p++) {      // Process non-leaf nodes and assign output to treeBuffer (node 8..onwards)
        poseidonHasher[i].inputs[0] <== treeBuffer[p*2];
        poseidonHasher[i].inputs[1] <== treeBuffer[p*2+1];
        treeBuffer[i] <== poseidonHasher[i].out;
        i++;
    }

    root === treeBuffer[numTotalNodes - 1];
}

// Function to select one of the two values (a/b) based on selector
// select == 1 -> return a
// select == 0 -> return b
function nodeSelector(select, a, b) {
    return select * (a - b) + b;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    
    // create n hasher functions and n+1 intermediate values values
    component poseidonHasher[n];
    signal computedHash[n+1];
    computedHash[0] <== leaf;

    for (var i=0; i<n; i++) {
        poseidonHasher[i] = Poseidon(2);
        // select input elements order based on their position in tree. i.e. by path_index of i'th node.  
        poseidonHasher[i].inputs[0] <== nodeSelector(path_index[i], path_elements[i], computedHash[i]);
        poseidonHasher[i].inputs[1] <== nodeSelector(path_index[i], computedHash[i], path_elements[i]);
        computedHash[i+1] <== poseidonHasher[i].out;
    }
    root <== computedHash[n];
}