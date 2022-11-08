// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IProposal.sol";


contract Proposal is Initializable, ERC1155, Pausable, Ownable, ERC1155Supply {

    address constant GAURD = address(1);
    uint S;
    uint holders; 
    uint public A;
    uint public B;
    IProposal public nextProposal;


    mapping (address => uint) public balances;
    mapping (address => address) _nextHolders;


    constructor() ERC1155("") {
        _disableInitializers();
    }
    
    function initialize(string memory _uri, address _main, address _admin) public initializer {
        _transferOwnership(_admin);
        _nextHolders[GAURD] = GAURD;
        A=25;
        B=3;
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

    function importToNext(uint _dF, address _buyer) external payable returns(uint) {
        require(_dF == msg.value, "Wrong value, Send the exact price");
        uint supplyId = uint(keccak256(abi.encodePacked(_buyer))); 
        
        // if(balanceOf(_buyer,supplyId) == 0){
        // addHolder(_buyer, _dS);
        // } else {
        // increaseBalance(msg.sender, _dS);
        // }
        // mint(msg.sender, supplyId, _dS, "");

        // S += _dS;
        return(S);
    }

    function Sell(uint _dS) public returns(uint) {
        require(balanceOf(msg.sender,uint(keccak256(abi.encodePacked(msg.sender)))) > 0, "You don't have any token to sell.");
        require(_dS <= balanceOf(msg.sender,uint(keccak256(abi.encodePacked(msg.sender)))), "You don't have this amount of token");

        uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 

        if(_dS == balanceOf(msg.sender,supplyId)){
        removeHolder(msg.sender);
        } else {
        reduceBalance(msg.sender, _dS);
        }
        _burn(msg.sender, supplyId, _dS);
        payable(msg.sender).transfer(sellPrice(_dS));      
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

    function transferToNext(address _nextProposal) external onlyOwner {
    nextProposal =  IProposal(_nextProposal);
    address currentAddress = _nextHolders[GAURD];
    for(uint256 i = 0; i < holders; i++) {
      uint balanceOfCurrent = balanceOf(currentAddress, uint(keccak256(abi.encodePacked(currentAddress))));
      nextProposal.importToNext{gas: 1000000, value: sellPrice(balanceOfCurrent)}(sellPrice(balanceOfCurrent), currentAddress);
      currentAddress = _nextHolders[currentAddress];
    }
    }

   function getArray() public view returns(address[] memory) {
    address[] memory holderList = new address[](holders);
    address currentAddress = _nextHolders[GAURD];
    for(uint256 i = 0; i < holders; i++) {
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
    return address(0);
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
}
