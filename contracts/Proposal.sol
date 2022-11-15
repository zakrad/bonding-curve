// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IMain.sol";


contract Proposal is Initializable, ERC1155, Pausable, Ownable, ERC1155Supply {

    address constant GAURD = address(1);
    uint public nextId;
    IMain public nextMain;

    mapping (uint => uint) public holders;
    mapping (address => address) _nextHolders;


    constructor() ERC1155("") {
        _disableInitializers();
    }
    
    function initialize(address _admin) public initializer {
        _transferOwnership(_admin);
        _nextHolders[GAURD] = GAURD;
        pause();
    }

    modifier proposalExists(uint _id) {
      require(exists(_id) , "Proposal ID does not exists");
      _;
    }

    function buyPrice(uint _dS, uint _id) public view returns(uint) {
        // uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );
        uint dF = 1000 * (sqrt((totalSupply(_id)+_dS)**2+10**6)-sqrt(totalSupply(_id)**2+10**6));
        return dF;
    }

    function sellPrice(uint _dS, uint _id) public view returns(uint) {
        // uint dF = (A*_dS) + (B/3)*( S**3 - (S - _dS)**3 );
        uint dF = 1000 * (sqrt(totalSupply(_id)**2+10**6)-sqrt((totalSupply(_id)-_dS)**2+10**6));
        return dF;
    }

    function createProposal() public onlyOwner whenPaused{
        _mint(address(this), nextId, 1, "");
        nextId++;
    }

    function Buy(uint _dS, uint _id) whenNotPaused proposalExists(_id) public payable returns(uint) {
        require(buyPrice(_dS, _id) == msg.value, "Wrong value, Send the exact price");
        _mint(msg.sender, _id, _dS, "");
        return(totalSupply(_id));
    }

    function importFromMain(address _buyer, uint _id) proposalExists(_id) external payable returns(uint) {
      // require(isProposal(msg.sender), "Only callable from another proposal");
        uint dS = (sqrt(((10**6)*(totalSupply(_id)**2))+((msg.value)**2)+(2000*msg.value*sqrt(totalSupply(_id)**2+10**6)))-(1000*totalSupply(_id)))/1000;
        _mint(_buyer, _id, dS, "");
        return(totalSupply(_id));
    }

    function Sell(uint _dS, uint _id) whenNotPaused proposalExists(_id) public returns(uint) {
        require(balanceOf(msg.sender, _id) > 0, "You don't have any token in this proposal.");
        require(_dS <= balanceOf(msg.sender, _id), "You don't have this amount of token");
        _burn(msg.sender, _id, _dS);
        payable(msg.sender).transfer(sellPrice(_dS, _id));
        return(totalSupply(_id));
    }

    function addHolder(address holder, uint _id, uint amount) internal {
    require(_nextHolders[holder] == address(0));
    address index = _findIndex(amount, _id);
    _nextHolders[holder] = _nextHolders[index];
    _nextHolders[index] = holder;
    holders[_id]++;
    }

    function removeHolder(address holder, uint _id) internal {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    _nextHolders[prevHolder] = _nextHolders[holder];
    _nextHolders[holder] = address(0);
    holders[_id]--;
    }

  function increaseBalance(
    address holder, 
    uint _id,
    uint amount
  ) internal {
    updateBalance(holder, balanceOf(holder, _id) + amount, _id);
  }

  function reduceBalance(
    address holder, 
    uint _id
  ) internal {
    updateBalance(holder, balanceOf(holder, _id), _id);
  }

  function updateBalance(
    address holder, 
    uint newBalance,
    uint _id
  ) internal {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    address nextHolder = _nextHolders[holder];
    if(!_verifyIndex(prevHolder, newBalance, nextHolder, _id)){
      removeHolder(holder, _id);
      addHolder(holder, _id, newBalance);
    }
  }

  function transferToMain(address _main, uint8[] memory sortedIds) external onlyOwner whenPaused returns(address){
    nextMain =  IMain(_main);
    address currentAddress = _nextHolders[GAURD];
    for(uint8 i=0; i < sortedIds.length; i++){
      for(uint256 j= 0; j < holders[sortedIds[i]]; j++) {
        nextMain.importFromProposal{gas: 1000000, value: sellPrice(balanceOf(currentAddress, sortedIds[i]), sortedIds[i])-1000000}(currentAddress);
        _burn(currentAddress, sortedIds[i], balanceOf(currentAddress, sortedIds[i]));
        currentAddress = _nextHolders[currentAddress];
      }
    }
    return currentAddress;
  }

   function getArray(uint8 _id) public view returns(address[] memory) {
    address[] memory holderList = new address[](holders[_id]);
    address currentAddress = _nextHolders[GAURD];
    for(uint256 i = 0; i < holders[_id]; i++) {
      holderList[i] = currentAddress;
      currentAddress = _nextHolders[currentAddress];
    }
    return holderList;
    }

    function _findIndex(uint256 newValue, uint _id) internal view returns(address) {
    address candidateAddress = GAURD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextHolders[candidateAddress], _id))
        return candidateAddress;
      candidateAddress = _nextHolders[candidateAddress];
    }
    return address(0);
  }


    function _verifyIndex(address prevHolder, uint256 newValue, address nextHolder, uint _id)
    internal
    view
    returns(bool) {
    return (prevHolder == GAURD || balanceOf(prevHolder, _id) >= newValue) && 
           (nextHolder == GAURD || newValue > balanceOf(nextHolder, _id));
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

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if(from != address(0) && to != address(0)){
          if(balanceOf(to, ids[0]) == 0){
                addHolder(to, ids[0], amounts[0]);     
          } else {
                increaseBalance(to, ids[0], amounts[0]);
          }
        } else if(from == address(0)){
            if(balanceOf(to, ids[0]) == 0){
              addHolder(to, ids[0], amounts[0]);
            } else {
              increaseBalance(to, ids[0], amounts[0]);
            }
        }
    }

    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        if(from != address(0) && to != address(0)){
            if(balanceOf(from, ids[0]) == 0){
              removeHolder(from, ids[0]);
            } else {
              reduceBalance(from, ids[0]);
            }
        } else if(to == address(0)){
           if(balanceOf(from, ids[0]) == 0){
              removeHolder(from, ids[0]);
            } else {
              reduceBalance(from, ids[0]);
            } 
        }
    }

    function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

    receive() external payable {}
}
