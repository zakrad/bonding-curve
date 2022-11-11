/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Proposal.sol";
import "./Main.sol";

contract ProposalFactory is Ownable {    
    event ProposalCreated(address proposal);
    event MainCreated(address main);

    address private dacAdmin;
    address public main;
    address immutable proposalImplementation;
    address immutable mainImplementation;
    address[] public proposals;
    address[] public history;


    constructor(address _dacAdmin) {
        dacAdmin = _dacAdmin;
        main = address(0);
        proposalImplementation = payable(address(new Proposal()));
        mainImplementation = payable(address(new Main()));
    }

    function createMain() onlyOwner external returns(address){
        address payable clone = payable(Clones.clone(mainImplementation));
        Main(clone).initialize(dacAdmin);
        history.push(clone);
        main = clone;
        emit MainCreated(clone);
        return clone;
    }

    function createProposal() onlyOwner external returns(address){
        address payable clone = payable(Clones.clone(proposalImplementation));
        Proposal(clone).initialize(dacAdmin);
        proposals.push(clone);
        emit ProposalCreated(clone);
        return clone;
    }

    function getProposals() external view returns (address[] memory) {
        return proposals;
    }

    function getHistory() external view returns (address[] memory) {
        return history;
    }
}