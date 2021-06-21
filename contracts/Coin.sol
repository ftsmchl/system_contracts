//pragma solidity >0.5.15 <0.8.0;
pragma solidity ^0.5.0;

contract Coin {
	address public minter;
	mapping (address => uint) public balances;

	event Sent(address from, address to, uint amount);

	constructor() public{
		minter = msg.sender;
	}

	function mint(address receiver, uint amount) public {
		require(msg.sender == minter);
		require(amount < 1e60);
		balances[receiver] += amount;
	}

	function send(address receiver , uint amount) public {
		require(balances[msg.sender] >= amount, "Insufficient balance.");
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Sent(msg.sender, receiver, amount);
	}

} 
