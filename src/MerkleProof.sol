// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


//@dev these are for verification of Merkle Trees proofs.


library MerkleProof {
    /**
    returns true if `leaf` is proved to be part of a `root`
    @param proof Array of proofs
    @param root is root of tree
     */
    

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns(bool,uint256) {
        bytes32 computedHash = leaf;
        uint index;
        for(uint i; i< proof.length; i++){
            index *= 2;
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash,proofElement));
                index++;
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement,computedHash));
                index++;
            }
        }
        return (computedHash == root, index);
    }

    /**
    =========SECURITY===========
    `bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));` 
    @note : bytes.concat simply avoids memory. otherwise we have to copy to memory
    double hash prevents 2nd preimage attack (2nd preimage resistant). This creates a fundamental diff btw:
        - A leaf node
        - An intermediary node
    Hence leaves are double-hashed while intermediate nodes are single-hashed

    Verification assumes proof array are all valid. else.....

    Whats the security significance of index.?

    For multiple claim, can check be bypass? 

    Use Assembly to hash (for less gas)
    
     */
    
    
            
}