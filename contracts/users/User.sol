pragma solidity ^0.5.0;

import "./UsersRegistry.sol";



contract User {

event UserCreated(address myAddress);

string public name;
address private owner ;


constructor(string memory _name) public {
	name = _name;
	owner = msg.sender;
	emit UserCreated(address(this));
}


function callGreeting() public returns(string memory) {
	UsersRegistry uR = UsersRegistry(owner);	
	return uR.getGreeting();
}

}
