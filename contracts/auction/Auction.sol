pragma solidity ^0.5.0;

import "./AuctionFactory.sol";
import "../AgoraContract.sol";
import "../storage/StorageAgreement.sol";

contract Auction {

	//to delete the auction after it is finalized.
	address private auctionFactory;
	//send the address to StorageAggreement.
	address private contractsRegistry;

	//owner of the auction
	address public owner;
	bytes32 public taskID;
	//when did the auction start in number of blocks.
	uint public startTime;
	uint public auctionDeadline;
	//duration of the Agora contract
	uint public duration;

	address public agoraContract;
	
	bool public canceled;
	bool public finalized;
	uint public lowestOffer;
	//the provider with the best offer until now
	address public winningBidder;
	mapping(address => uint256) public fundsByBidder;

	event NewOffer(bytes32 taskID,address bidder, uint lowestOffer);
	event AuctionCanceled(bytes32 taskID);
	event AuctionFinalized(bytes32 taskID, address agoraContract);


	constructor (
		address _owner,
		bytes32 _taskID,
		uint _initialOffer,
		uint _startTime,
		uint _duration,
		address _auctionFactory,
		address _contractsRegistry
	) public {
		require (
			_owner != address(0x0),
			"Must provide an auction owner"
		);

		auctionFactory = _auctionFactory;
		contractsRegistry = _contractsRegistry;
		//now is measured in seconds, deadline of an auction is 6 minutes
		//auctionDeadline = (now + 360) * 1000;
		auctionDeadline = (now + 60) * 1000;//auction Deadline lasts a minute
		owner = _owner;
		taskID = _taskID;
		lowestOffer = _initialOffer;
		startTime = _startTime;
		duration = _duration;	
	} 


	function cancelAuction() public
		onlyOwner
		onlyBeforeEnd
		onlyNotCanceled
		returns (bool success) 
	{
		canceled = true;
		emit AuctionCanceled(taskID);
		AuctionFactory aR = AuctionFactory(auctionFactory);
		aR.removeStorageAuction(address(this));
	
		return success;
	}	
	

	function placeOffer(uint newOffer) public 
		onlyAfterStart
		onlyBeforeEnd
		onlyNotCanceled
		onlyNotOwner
		onlyNotFinalized
		returns (bool success)
	{
		require(newOffer < lowestOffer, "A new offer should be better than the current best.");	
		fundsByBidder[msg.sender] = newOffer;
		lowestOffer = newOffer;
		winningBidder = msg.sender;

		emit NewOffer(taskID, msg.sender, lowestOffer);
		return true;
	}
	
	//must return the agoraContract's address
	function finalize() public 
		payable
		onlyOwner
		onlyAfterStart
		onlyNotCanceled
		returns(address)
	{
		require(
			winningBidder != address(0x00),
			"There must be a valid address to finalize the auction."
		);
		
		//collateral in gwei
		uint collateral = 1000;
		StorageAgreement ags = (new StorageAgreement).value(lowestOffer)
			(taskID,
			 address(uint160(owner)),
			 address(uint160(winningBidder)),
			 lowestOffer,
			 collateral,
			 duration,
			 contractsRegistry);	

		agoraContract = address(ags);	 
	
		finalized = true;
		emit AuctionFinalized(taskID, agoraContract);

		//delete auction from the registry of the auctionFactory
		AuctionFactory aR = AuctionFactory(auctionFactory);
		aR.removeStorageAuction(address(this));

		return agoraContract;		
	}

	modifier onlyOwner {
		require(
			msg.sender == owner,
			"This action must be performed by the auction owner."
		);
		_;
	}

	modifier onlyNotOwner {
		require(
			msg.sender != owner,
			"This action must not be performed by the auction owner."
		);
		_;
	}

	modifier onlyAfterStart {
		require(
			now * 1000 >= startTime,
			"This action must be performed after the auction startTime."
		);
		_;
	}

	modifier onlyBeforeEnd {
		require(
			now * 1000 <= auctionDeadline,
			"This action must be performed before the auctionDeadline."
		);
		_;
	}


	modifier onlyNotCanceled {
		require(
			!canceled,
			"This action cannot be performed on a canceled auction."
		);
		_;
	}

	modifier onlyNotFinalized {
		require(
			!finalized,
			"This action cannot be performed on a finalized auction."
		);
		_;
	}

	modifier onlyEndedOrCanceled {
		require(
			now * 1000 >= auctionDeadline || canceled,
			"This action cannot be performed on a finalized auction."
		);
		_;
	}



}
