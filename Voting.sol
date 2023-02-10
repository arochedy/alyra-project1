pragma solidity 0.8.14;

// Voici le déroulement de l'ensemble du processus de vote :

// L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum. => ok ?
// L'administrateur du vote commence la session d'enregistrement de la proposition. => ok 
// Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
// L'administrateur de vote met fin à la session d'enregistrement des propositions. ok 
// L'administrateur du vote commence la session de vote.
// Les électeurs inscrits votent pour leur proposition préférée.
// L'administrateur du vote met fin à la session de vote.
// L'administrateur du vote comptabilise les votes.
// Tout le monde peut vérifier les derniers détails de la proposition gagnante.


import "@openzeppelin/contracts/access/Ownable.sol";

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

contract Voting is Ownable{


    uint private winningProposalId ;
    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters ;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping(address => bool) private whitelistedAddresses;
    
    // mapping(address => uint) private userVotes;
    mapping (address => Voter) private userVotes;
    Proposal[] public proposals;

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

    function getCurrentStatus () public view returns (WorkflowStatus) {
        return currentStatus;
    }

    function whitelist (address _address) onlyOwner public 
    {
        //check s'il a pas déjà eté whitelisted 
        require(whitelistedAddresses[_address] == false, "Already registred");
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Not RegisteringVoters period");

        whitelistedAddresses[_address] = true;
        //create voter for msg.sender
        Voter memory currentVoter = Voter(true,false,0);
        userVotes[msg.sender] = currentVoter;
        emit VoterRegistered(_address);
    }

    function updateWorkflow() onlyOwner public 
    {
        require(currentStatus < WorkflowStatus.VotesTallied);
        WorkflowStatus oldStatus = currentStatus;
        WorkflowStatus nextStatus = WorkflowStatus(uint(oldStatus) +1);
        currentStatus = nextStatus;
        emit WorkflowStatusChange(oldStatus, nextStatus);
    }


    function addProposal(string calldata description) public returns (uint) {

        // Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.

        require(whitelistedAddresses[msg.sender] == true, "Your not allowed to addProposal");
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "biteNot ProposalsRegistrationStarted period");
        Proposal memory prop =  Proposal(description, 0);
        proposals.push(prop);
        
        emit ProposalRegistered(proposals.length-1);
        return proposals.length-1;

    }

    function vote(uint _proposalId) canVote public 
    {
        // Les électeurs inscrits votent pour leur proposition préférée.


        //check the _proposalId exists
        require(proposals.length > _proposalId, "This proposal does'nt exist");
        

        Voter memory vote =  Voter(true,true,_proposalId);
        userVotes[msg.sender] = vote;
        //TO FINISH ? update counters
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender,_proposalId);
    }


    function tailVotes () onlyOwner public {
        // L'administrateur du vote comptabilise les votes.
        require(currentStatus == WorkflowStatus.VotingSessionEnded, "It's not good time to do it");
        uint maxVote = 0;
        uint currentWinningProposalId = 0;

        for(uint i = 0; i< proposals.length; i++)
        {
            if(proposals[i].voteCount > maxVote)
            {
                currentWinningProposalId = i;
                maxVote = proposals[i].voteCount;
            }
        }

        winningProposalId = currentWinningProposalId;
        currentStatus = WorkflowStatus.VotesTallied;
    }
    function isWhitelisted(address _address) public view returns (bool)
    {
        return whitelistedAddresses[_address];
    }

    function getWinner() public view returns ( Proposal memory)
    {
        require(currentStatus == WorkflowStatus.VotesTallied, "Vote is not finished");
        //TO DO returns proposal ?
        return proposals[winningProposalId] ;
    }


    modifier canVote()
    {   
        require(isWhitelisted(msg.sender), "You're not authorized");
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "It's not the time to vote");
        require(userVotes[msg.sender].hasVoted == false, "You already voted");
        _;
    }




}