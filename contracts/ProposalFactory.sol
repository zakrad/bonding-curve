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

    // enum State
    // {
    // MAIN,     //0
    // OPEN,     //1
    // PROPOSAL  //2
    // }

    // State public period;

    // modifier isMain() {
    //   require(period == State.MAIN, "This function only allowed in Main state.");
    //   _;
    // }

    // modifier isOpen() {
    //   require(period == State.OPEN, "This function only allowed in Open state.");
    //   _;
    // }

    // modifier isProposal() {
    //   require(period == State.PROPOSAL, "This function only allowed in Proposal state.");
    //   _;
    // }

    constructor(address _dacAdmin) {
        dacAdmin = _dacAdmin;
        main = address(0);
        proposalImplementation = payable(address(new Proposal()));
        mainImplementation = payable(address(new Main()));
    }

    function createMain() onlyOwner external returns(address){
        address payable clone = payable(Clones.clone(mainImplementation));
        Main(clone).initialize("https://paper-score-api/main-nft", main, dacAdmin);
        history.push(clone);
        main = clone;
        emit MainCreated(clone);
        return clone;
    }

    function createProposal() onlyOwner external returns(address){
        address payable clone = payable(Clones.clone(proposalImplementation));
        Proposal(clone).initialize("https://paper-score-api/proposal-nft", main, dacAdmin);
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