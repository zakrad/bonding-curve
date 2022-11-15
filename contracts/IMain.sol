// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMain {
    function importFromProposal(address _buyer) external payable returns(uint);
    function transferToProposals(address _proposal, uint8 numProps, uint _holders) external;
}