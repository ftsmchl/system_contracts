pragma solidity ^0.5.0;

import {ECDSA} from "../ECDSA.sol";
import "../AgoraContract.sol";

contract StorageAgreement  is AgoraContract{
	
	//the merkleRoot of the sector roots 
	bytes32 storageRoot;

	//Events
	event StorageTaskCreated(bytes32 taskID, address storageContractAddress);
	event ContractActivated(address storageContractAddress);
	event ContractChallenged(address storageContractAddress, uint proofIndex, uint expDate);

	//mapping for checking a revision

	//mapping (uint => bool) public revision;
	uint latestRevisionChallenged;
	//proofIndex of the challenged
	uint proofIndex;


	constructor(
		bytes32 _taskID,
		address payable _client,
		address payable _provider,
		uint _payment,
		uint _guarantee,
		uint _duration,
		address _contractsRegistry	
	) AgoraContract(_taskID, _client, _provider, _payment, _guarantee, _duration, _contractsRegistry)
		public 
		payable
	{
		registry.registerStorageContract(address(this));
		emit StorageTaskCreated(taskID, address(this));
	
	}

	function computeMsgHash(bytes32 _merkleRoot, bytes memory _data, bytes32 _proofSet, uint _fileContractSize, uint _myRevision, uint _proofIndex, uint _numLeaves) public pure returns (bytes32 keccakHash){
		bytes32 hash = keccak256(abi.encodePacked(_merkleRoot, _data, _proofSet, _fileContractSize, _myRevision, _proofIndex, _numLeaves));
		keccakHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		return keccakHash;	
	}

	function bytesHash(bytes memory _msg) public pure returns (bytes32) {
		return keccak256(abi.encodePacked("0x00", _msg));
	}

	function nodeSum(bytes32 a, bytes32 b) public pure returns(bytes32 hash){
		hash = keccak256(abi.encodePacked("0x00", a, b));	
		return hash;
	}

	//activation is called from the provider
	//i need to fix it maybe to have an activation limit time.
	function activate() 
		public
		payable
		requiresProvider()
		requiresStatus(Status.Inactive)
	{
		require(
			msg.value == guarantee,
			"Guarantee is not equal to what has been agreed"	
		);	

		status = Status.Active;
		activateDate = block.timestamp * 1000;
		endDate = activateDate + duration;

		emit ContractActivated(address(this));	
	}


	// i need to make it payable so the client uploads also the challenge reward in case the provider succesfully uploads the proof
	function challengeProvider(
		bytes memory signatureClient, 
		bytes memory signatureProvider, 
		bytes32 _merkleRoot, 
		//uint _fileContractSize, 
		uint _revisionNumber,
		uint _numLeaves
	)
		public
		requiresClient()
		requiresStatus(Status.Active)
	{
		require(_revisionNumber >= latestRevisionChallenged, "Uploaded an old revision, be careful");
		require((block.timestamp * 1000 + challengeTime < endDate), "No time for the provider to give the next one proof");
		require(verifySignaturesChallenge(signatureClient, signatureProvider, _merkleRoot, _revisionNumber, _numLeaves), "Signatures are not valid!!!");	

		//save the revision number
		latestRevisionChallenged = _revisionNumber;

		proofIndex = (block.timestamp * 1000) % _numLeaves;

		challengeExpirationDate = (block.timestamp * 1000) + challengeTime;
		storageRoot = _merkleRoot;

		//The contract status will be changed to challenged
		status = Status.Challenged;

		//now the provider has a specific amount of time to upload the next challenge proof
		emit ContractChallenged(address(this), proofIndex, challengeExpirationDate);


	}

	//This function can be called by the client in case the provider sends an offchain wrong merkle proof.
	function challengeProviderAfterWrongProof(
		bytes memory signatureClient, 
		bytes memory signatureProvider, 
		bytes32 _merkleRoot, 
		bytes memory _data, 
		bytes32[] memory _proofSet, 
		uint _fileContractSize, 
		uint _revisionNumber,
		uint _proofIndex,
		uint _numLeaves
	)
		public
		requiresClient()
		requiresStatus(Status.Active)
	{
		require((block.timestamp * 1000 + challengeTime < endDate), "No time for the provider to give the next one proof");
		require(verifySignatures(signatureClient, signatureProvider, _merkleRoot, _data, _proofSet, _fileContractSize, _revisionNumber, _proofIndex, _numLeaves), "Signatures are not valid!!!");
		require(!verifyProof(_merkleRoot, _data, _proofSet, _proofIndex, _numLeaves), "The proof given is correct no need to challenge the provider!!");	
		
		if (proofsMissed < 2) {
			proofsMissed ++;
			//penalty is taken from the guarantee 
			guarantee = guarantee - penalty;	
			//here is gonna send the next proofIndex that the provider will have to prove .
			//uint proofIndex = (block.timestamp * 1000)% _numLeaves; 

			challengeExpirationDate = (block.timestamp * 1000) + challengeTime;

			storageRoot = _merkleRoot;	
			proofIndex = _proofIndex;
			
			//The contract status is set to challenged
			status = Status.Challenged;

			//so the provider now has a specific amount of time to upload the next challenge proof.
			emit ContractChallenged(address(this), proofIndex, challengeExpirationDate);
		} else {
			//invalidate the contract, provider loses all the guarantee and also does not get paid. 	
			emit TaskInvalidate(taskID);
		}
	
	}

	function asnwerChallenge(
		bytes memory signatureClient, 
		bytes memory signatureProvider,
		bytes32 _merkleRoot,
		bytes memory _data,
		bytes32[] memory _proofSet,
		uint _proofIndex,
		uint _numLeaves,
		uint _revisionNumber	
	) 
		public 
		requiresProvider()
		requiresStatus(Status.Challenged)	
	{
		
		require((_merkleRoot == storageRoot) && (_proofIndex == proofIndex), "merkleRoot or proofIndex  is not the same be careful!!!");	
		require(block.timestamp * 1000 < challengeExpirationDate, "Your time to answer the challenge has passed!!!"); 
		require(verifySignaturesChallenge(signatureClient, signatureProvider, _merkleRoot, _revisionNumber, _numLeaves), "Signatures are not valid!!!");	
	

		//Check if renter has tried to check an older revision
		if (_revisionNumber > latestRevisionChallenged) {
			//maybe a penalty for the renter and a reward for the provider
			status = Status.Active;	
		} else {	
			if (verifyProof(_merkleRoot, _data, _proofSet, _proofIndex, _numLeaves)) {
				status = Status.Active;	
			} else {
				//invalidate the contract as it is the second time that the provider fails to submit a correct proof 
				status = Status.Invalid;
				//call the invalidation function
				//return payment back to renter
				
				emit TaskInvalidate(taskID);
			}
		}	
	}



	function verifySignaturesChallenge(
		bytes memory signatureClient,
		bytes memory signatureProvider,
		bytes32 _merkleRoot,
		uint _revision,
		uint _numLeaves
	) public returns(bool)
	{
	//	require(!revision[_revision], "This revision has already been challenged");	

		bytes32 hash = keccak256(abi.encodePacked(_merkleRoot, _revision, _numLeaves));
		bytes32 keccakHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		
		address _client = ECDSA.recover(keccakHash, signatureClient);
		address _provider = ECDSA.recover(keccakHash, signatureProvider);

		if (_client == client && _provider == provider){
			return true;	
		} else {
			return false;	
		}


	}	


	function verifySignatures(
		bytes memory signatureClient, 
		bytes memory signatureProvider, 
		bytes32 _merkleRoot, 
		bytes memory _data, 
		bytes32[] memory _proofSet, 	
		uint _fileContractSize, 
		uint _revision,
		uint _proofIndex,
		uint _numLeaves
	)
		public returns(bool) 
	{
	//	require(!revision[_revision], "This revision has already been challenged");		
	//`	revision[_revision] = true;
		
		bytes32 proofSetHash = calculateArrayHash(_proofSet);
		bytes32 hash = computeMsgHash(_merkleRoot, _data, proofSetHash, _fileContractSize, _revision, _proofIndex, _numLeaves);
		address _client = ECDSA.recover(hash, signatureClient);
		address _provider = ECDSA.recover(hash, signatureProvider);

		if (_client == client && _provider == provider){
			return true;	
		} else {
			return false;	
		}
	}	

	function calculateArrayHash(bytes32[] memory _proofSet) public view returns(bytes32 hash){
		bytes memory data;
		for (uint i = 0; i < _proofSet.length; i++){
			data = abi.encodePacked(data, _proofSet[i]);	
		}		
		hash = keccak256(data);	
		return hash;
	}


	function verifyProof( bytes32 merkleRoot, bytes memory data, bytes32[] memory proofSet, uint prIndex, uint numLeaves) public view returns(bool){
		require(prIndex <= numLeaves, "proofIndex cannot be bigger than number of Leaves");
        	uint height = 0;
                require(proofSet.length > height, "careful proofSet is nil");
                bytes32 sum = bytesHash(data);
               	height = height + 1;
                uint stableEnd = proofIndex;
 
        	while(true) {
                	uint subTreeStartIndex = (prIndex / (1 << height)) * (1 << height);
                        uint subTreeEndIndex = subTreeStartIndex + (1 << (height)) - 1;
                        if (subTreeEndIndex >= numLeaves) {
                	        break;
                        }
                        stableEnd = subTreeEndIndex;
 
                        if (proofSet.length + 1<= height){
                        	return (false);
                        }
                        if ((prIndex - subTreeStartIndex) < (1 << (height - 1))){
                	        sum = nodeSum(sum, proofSet[height - 1]);
                       	} else {
                        	sum = nodeSum(proofSet[height - 1], sum);
                        }
                        height = height + 1;
      		}

		if (stableEnd != (numLeaves-1)) {
		if (proofSet.length + 1 <= height) {
	        	return (false);
		}
		sum = nodeSum(sum, proofSet[height - 1]);
	        height = height + 1;
				                        }
			         
		while(height < proofSet.length + 1){
			sum = nodeSum(proofSet[height - 1], sum);
			height = height + 1;
	        }
	
		if(sum == merkleRoot){
			return (true);
		}
		return (false);
	}


	function uploadDeposit() public payable {
		require((msg.value % uploadPrice) == 0, "money uploaded not a multiplier of uploadPrice");	
		uploadPayment += msg.value;
	}

	function downloadDeposit() public payable {
		require((msg.value % downloadPrice) == 0 , "money uploaded not a multiplier of downloadPrice");	
		downloadPayment += msg.value;
	}

	function challengeDeposit() public payable {
		require((msg.value % challengePrice == 0), "money uploaded not a multiplier of challengePrice");
		challengePayment += msg.value;	
	}

	function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
		return ECDSA.recover(hash, signature);	
	}

	//cancel can be called by the client at any point before provider activates the contract
	function cancel() 
		public 
		requiresClient
		requiresStatus(Status.Inactive)
	{
		super.cancel();
		registry.deleteStorageContract(address(this));	
	}

	function invalidate()
		public
		requiresProvider
		requiresStatus(Status.Challenged)
	{
		require(block.timestamp * 1000 > challengeExpirationDate, "Provider's proof window is not over yet");	
	}
	








}
