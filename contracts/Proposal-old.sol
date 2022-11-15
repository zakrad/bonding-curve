// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import "./IMain.sol";


// contract Proposal is Initializable, ERC1155, Pausable, Ownable {

//     address constant GAURD = address(1);
//     uint public S;
//     uint public holders; 
//     uint public A;
//     uint public B;
//     IMain public nextMain;


//     mapping (address => uint) public balances;
//     mapping (address => address) _nextHolders;


//     constructor() ERC1155("") {
//         _disableInitializers();
//     }
    
//     function initialize(address _admin) public initializer {
//         _transferOwnership(_admin);
//         _nextHolders[GAURD] = GAURD;
//         A=25;
//         B=3;
//     }

//     modifier onlyCaller(address _sender, uint _supplyId) {
//       require(uint(keccak256(abi.encodePacked(_sender))) == _supplyId, "Your id does not match");
//       _;
//     }

//     function buyPrice(uint _dS) public view returns(uint) {
//         // uint dF = (A*_dS) + (B/3) * ( (S + _dS)**3 - S**3 );
//         uint dF = 1000 * (sqrt((S+_dS)**2+10**6)-sqrt(S**2+10**6));
//         return dF;
//     }

//     function sellPrice(uint _dS) public view returns(uint) {
//         // uint dF = (A*_dS) + (B/3)*( S**3 - (S - _dS)**3 );
//         uint dF = 1000 * (sqrt(S**2+10**6)-sqrt((S-_dS)**2+10**6));
//         return dF;
//     }


//     function Buy(uint _dS) whenNotPaused public payable returns(uint) {
//         require(buyPrice(_dS) == msg.value, "Wrong value, Send the exact price");

//         uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 

//         if(balanceOf(msg.sender,supplyId) == 0){
//         addHolder(msg.sender, _dS);
//         } else {
//         increaseBalance(msg.sender, _dS);
//         }
//         mint(msg.sender, supplyId, _dS, "");

//         S += _dS;
//         return(S);
//     }

//     function importFromMain(address _buyer) external payable returns(uint) {
//       // require(isProposal(msg.sender), "Only callable from another proposal");
//         uint supplyId = uint(keccak256(abi.encodePacked(_buyer))); 
//         uint dS = (sqrt(((10**6)*(S**2))+((msg.value)**2)+(2000*msg.value*sqrt(S**2+10**6)))-(1000*S))/1000;
//         if(balanceOf(_buyer,supplyId) == 0){
//         addHolder(_buyer, dS);
//         } else {
//         increaseBalance(_buyer, dS);
//         }
//         mint(_buyer, supplyId, dS, "");
//         S += dS;
//         return(S);
//     }

//     function Sell(uint _dS) whenNotPaused public returns(uint) {
//         require(balanceOf(msg.sender,uint(keccak256(abi.encodePacked(msg.sender)))) > 0, "You don't have any token to sell.");
//         require(_dS <= balanceOf(msg.sender,uint(keccak256(abi.encodePacked(msg.sender)))), "You don't have this amount of token");

//         uint supplyId = uint(keccak256(abi.encodePacked(msg.sender))); 

//         if(_dS == balanceOf(msg.sender,supplyId)){
//         removeHolder(msg.sender);
//         } else {
//         reduceBalance(msg.sender, _dS);
//         }
//         _burn(msg.sender, supplyId, _dS);
//         payable(msg.sender).transfer(sellPrice(_dS));      
//         S -= _dS;
//         return(S);
//     }

//     function addHolder(address holder, uint256 balance) internal {
//     require(_nextHolders[holder] == address(0));
//     address index = _findIndex(balance);
//     balances[holder] = balance;
//     _nextHolders[holder] = _nextHolders[index];
//     _nextHolders[index] = holder;
//     holders++;
//     }

