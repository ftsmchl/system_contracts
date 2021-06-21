pragma solidity ^0.5.0;

library  ECDSA {

	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
		if (signature.length != 65) {
			revert("ECDSA : Invalid signature length");
		}

		bytes32 r;
		bytes32 s; 
		uint8 v;

		assembly {
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

}
