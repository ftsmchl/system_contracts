pragma solidity ^0.5.0;

import {ECDSA} from "./ECDSA.sol";

contract tryecdsa2{

	//uint length;
	mapping(uint => bool) public revision;

	uint moneyUpload;	

	address provider;
	address client;

	uint256 endingTime = now + 120;

	event contractChallenged();
	event pipes(bytes data);
	event dep(uint payment);
	event auction(bytes32 taskID, uint duration);
	event setAddress();
	event hashes(bytes32 proofSetHash, bytes32 msgHash, address client, address provider);
	event messageHash(bytes32 mesgHash);
	
	event test(uint indexed user, address indexed sender);

	function getResult(bytes memory _msg ) public pure returns(bytes32 hash){
		hash = keccak256(abi.encodePacked(_msg));
		hash = keccak256((abi.encodePacked("\x19Ethereum Signed Message:\n32",hash)));
		return hash;
	}


	function hasClosed() public view returns (bool) {
		return now > endingTime;
	} 


	//Test keyword now 
	function returnCurrentBlockNumber() public view returns(uint256 , uint256, uint256) {
		return (now, now *1000, 5);	
	}
	function printBytes(bytes32 _data) public pure returns(bytes32 ){
		return _data;	
	}

	function bytesHash(bytes memory _msg) public pure returns(bytes32){
		return keccak256(abi.encodePacked("0x00", _msg));
	}


	function msgHash(string memory _msg) public pure returns(bytes32 ){
		return keccak256(abi.encodePacked("0x00", _msg));	
	}

	function leafSum(bytes32 _msg) public pure returns(bytes32 hash){
		hash = keccak256(abi.encodePacked("0x00",_msg));
		return hash;
	}

	function dataSum(bytes32 _data) public pure returns(bytes32 hash){
		hash = keccak256(abi.encodePacked("0x00", _data));
		return hash;
			
	}

	function nodeSum(bytes32 a, bytes32 b) public pure returns(bytes32 hash){
		hash = keccak256(abi.encodePacked("0x01", a, b));
		return hash;	
	}

	function setAddresses(address _client, address _provider) public {
		provider = _provider;
		client = _client;		
		emit setAddress();
	}

	//fixed proofSet contains the actual proofSet except of actual data
	function verifyProof(/*bytes memory data,*/ bytes32 merkleRoot, bytes memory data, bytes32[] memory proofSet, uint proofIndex, uint numLeaves) public view returns (bool, bytes32, bytes32, string memory ){
		//require(merkleRoot != NULL, "cannot create a proof when merkleRoot is nil");
		require(proofIndex <= numLeaves, "proofIndex cannot be bigger than number of Leaves");
		uint height = 0;
		require(proofSet.length > height, "carefull proofSet is nil");
	//	height++; 	
	//	bytes32 sum = leafSum(proofSet[height]);
		bytes32 sum = bytesHash(data);	
		height = height + 1;
		uint stableEnd = proofIndex;

		while(true) {
			uint subTreeStartIndex = (proofIndex / (1 << height)) * (1 << height);	
			uint subTreeEndIndex = subTreeStartIndex + (1 << (height)) - 1;
			if (subTreeEndIndex >= numLeaves) {
				break;	
			}
			stableEnd = subTreeEndIndex;
			
			if (proofSet.length + 1<= height){
				return (false, sum, merkleRoot, "prwto if");	
			}
			if ((proofIndex - subTreeStartIndex) < (1 << (height - 1))){
				sum = nodeSum(sum, proofSet[height - 1]);	
			} else {
				sum = nodeSum(proofSet[height - 1], sum);	
			}
			height = height + 1;
			
		}

		if (stableEnd != (numLeaves-1)) {
			if (proofSet.length + 1 <= height) {
				return (false, sum, merkleRoot, "deutero if"); 
			}	
			sum = nodeSum(sum, proofSet[height - 1]);
			height = height + 1;
		}
	
		while(height < proofSet.length + 1){
			sum = nodeSum(proofSet[height - 1], sum);	
			height = height + 1;
		}
				
		if(sum == merkleRoot){
			return (true, sum, merkleRoot, "trito if");	
		}
		return (false, sum,  merkleRoot, "tetarto fd");
	}



	function calculateLeafIndex(string memory hashString) public view returns (uint256 , uint256){
		uint256 number = uint256(keccak256(abi.encodePacked(hashString)));
		return (number, number % 65536);	
	}

	function calculateArrayHash(bytes32[] memory proofSet) public view returns(bytes32 hash){
		bytes memory data;
		for (uint i = 0; i < proofSet.length; i++){
			data = abi.encodePacked(data, proofSet[i]); 
		}
		hash = keccak256(data);
		return hash;	
	}

	function gamwToSpitiMou(bytes memory data) public{
		emit pipes(data);	
	}





	function recover(bytes32 hash, bytes memory signature) internal pure returns(address){
	
		if(signature.length != 65){
			revert("ECDSA : Invalid signature length");	
		}	

		bytes32 r;
		bytes32 s;
		uint8 v;

		assembly{
			r := mload(add(signature, 0x20))	
			s := mload(add(signature, 0x40))
			v := byte(0, mload(add(signature, 0x60)))	
		}

		if (v != 27 && v != 28) {
			revert("ECDSA : invalid signature 'v' value");	
		}

		address signer = ecrecover(hash, v, r, s);
		require(signer != address(0), "ECDSA : invalid signature");

		return signer;
	}


	function testEvent(uint user) public {
		emit test(user, msg.sender);	
	}

	function deposit() public payable {
		if (msg.value == 1000){
			moneyUpload = msg.value;
			emit dep(msg.value);			
		}else{
		}
	}

	function money() public view returns(uint){
		return moneyUpload;	
	}

	function VrfSgn(bytes memory signatureClient, bytes memory signatureProvider, bytes memory data) public {
		bytes32 msgHash = getResult(data);
		address _client = ECDSA.recover(msgHash, signatureClient);
		address _provider = ECDSA.recover(msgHash, signatureProvider);
		if(_client == client && _provider == provider){
			emit contractChallenged();	
		} else {}
			
	}

	function verifySignatures(
		bytes memory signatureClient, 
		bytes memory signatureProvider, 
		bytes32 _merkleRoot, 
		bytes memory _data, 
		bytes32[] memory _proofSet, 
		uint _fileContractSize, 
		uint _revision) 
		public  /*returns (bool ) */{
		
		require(!revision[_revision], "This revision has already been challenged");
		revision[_revision] = true;

		bytes32 proofSetHash = calculateArrayHash(_proofSet);
		bytes32 hash = computeMsgHash(_merkleRoot, _data, proofSetHash, _fileContractSize, _revision); 
		address _client = ECDSA.recover(hash, signatureClient);
		address _provider = ECDSA.recover(hash, signatureProvider);

		emit hashes(proofSetHash, hash, _client, _provider);

		if (_client == client  && _provider == provider) {
			emit contractChallenged();
			//return true;
		} else {
		//	return false;
		}

	}


	function computeMsgHash(bytes32 merkleRoot, bytes memory data, bytes32 proofSet, uint fileContractSize, uint my_revision) public  returns (bytes32 keccakHash) {
		bytes32 hash = keccak256(abi.encodePacked(merkleRoot, data, proofSet, fileContractSize, my_revision));
		emit messageHash(hash);
		keccakHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		//_length = my_msg.length;
		return keccakHash;
	}


}