//     function removeHolder(address holder) internal {
//     require(_nextHolders[holder] != address(0));
//     address prevHolder = _findPrevHolder(holder);
//     _nextHolders[prevHolder] = _nextHolders[holder];
//     _nextHolders[holder] = address(0);
//     balances[holder] = 0;
//     holders--;
//     }

//     function increaseBalance(
//     address holder, 
//     uint256 balance
//   ) internal {
//     updateBalance(holder, balances[holder] + balance);
//   }

//   function reduceBalance(
//     address holder, 
//     uint256 balance
//   ) internal {
//     updateBalance(holder, balances[holder] - balance);
//   }

//   function updateBalance(
//     address holder, 
//     uint256 newBalance
//   ) internal {
//     require(_nextHolders[holder] != address(0));
//     address prevHolder = _findPrevHolder(holder);
//     address nextHolder = _nextHolders[holder];
//     if(_verifyIndex(prevHolder, newBalance, nextHolder)){
//       balances[holder] = newBalance;
//     } else {
//       removeHolder(holder);
//       addHolder(holder, newBalance);
//     }
//     }

//     function transferToMain(address _main) external onlyOwner whenPaused returns(address){
//     nextMain =  IMain(_main);
//     address currentAddress = _nextHolders[GAURD];
//     for(uint256 i = 0; i < holders; i++) {
//       uint currentId = uint(keccak256(abi.encodePacked(currentAddress)));
//       uint balanceOfCurrent = balanceOf(currentAddress, currentId);
//       nextMain.importFromProposal{gas: 1000000, value: sellPrice(balanceOfCurrent)-1000000}(currentAddress);
//       _burn(currentAddress, currentId, balanceOfCurrent);  
//       S -= balanceOfCurrent;
//       currentAddress = _nextHolders[currentAddress];
//     }
//     return currentAddress;
//     }

//    function getArray() public view returns(address[] memory) {
//     address[] memory holderList = new address[](holders);
//     address currentAddress = _nextHolders[GAURD];
//     for(uint256 i = 0; i < holders; i++) {
//       holderList[i] = currentAddress;
//       currentAddress = _nextHolders[currentAddress];
//     }
//     return holderList;
//     }

//     function _findIndex(uint256 newValue) internal view returns(address) {
//     address candidateAddress = GAURD;
//     while(true) {
//       if(_verifyIndex(candidateAddress, newValue, _nextHolders[candidateAddress]))
//         return candidateAddress;
//       candidateAddress = _nextHolders[candidateAddress];
//     }
//     return address(0);
//   }


//     function _verifyIndex(address prevHolder, uint256 newValue, address nextHolder)
//     internal
//     view
//     returns(bool) {
//     return (prevHolder == GAURD || balances[prevHolder] >= newValue) && 
//            (nextHolder == GAURD || newValue > balances[nextHolder]);
//     }
    
//     function _isPrevHolder(address holder, address prevHolder) internal view returns(bool) {
//     return _nextHolders[prevHolder] == holder;
//     }

//     function _findPrevHolder(address holder) internal view returns(address) {
//     address currentAddress = GAURD;
//     while(_nextHolders[currentAddress] != GAURD) {
//       if(_isPrevHolder(holder, currentAddress))
//         return currentAddress;
//       currentAddress = _nextHolders[currentAddress];
//     }
//     return address(0);
//   }

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     function mint(address account, uint256 id, uint256 amount, bytes memory data)
//         internal
//         onlyCaller(account, id)
//     {
//         _mint(account, id, amount, data);
//     }

//     function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
//         public
//         onlyOwner
//     {
//         _mintBatch(to, ids, amounts, data);
//     }

//     function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
//         internal
//         override(ERC1155)
//     {
//         super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
//     }

//     function sqrt(uint y) internal pure returns (uint z) {
//     if (y > 3) {
//         z = y;
//         uint x = y / 2 + 1;
//         while (x < z) {
//             z = x;
//             x = (y / x + x) / 2;
//         }
//     } else if (y != 0) {
//         z = 1;
//     }
// }

//     receive() external payable {}
// }
