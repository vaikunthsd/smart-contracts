pragma solidity ^0.5.0;

contract DAO {
  struct Proposal {
    uint id;
    string description;
    uint voteYes;
    uint voteNo;
    uint initialTotalBalance;
    bool _sealed; //sealed is a reserved keyword
  }
  enum Vote {
    UNDEFINED,
    YES,
    NO
  }
  address public creator;
  address public curator;
  uint public valuation = 1;
  uint public totalBalance;
  bool public unsealedProposal; //true if there is an unsealed proposal (i.e a vote is ongoing)
  uint nextProposalId = 1; //1 and not 0 so that we can check that a proposal exist with `proposals[proposalId].id != 0`
  mapping(address => uint) public balances; //token balances.
  mapping(uint => Proposal) public proposals; //collection of proposals index by the their ids
  mapping(address => mapping(uint => Vote)) public votes; //represents user votes, per proposal. nested uint is proposalId
  address[] public investors; //to be able to reset balances mapping

  constructor() public {
    creator = msg.sender;
    curator = msg.sender;
  }

  function delegateCurator(address newCurator) 
    external 
    isCurator()
    noUnsealedProposal() {
    curator = newCurator; 
  }
  
  function createProposal(string calldata description) 
    external 
    isCurator()
    noUnsealedProposal() {
    proposals[nextProposalId] = Proposal(
      nextProposalId, 
      description, 
      0,
      0,
      totalBalance,
      false
    );
    unsealedProposal = true;
    nextProposalId++;
  }

  function deposit() external payable {
    balances[msg.sender] += msg.value;
    totalBalance += msg.value;
    investors.push(msg.sender); //certain addresses will be added several times if several deposit, but this array is only used to reset balances, so thats ok

    //vote for current proposal IF its unsealed AND sender has already voted
    Vote myVote = votes[msg.sender][nextProposalId - 1];
    if(unsealedProposal == true && myVote != Vote.UNDEFINED) {
      _vote(nextProposalId - 1, myVote, msg.value);
    }
  }

  function withdraw(uint amount) external {
    require(balances[msg.sender] >= amount);
    require(totalBalance >= amount);
    //If a proposal in unsealed (i.e we are voting) and the sender has voted, all his/her tokens are frozen, cant withdraw
    if(unsealedProposal) {
      require(votes[msg.sender][nextProposalId - 1] == Vote.UNDEFINED);
    }
    balances[msg.sender] -= amount;
    totalBalance -= amount;
    msg.sender.transfer(amount * valuation);
  }

  function vote(uint proposalId, Vote myVote) external {
    require(proposals[proposalId].id != 0); //make sure proposal exist
    require(proposals[proposalId]._sealed == false);
    require(myVote != Vote.UNDEFINED);
    require(votes[msg.sender][proposalId] == Vote.UNDEFINED); //if vote is UNDEFINED means user never voted before
    _vote(proposalId, myVote, balances[msg.sender]);
  }

  function _vote(uint proposalId, Vote myVote, uint amount) internal {
    Proposal storage proposal = proposals[proposalId];
    if(myVote == Vote.YES) {
      proposal.voteYes += amount;
    } else {
      proposal.voteNo += amount;
    }
    votes[msg.sender][proposalId] = myVote;
    if(2 * proposal.voteNo > proposal.initialTotalBalance) {
      proposal._sealed = true;
      unsealedProposal = false;
      return;
    }
    if(2 * proposal.voteYes > proposal.initialTotalBalance) {
      proposal._sealed = true;
      unsealedProposal = false;
      valuation = valuation * _random(11);
      if(valuation == 0) {
        totalBalance = 0;
        for(uint i = 0; i < investors.length; i++) {
          delete balances[investors[i]];
        }
      }
    }
  }

  function _random(uint modulo) view internal returns(uint) {
    return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % modulo;
  }

  function getBalance(address _of) view external returns(uint) {
    return balances[_of]; //of is a reserved keyword
  }

  modifier isCurator() {
    require(msg.sender == curator);
    _;
  }

  modifier noUnsealedProposal() {
    require(unsealedProposal == false);
    _;
  }
}
