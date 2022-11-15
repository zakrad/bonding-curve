// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProposal {
    function importFromMain(address _buyer, uint _id) external payable;
    function transferToMain(address _main, uint8[] memory sortedIds) external;
}