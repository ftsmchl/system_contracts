pragma solidity ^0.5.0;

//import {ECDSA} from "../ECDSA.sol";
import "./Auction.sol";

contract AuctionFactory {

	address public contractsRegistry;
	address[] public storageAuctions;

	//event, so every provider can see that an auction is created
	event StorageAuctionCreated(address auctionContract, bytes32 taskID, address owner, uint initialBid, uint duration);

	//constructor must have the address of contracts registry to pass it to the auction.
	constructor (address _contractsRegistry) public {
		contractsRegistry = _contractsRegistry;
	}

	//creation of an auction is called by the renter.
	function createStorageAuction(bytes32 taskID,uint duration) public returns (address) {
		uint initialBid = 1000;
		Auction newAuction = new Auction (
			msg.sender,
			taskID,
			initialBid,
			now * 1000,
			duration,
			address(this),
			contractsRegistry
		);
	
		storageAuctions.push(address(newAuction));

		//emit event for the providers to start biding for the contract.
		emit StorageAuctionCreated(address(newAuction), taskID, msg.sender, initialBid, duration);

		return address(newAuction);
	}

	function getAllStorageAuctions() public view returns (address[] memory) {
		return storageAuctions;
	}
	
	function getStorageAuctionsSize() public view returns (uint) {
		return storageAuctions.length;
	}

	//This function maybe is internal no public
	function removeStorageAuction(address auction) public  returns (bool){
		uint selectedIndex;
		uint storageAuctionsLength = storageAuctions.length;

		for (uint i = 0; i < storageAuctionsLength; i++) {
			if (auction == storageAuctions[i]){
				selectedIndex = i;	
				break;
			}
		}

		delete storageAuctions[selectedIndex];
		return true;
	}


}






