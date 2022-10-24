// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BondingCurve.sol";

contract ContinuousToken is BancorBondingCurve, Ownable, ERC20 {

    uint256 public scale = 10**18;
    uint256 public reserveBalance = 10*scale;
    uint256 public reserveRatio;

    event ContinuousMint(address indexed _from, uint256 indexed, uint256 );
    event ContinuousBurn(address indexed _from, uint256 indexed, uint256 );
    
    constructor(
        uint256 _reserveRatio
    ) ERC20("Dac","DAC") {
        reserveRatio = _reserveRatio;
        _mint(msg.sender, 1*scale);
    }

    function mint() public payable {
        require(msg.value > 0, "Must send ether to buy tokens.");
        _continuousMint(msg.value);
    }

    function burn(uint256 _amount) public {
        uint256 returnAmount = _continuousBurn(_amount);
        payable(msg.sender).transfer(returnAmount);
    }

    function calculateContinuousMintReturn(uint256 _amount)
        public view returns (uint256 mintAmount)
    {
        return calculatePurchaseReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    function calculateContinuousBurnReturn(uint256 _amount)
        public view returns (uint256 burnAmount)
    {
        return calculateSaleReturn(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
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