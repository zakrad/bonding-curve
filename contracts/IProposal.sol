// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProposal {
    function importFromMain(address _buyer) external payable returns(uint);
    function transferToMain(address _main) external;
}