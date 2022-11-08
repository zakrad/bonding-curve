// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Proposal is ERC1155, Pausable, Ownable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("") {}


    mapping (uint => address) public priority;
    uint totalSupply;
    
    uint public A=25;
    uint public B=3;

    modifier onlyCaller(address _sender, uint _supplyId) {
      require(uint(keccak256(abi.encodePacked(_sender))) == _supplyId, "Your id does not match");
      _;
    }

    modifier checkPrice(uint _dF) {
        require(_dF == msg.value, "Send the exact price");
        _;
    }

    function buyPrice(uint _dS) internal returns(uint) {
        uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );
        return dF;
    }

    function Buy(uint _dS) public payable returns(uint) {
        uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 
        
        uint S = totalSupply;
        uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );

        if(balanceOf(msg.sender,supplyId) == 0){

        _mint(msg.sender, supplyId, _dS, "");

        } else if {
        
        mint(msg.sender, supplyId, _dS, "")

        }


        if(Wsender>=dF){
            W[msg.sender]-=dF;
            payable(msg.sender).transfer(msg.value);
        } else {
            uint ExessB = Wsender + msg.value - dF;
            require(ExessB >= 0 , "Insufficient funds!");
            payable(msg.sender).transfer(ExessB);
            W[msg.sender]=0;
            V[msg.sender]+=dF-Wsender;
        }
        totalSupply += _dS;
        return(dF);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
        onlyCaller(account, id)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    receive() external payable {}
}
