pragma solidity 0.8.17;

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

// import "@openzeppelin/contracts/access/Ownable.sol"; //for truffle test


import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

contract Voting is Ownable{

    uint private winningProposalId ;

    WorkflowStatus currentStatus = WorkflowStatus.RegisteringVoters ;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    mapping(address => bool) private voters; 
    
    mapping (address => Voter) private userVotes;
    Proposal[] private proposals; //can only view by voters

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

    //GETTERS 
    function getCurrentStatus() isVoter external view returns (WorkflowStatus) {
        return currentStatus;
    }

    function getProposal(uint256 _proposalId) external view isVoter returns (Proposal memory)
    {
        return proposals[_proposalId];
    }

    function getProposals() external view isVoter returns (Proposal[] memory)
    {
        return proposals;
    }

    function getVoterInfo(address _address) isVoter external view returns (Voter memory)
    {
        require(isWhitelisted(_address), "This address is not a voter");
        return userVotes[_address];
    }

    function getWinner() isVoter external view returns (Proposal memory)
    {
        require(currentStatus == WorkflowStatus.VotesTallied, "Vote is not finished");
        return proposals[winningProposalId] ;
    }

    function isWhitelisted(address _address) isVoter external view returns (bool)
    {
        return voters[_address];
    }

    //END GETTERS

    //ADMIN FUNCTIONS
    function whitelist(address _address) onlyOwner external 
    {
        //check s'il a pas déjà eté whitelisted 
        require(voters[_address] == false, "Already registred");
        require(currentStatus == WorkflowStatus.RegisteringVoters, "Not RegisteringVoters period");

        voters[_address] = true;
  
        Voter memory currentVoter = Voter(true,false,0);
        userVotes[msg.sender] = currentVoter;
        emit VoterRegistered(_address);
    }

    function updateWorkflow() onlyOwner external 
    {
        require(currentStatus < WorkflowStatus.VotesTallied);
        WorkflowStatus oldStatus = currentStatus;
        WorkflowStatus nextStatus = WorkflowStatus(uint(oldStatus) +1);
        currentStatus = nextStatus;
        emit WorkflowStatusChange(oldStatus, nextStatus);
    }

    function tailVotes () onlyOwner external {
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
    //END ADMIN FUNCTIONS

    //VOTER FUNCTIONS
    function addProposal(string calldata _description) isVoter external returns (uint) {

        // Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.

        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Not the time for add proposals");
        Proposal memory prop =  Proposal(_description, 0);
        proposals.push(prop);
        
        emit ProposalRegistered(proposals.length-1);
        return proposals.length-1;

    }

    function vote(uint _proposalId) canVote external 
    {
        // Les électeurs inscrits votent pour leur proposition préférée.

        require(proposals.length > _proposalId, "This proposal does'nt exist");

        Voter memory vote =  Voter(true,true,_proposalId);
        userVotes[msg.sender] = vote;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender,_proposalId);
    }


  

    
    //modifiers
    modifier canVote() 
    {   
        require(isWhitelisted(msg.sender), "You're not authorized");
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "It's not the time to vote");
        require(userVotes[msg.sender].hasVoted == false, "You already voted");
        _;
    }

    modifier isVoter()
    {   
        require(isWhitelisted(msg.sender), "You're not authorized");
        _;
    }

    //END MODIFIERS

    


}