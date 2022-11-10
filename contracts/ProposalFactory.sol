/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Proposal.sol";

contract ProposalFactory is Ownable {    
    event ProposalCreated(address author);

    address private dacAdmin;
    address public main;
    address immutable proposalImplementation;
    address[] public proposals;

    

    constructor(address _dacAdmin, address _main) {
        dacAdmin = _dacAdmin;
        main = _main;
        proposalImplementation = address(new Proposal());
    }

    function createProposal() onlyOwner external returns(address){
        address clone = Clones.clone(proposalImplementation);
        Proposal(clone).initialize("https://paper-score-api/{id}", main, dacAdmin);
        proposals.push(clone);
        emit ProposalCreated(clone);
        return clone;
    }

    function getProposals() external view returns (address[] memory) {
        return proposals;
    }
}