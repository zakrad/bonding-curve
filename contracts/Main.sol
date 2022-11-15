// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IProposal.sol";


contract Main is Initializable, ERC20, Pausable, Ownable {

    address constant GAURD = address(1);
    IProposal public nextProposal;
    uint public holders; 

    mapping (address => address) _nextHolders;

    constructor() ERC20("DeCorp", "DAC") {
        _disableInitializers();
    }
    
    function initialize(address _admin) public initializer {
        _transferOwnership(_admin);
        _nextHolders[GAURD] = GAURD;
        _mint(_admin, 1);
    }

    function buyPrice(uint _dS) public view returns(uint) {
        // uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );
        uint dF = 1000 * (sqrt((totalSupply()+_dS)**2+10**6)-sqrt(totalSupply()**2+10**6));
        return dF;
    }

    function sellPrice(uint _dS) public view returns(uint) {
        // uint dF = (A*_dS) + (B/3)*( S**3 - (S - _dS)**3 );
        uint dF = 1000 * (sqrt(totalSupply()**2+10**6)-sqrt((totalSupply()-_dS)**2+10**6));
        return dF;
    }


    function Buy(uint _dS) whenNotPaused public payable returns(uint) {
        require(buyPrice(_dS) == msg.value, "Wrong value, Send the exact price");
        _mint(msg.sender, _dS);
        return(totalSupply());
    }

    function importFromProposal(address _buyer) external payable returns(uint) {
      // require(isProposal(msg.sender), "Only callable from another proposal");
        uint dS = (sqrt(((10**6)*(totalSupply()**2))+((msg.value)**2)+(2000*msg.value*sqrt(totalSupply()**2+10**6)))-(1000*totalSupply()))/1000;
        _mint(_buyer, dS);
        return(totalSupply());
    }

    function Sell(uint _dS) whenNotPaused public returns(uint) {
        require(balanceOf(msg.sender) > 0, "You don't have any token to sell.");
        require(_dS <= balanceOf(msg.sender), "You don't have this amount of token");
        _burn(msg.sender, _dS);
        payable(msg.sender).transfer(sellPrice(_dS));
        return(totalSupply());
    }

    function addHolder(address holder, uint amount) internal {
    require(_nextHolders[holder] == address(0));
    address index = _findIndex(amount);
    _nextHolders[holder] = _nextHolders[index];
    _nextHolders[index] = holder;
    holders++;
    }

    function removeHolder(address holder) internal {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    _nextHolders[prevHolder] = _nextHolders[holder];
    _nextHolders[holder] = address(0);
    holders--;
    }

  function increaseBalance(
    address holder, 
    uint amount
  ) internal {
    updateBalance(holder, balanceOf(holder) + amount);
  }

  function reduceBalance(
    address holder
  ) internal {
    updateBalance(holder, balanceOf(holder));
  }

  function updateBalance(
    address holder, 
    uint256 newBalance
  ) internal {
    require(_nextHolders[holder] != address(0));
    address prevHolder = _findPrevHolder(holder);
    address nextHolder = _nextHolders[holder];
    if(!_verifyIndex(prevHolder, newBalance, nextHolder)){
      removeHolder(holder);
      addHolder(holder, newBalance);
    }
  }

  function transferToProposals(address _proposal, uint8 numProps, uint _holders) external onlyOwner whenPaused {
    address currentAddress = _nextHolders[GAURD];
    nextProposal =  IProposal(_proposal);
    for(uint256 i = 0; i < _holders ; i++) {
      for(uint8 j = 0; j < numProps ; j++){
        nextProposal.importFromMain{gas: 1000000, value: (sellPrice(balanceOf(currentAddress))/numProps)-1000000}(currentAddress, j);
      }
      _burn(currentAddress, balanceOf(currentAddress));
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
    return (prevHolder == GAURD || balanceOf(prevHolder) >= newValue) && 
           (nextHolder == GAURD || newValue > balanceOf(nextHolder));
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

  function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
  {
        super._beforeTokenTransfer(from, to, amount);
        if(from != address(0) && to != address(0)){
          if(balanceOf(to) == 0){
                addHolder(to, amount);     
          } else {
                increaseBalance(to, amount);
          }
        } else if(from == address(0) && to != address(0)){
            if(balanceOf(to) == 0){
              addHolder(to, amount);
            } else {
              increaseBalance(to, amount);
            }
        }
  }

  function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
  {
        super._afterTokenTransfer(from, to, amount);
        if(from != address(0) && to != address(0)){
            if(balanceOf(from) == 0){
              removeHolder(from);
            } else {
              reduceBalance(from);
            }
        } else if(from != address(0) && to == address(0)){
           if(balanceOf(from) == 0){
              removeHolder(from);
            } else {
              reduceBalance(from);
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
