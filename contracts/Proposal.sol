// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Proposal is ERC1155, Pausable, Ownable, ERC1155Burnable, ERC1155Supply {

    mapping (address => uint) public balances;
    mapping (address => address) _nextHolders;
    uint S;
    uint holders;
    // uint[] balances;
    address constant GAURD = address(1);
    
    uint public A=25;
    uint public B=3;

    constructor() ERC1155("") {
        _nextHolders[GAURD] = GAURD;
    }


    modifier onlyCaller(address _sender, uint _supplyId) {
      require(uint(keccak256(abi.encodePacked(_sender))) == _supplyId, "Your id does not match");
      _;
    }

    function buyPrice(uint _dS) public view returns(uint) {
        uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );
        return dF;
    }

    function sellPrice(uint _dS) public view returns(uint) {
        uint dF = (A*_dS) + (B/3)*( S**3 - (S - _dS)**3 );
        return dF;
    }


    function Buy(uint _dS) public payable returns(uint) {
        require(buyPrice(_dS) == msg.value, "Wrong value, Send the exact price");

        uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 

        if(balanceOf(msg.sender,supplyId) == 0){
        addHolder(msg.sender, _dS);
        } else {
        increaseBalance(msg.sender, _dS);
        }
        mint(msg.sender, supplyId, _dS, "");

        S += _dS;
        return(S);
    }

    function Sell(uint _dS) public payable returns(uint) {
        require(sellPrice(_dS) == msg.value, "Wrong value, Send the exact price");
        require(_dS <= balanceOf(msg.sender,uint(keccak256(abi.encodePacked(msg.sender)))));

        uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 

        if(_dS == balanceOf(msg.sender,supplyId)){
        removeHolder(msg.sender);
        } else {
        reduceBalance(msg.sender, _dS);
        }
        burn(msg.sender, supplyId, _dS);        
        S -= _dS;
        return(S);
    }

    function addHolder(address holder, uint256 balance) public {
    require(_nextHolders[holder] == address(0));
    address index = _findIndex(balance);
    balances[holder] = balance;
    _nextHolders[holder] = _nextHolders[index];
    _nextHolders[index] = holder;
    holders++;
    }

    function removeHolder(address holder) public {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    _nextHolders[prevHolder] = _nextHolders[holder];
    _nextHolders[holder] = address(0);
    balances[holder] = 0;
    holders--;
    }

    function increaseBalance(
    address holder, 
    uint256 balance
  ) public {
    updateBalance(holder, balances[holder] + balance);
  }

  function reduceBalance(
    address holder, 
    uint256 balance
  ) public {
    updateBalance(holder, balances[holder] - balance);
  }

  function updateBalance(
    address holder, 
    uint256 newBalance
  ) public {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    address nextHolder = _nextHolders[holder];
    if(_verifyIndex(prevHolder, newBalance, nextHolder)){
      balances[holder] = newBalance;
    } else {
      removeHolder(holder);
      addHolder(holder, newBalance);
    }
    }

   function getTop(uint256 k) public view returns(address[] memory) {
    require(k <= holders);
    address[] memory holderList = new address[](k);
    address currentAddress = _nextHolders[GAURD];
    for(uint256 i = 0; i < k; i++) {
      holderList[i] = currentAddress;
      currentAddress = _nextHolders[currentAddress];
    }
    return holderList;
    }

    function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = GAURD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextHolders[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextHolders[candidateAddress];
    }
  }


    function _verifyIndex(address prevHolder, uint256 newValue, address nextHolder)
    internal
    view
    returns(bool) {
    return (prevHolder == GAURD || balances[prevHolder] >= newValue) && 
           (nextHolder == GAURD || newValue > balances[nextHolder]);
    }
    
    function _isPrevHolder(address holder, address prevHolder) internal view returns(bool) {
    return _nextHolders[prevHolder] == holder;
    }

    function _findPrevHolder(address holder) internal view returns(address) {
    address currentAddress = GAURD;
    while(_nextHolders[currentAddress] != GAURD) {
      if(_isPrevHolder(holder, currentAddress))
        return currentAddress;
      currentAddress = _nextHolders[currentAddress];
    }
    return address(0);
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
