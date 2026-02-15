// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.33;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus status = WorkflowStatus.RegisteringVoters;

    mapping(address => Voter) public whiteList;
    Proposal[] public proposals;
    uint private winningProposalId;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor() Ownable(msg.sender) {}

    function registerVoters(address _voter) external onlyOwner {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "Voters registration is not open yet"
        );
        require(_voter != address(0), "Voter address cannot be zero");
        require(whiteList[_voter].isRegistered == false, "Already registered");
        whiteList[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0
        });
        emit VoterRegistered(_voter);
    }

    function startProposalsRegistering() external onlyOwner {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "Registering voters is not finished"
        );
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, status);
    }

    function stopProposalsRegistration() external onlyOwner {
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Registering proposals havent started yet"
        );
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            status
        );
    }

    function startVotingSession() external onlyOwner {
        require(
            status == WorkflowStatus.ProposalsRegistrationEnded,
            "Registering proposals phase is not finished"
        );
        require(proposals.length >= 2, "not enough proposals");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            status
        );
    }

    function stopVotingSession() external onlyOwner {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, status);


    }

    function registerProposals(string calldata _proposal) external {
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not allowed yet"
        );
        require(whiteList[msg.sender].isRegistered, "You're not a voter");

        proposals.push(Proposal({description: _proposal, voteCount: 0}));
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint _proposalId) external {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        require(whiteList[msg.sender].isRegistered, "You're not a voter");
        require(
            whiteList[msg.sender].hasVoted == false,
            "You've already voted"
        );

        whiteList[msg.sender].votedProposalId = _proposalId;
        whiteList[msg.sender].hasVoted = true;
        proposals[_proposalId].voteCount += 1;

        if (
            proposals[_proposalId].voteCount >
            proposals[winningProposalId].voteCount
        ) {
            winningProposalId = _proposalId;
        }

        emit Voted(msg.sender, _proposalId);
    }

    function getWinner() external view returns (uint) {
        require(status == WorkflowStatus.VotesTallied, "Votes are not tallied");
        return winningProposalId;
    }
}
