// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProposal {
    function importToNext(address _buyer) external payable returns(uint);
    function transferToNext(address _nextProposal) external;
}