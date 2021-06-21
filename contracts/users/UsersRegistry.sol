//pragma solidity >=0.4.21 <0.7.0;
pragma solidity ^0.5.0;

import "./User.sol";

contract UsersRegistry {

	mapping(address => string) public providerUrls;
	mapping(address => bool) public providerUrlsExist;
	string Greeting = "Geia sou magka paixtara";

	function getProviderUrl(address addr) public view returns (string memory) {
		return providerUrls[addr];
	}

	function getGreeting() public view returns (string memory) {
		return Greeting;
	}

	function createUser(string memory _name) public returns (address) {
		new User(
			_name
		//	address(this)
		);		
	}


	function setProviderUrl(string memory providerAddr) public {
		require(!providerUrlsExist[msg.sender], "provider URl exists");
		providerUrlsExist[msg.sender] = true;
		providerUrls[msg.sender] = providerAddr;
	}

}
