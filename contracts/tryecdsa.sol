pragma solidity ^0.5.0;

import {ECDSA} from "./ECDSA.sol";

contract tryecdsa{

	//uint length;

	function getResult() public pure returns(uint sum){
		uint a = 1;
		uint b = 2;
		sum = a + b;
		return sum;
	}


	function verify(bytes32 hash, bytes memory signature, string memory _msg) public view returns (bool verified) {
		require(hash == computeMsgHash(_msg), "The hash is not produced from this message !!!");
		address _sender = ECDSA.recover(hash, signature);
		if (_sender == msg.sender) {
			return true;
		} else {
			return false;
		}

	}


	function computeMsgHash(string memory my_msg) public pure returns (bytes32 keccakHash) {
		bytes memory msgBytes = bytes(my_msg);
		string memory length = uint2str(msgBytes.length);
		keccakHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", length, my_msg));
		//_length = my_msg.length;
		return keccakHash;
	}


	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
	        uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
	   	uint k = len - 1;
		while (_i != 0) {
		        bstr[k--] = byte(uint8(48 + _i % 10));
	 	       _i /= 10;
	        }
		return string(bstr);
	}







}
