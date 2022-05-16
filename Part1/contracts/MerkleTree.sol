//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root


    //Test function to verify and debug parsing logic
    function dummyTestPoseidon(uint256[2] memory input) public pure returns(uint256) {
        return input[0] + input[1];
    }

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        hashes = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        uint8 i=0;
        for(uint8 k=8; k<15; k++) {
            // Generate hashes and propogate to root.
            hashes[k] = PoseidonT3.poseidon([hashes[i], hashes[i+1]]);
            // hashes[k] = dummyTestPoseidon([hashes[i], hashes[i+1]]);
            i++;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index<8, "Tree overflow");          // Cannot insert if leaf nodes are full

        uint8[4] memory levelRanges = [0, 8, 12, 14];   // Start index for each level.
        uint256 idx = index;                            // index in array
        uint256 offset = index/2;                       // offset at current level
        uint256 parentHash;                             // Hash value to be stored in parent node. 
        hashes[idx] = hashedLeaf;

        // will itereate through all levels and update hashes for parent nodes. 
        for(uint256 i = 1; i<=3; i++) {
            if(idx%2 == 0) {
                // adding as left node
                parentHash = PoseidonT3.poseidon([hashes[idx], hashes[idx+1]]);
                // parentHash = dummyTestPoseidon([hashes[idx], hashes[idx+1]]);
            } else {
                // adding as right node
                parentHash = PoseidonT3.poseidon([hashes[idx-1], hashes[idx]]);
                // parentHash = dummyTestPoseidon([hashes[idx-1], hashes[idx]]);
            }
            idx = levelRanges[i] + offset;                // compute index of parent node and assign hash value.
            hashes[idx] = parentHash;
            offset = offset/2;
        }
        root = hashes[hashes.length-1];                   // update root and increment the index till the leaf nodes are filled.
        index++;
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        verifyProof(a, b, c, input);
        return (input[0] == root);
    }
}
