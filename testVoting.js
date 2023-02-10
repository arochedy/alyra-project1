const VotingContract = artifacts.require("Voting");
const truffleAssert = require("truffle-assertions");

contract("VotingContract", (accounts) => {
  let [alice, bob, claire] = accounts;
  let contractInstance;
  beforeEach(async () => {
    contractInstance = await VotingContract.new();
  });
  it("whitelist alice", async () => {
    let result = await contractInstance.whitelist(alice);


    truffleAssert.eventEmitted(result, "VoterRegistered", (ev) => {
      return ev.voterAddress == alice;
    });

    await truffleAssert.reverts(
      contractInstance.addProposal("test proposal"),
      "Not ProposalsRegistrationStarted period"
    );

  });
  it("Basic worklow", async () => {

    await contractInstance.whitelist(bob);

    let result = await contractInstance.updateWorkflow();


    truffleAssert.eventEmitted(result, "WorkflowStatusChange", (ev) => {
      return ev.previousStatus == 0 && ev.newStatus == 1;
    });

    let test = await contractInstance.getCurrentStatus();

    let resultAddProposal = await contractInstance.addProposal("test", { from: bob });
    truffleAssert.eventEmitted(resultAddProposal, "ProposalRegistered", (ev) => {
      return ev.proposalId == 0;
    });

    let resultAddProposal2 = await contractInstance.addProposal("test 2", { from: bob });
    truffleAssert.eventEmitted(resultAddProposal2, "ProposalRegistered", (ev) => {
      return ev.proposalId == 1;
    });

    await contractInstance.updateWorkflow();

    await contractInstance.updateWorkflow();
    //on peut voter

    let resultVote = await contractInstance.vote(1, { from: bob });
    // console.log("resultVote", resultVote);
    truffleAssert.eventEmitted(resultVote, "Voted", (ev) => {
      return ev.voter == bob && ev.proposalId == 1;
    });


    await truffleAssert.reverts(
      contractInstance.vote(0, { from: bob }),
      "You already voted"
    );

    await contractInstance.updateWorkflow();
    //fin des votes

    await contractInstance.tailVotes();

    let winner = await contractInstance.getWinner();
    console.log(winner);
    assert.equal(winner.description, "test 2");
    assert.equal(winner.voteCount, 1);

    let results = await contractInstance.getProposals({from : bob});
    console.log(results);

  });

  it("test errors flow", async () => {

    await contractInstance.whitelist(bob);

    await truffleAssert.reverts(
      contractInstance.whitelist(bob),
      "Already registred"
    );


    await truffleAssert.reverts(
      contractInstance.whitelist(claire, { from: bob }),
      "Ownable: caller is not the owner"
    );

    await truffleAssert.reverts(
      contractInstance.vote(0, { from: bob }),
      "It's not the time to vote"
    );




    let result = await contractInstance.updateWorkflow();


    truffleAssert.eventEmitted(result, "WorkflowStatusChange", (ev) => {
      return ev.previousStatus == 0 && ev.newStatus == 1;
    });

    // let test = await contractInstance.getCurrentStatus();


    let resultAddProposal = await contractInstance.addProposal("test", { from: bob });
    truffleAssert.eventEmitted(resultAddProposal, "ProposalRegistered", (ev) => {
      return ev.proposalId == 0;
    });

    let resultAddProposal2 = await contractInstance.addProposal("test 2", { from: bob });
    truffleAssert.eventEmitted(resultAddProposal2, "ProposalRegistered", (ev) => {
      return ev.proposalId == 1;
    });

    await contractInstance.updateWorkflow();

    await contractInstance.updateWorkflow();
    //on peut voter


    await truffleAssert.reverts(
      contractInstance.vote(2, { from: bob }),
      "This proposal does'nt exist"
    );
    await truffleAssert.reverts(
      contractInstance.vote(0, { from: claire }),
      "You're not authorized"
    );

    let resultVote = await contractInstance.vote(1, { from: bob });
    // console.log("resultVote", resultVote);
    truffleAssert.eventEmitted(resultVote, "Voted", (ev) => {
      return ev.voter == bob && ev.proposalId == 1;
    });

    await truffleAssert.reverts(
      contractInstance.tailVotes({ from: bob }),
      "Ownable: caller is not the owner"
    );

    await truffleAssert.reverts(
      contractInstance.tailVotes(),
      "It's not good time to do it"
    );


    await truffleAssert.reverts(
      contractInstance.vote(0, { from: bob }),
      "You already voted"
    );

    await contractInstance.updateWorkflow();
    //fin des votes

    await contractInstance.tailVotes();

    let winner = await contractInstance.getWinner();
    assert.equal(winner.description, "test 2");
    assert.equal(winner.voteCount, 1);

  });


});
