// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {MerkleProof} from "./Merkleproof.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";


contract KodakToken is ERC20,Ownable(msg.sender),ERC20Permit, ERC20Votes{
    using BitMaps for BitMaps.BitMap;

    uint public constant MINIMUMMINTINTERVAL = 365 days;
    uint public constant MINTCAP = 200; //2%
    bytes32 public merkleRoot;
    uint public nextMint; //timestamp
    uint public claimPeriodsEnds; //timestamp
    BitMaps.BitMap private claimed;

    event Claim (address indexed claimant, uint amount);
    event MerkleRootChanged(bytes32 merkleRoot);

    




    constructor(uint freesupply, uint airdropsupply, uint _claimPeriodEnds) ERC20("KodakToken","KDT") ERC20Permit("KodakToken") {
        _mint(msg.sender,freesupply);
        _mint(address(this), airdropsupply);
        claimPeriodsEnds = _claimPeriodEnds;
        nextMint = block.timestamp + MINIMUMMINTINTERVAL;
    }

    /**
    @dev claims airdrop tokens
    @param amount of claim
    @param delegate address tokenHolder wants to delegate their votes to.
    @param merkleproof proof proving the claim is valid
     */

    function claimTokens(uint amount, address delegate, bytes32[] calldata merkleproof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        (bool valid, uint256 index) = MerkleProof.verify(merkleproof,merkleRoot,leaf);
        require(valid, "ENS:Proof Failed");
        require(!isClaimed(index), "ENS: Tokens already claimed");

        claimed.set(index); //@audit how can DOS via index???
        emit Claim(msg.sender,amount);

        _delegate(msg.sender,delegate);
        _transfer(address(this), msg.sender, amount);


    }

    function sweep(address dest) external onlyOwner {
        require(block.timestamp > claimPeriodsEnds, "ENS: claim period not ended");
        _transfer(address(this),dest, balanceOf(address(this)));
    }

    //return true if claim at index in merkle tree is already taken

    function isClaimed(uint index) public view returns (bool) {
        return claimed.get(index);
    }
    
    //sets merkleroot.  Only callable if not set
    //@audit too one-time for a vital parameter
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(merkleRoot == bytes32(0), "ENS: Merkle already set");
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function mint (address dest, uint amount) external onlyOwner {
        require(amount <= (totalSupply() * MINTCAP) / 10000, "ENS: Mint exceeds maximum amount");
        require(block.timestamp >= nextMint, "ENS: Cannot mint yet");

        nextMint = block.timestamp + MINIMUMMINTINTERVAL;
        _mint(dest, amount);
    }
    // =============================Overrides required by solidity===========================

    // function _afterTokenTransfer(address from, address to, uint256 amount)
    //     internal
    //     override(ERC20, ERC20Votes)
    // {
    //     super._afterTokenTransfer(from, to, amount);
    // }

    // function _mint(address to, uint256 amount)
    //     internal
    //     override(ERC20, ERC20Votes)
    // {
    //     super._mint(to, amount);
    // }

    function _update(address from,address to, uint256 value)internal override(ERC20, ERC20Votes)
    {
        //super._update(account, amount);
    }
    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {}
}