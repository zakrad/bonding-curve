// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BondingCurve.sol";

contract ContinuousToken is BancorBondingCurve, Ownable, ERC20, ERC20Detailed {

    uint256 public scale = 10**18;
    uint256 public reserveBalance = 10*scale;
    uint32 public reserveRatio = 100000;

    event ContinuousMint(address indexed sender, uint256 indexed amount, uint256 deposit );
    event ContinuousBurn(address indexed sender, uint256 indexed amount, uint256 reimbursement);
    
    constructor(uint256 initialSupply) ERC20Detailed("Dac", "DAC", 18) public {
        _mint(msg.sender, initialSupply);
    }

    function mint() public payable {
        require(msg.value > 0, "Must send ether to buy tokens.");
        _continuousMint(msg.value);
    }

    function burn(uint256 _amount) public {
        uint256 returnAmount = _continuousBurn(_amount);
        msg.sender.transfer(returnAmount);
    }

    function calculateContinuousMintReturn(uint256 _amount)
        public view returns (uint256 mintAmount)
    {
        return calculatePurchaseReturn(totalSupply(), reserveBalance,reserveRatio, _amount);
    }

    function calculateContinuousBurnReturn(uint256 _amount)
        public view returns (uint256 burnAmount)
    {
        return calculateSaleReturn(totalSupply(), reserveBalance,reserveRatio, _amount);
    }

    function _continuousMint(uint256 _deposit)
        internal returns (uint256)
    {
        uint256 amount = calculateContinuousMintReturn(_deposit);
        _mint(msg.sender, amount);
        reserveBalance = reserveBalance + _deposit;
        emit ContinuousMint(msg.sender, amount, _deposit);
        return amount;
    }

    function _continuousBurn(uint256 _amount)
        internal returns (uint256)
    {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint256 reimburseAmount = calculateContinuousBurnReturn(_amount);
        reserveBalance = reserveBalance - reimburseAmount;
        _burn(msg.sender, _amount);
        emit ContinuousBurn(msg.sender, _amount, reimburseAmount);
        return reimburseAmount;
    }
}