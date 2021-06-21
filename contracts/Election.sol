//pragma solidity >=0.4.21 <0.7.0;
pragma solidity ^0.5.0;

contract Election {

	struct Candidate{
		uint id;
		string name;
		uint voteCount;
	}

	//Store Candidates
	//Fetch Candidates
	mapping(uint => Candidate) public candidates;

	//Boolean mapping
	mapping(address => bool) public Voters;

	//Store candidates count
	uint public candidatesCount;

	constructor() public {
		addCandidate("Candidate 1");
		addCandidate("Candidate 2");
	}

	//Private means that can only be called from within the contract
	//_name is because it is a local variable not a state variable
	function addCandidate(string memory _name) private {

		candidatesCount++;
		candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
	}


	function Vote(uint _id) public {
		require(!Voters[msg.sender], "This voter has already voted once");
		Voters[msg.sender] = true;
		candidates[_id].voteCount++;
	}
}
