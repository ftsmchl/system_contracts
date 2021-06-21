pragma solidity ^0.5.0;

import "./ContractsRegistry.sol";

//Functionality of a generic contract in Agora
contract AgoraContract {

	//Enum of the possible status values a contract can have
	enum Status {
		Inactive,
		Cancelled,
		Active,
		Complete,
		Invalid,
		Challenged
	}

	// Grace Period After End Date for the provider to complete the contract
	uint constant gracePeriod = 8640000;

	//variables for provider's challenge
	//period for the provider to submit a correct proof to the blockchain, after a challenge.
	uint constant challengeTime = 500000;
	uint internal challengeExpirationDate;

	//proofIndex of the current challenge
	uint internal proofIndex; 

	//unique identifier of the contract
	bytes32 internal taskID;

	//Address of the client
	address payable internal client;
	//Address of the service provider
	address payable internal provider;

	//Agreed payment for the task paid at the creation by the renter.
	uint internal payment;
	//Amount that the provider puts as a collateral
	uint internal guarantee;
	//Storage contract duration
	uint internal duration;
	//Contract activation date
	uint internal activateDate;
	//endDate is activateDate + duration??
	uint internal endDate;

	//variables for downloading finances	
	//amount renter deposits for downloading bandwidth chunks.
	uint internal downloadPayment;
	uint internal downloadPrice = 500;
	uint internal downloadMoneyEarned;

	//variable for uploading finances
	//amount renter deposits for uploading bandwidth.
	uint internal uploadPayment;
	//the upload price for uploading a piece of data 
	uint internal uploadPrice = 500;
	uint internal uploadMoneyEarned;

	//amount renter deposits for challenging provider.
	uint internal challengePayment;
	uint internal challengePrice;
	uint internal challengeMoneyEarned;

	//amount that gets out of guarantee as penalty for missing a proof
	uint internal penalty = 1000;

	//number of times a provider gets caught missing a proof, missing 2 proofs = disqualification.
	uint internal proofsMissed = 0;

	Status internal status;

	//Address of smart contract that stores all storage contracts.
	address public contractsRegistry;
	ContractsRegistry internal registry;

	//Events
	event TaskCompleted(bytes32 taskID);
	event TaskCanceled(bytes32 taskID);
	event TaskInvalidate(bytes32 taskID);
	//maybe an event TaskChallenged(bytes32 taskID);
	//event TaskChallenged(bytes32 taskID);

	//constructor of a general AgoraContract
	constructor(
		bytes32 _taskID,
		address payable _client,
		address payable _provider,
		//payment deposited from renter
		uint _payment,
		//collateral needed from the provider
		uint _guarantee,
		uint _duration,
		address _contractsRegistry
	)
		public
		payable
	{
		require(
			msg.value == _payment,
			"Transfered value is not equal to the one aggreed."
		);

		require(
			_guarantee >= _payment,
			"For security reasons, the guarantee should be greater than the agreed task price"
		);
	
		taskID = _taskID;
		
		client = _client;
		provider = _provider;
		payment = _payment;
		guarantee = _guarantee;
		duration = _duration;

		status = Status.Inactive;	
	
		contractsRegistry = _contractsRegistry;
		registry = ContractsRegistry(contractsRegistry);
	}



	//Client can cancel the contract if the contract has not been activated by the client
	function cancel() public
       		requiresClient
		requiresStatus(Status.Inactive)	
	{
		status = Status.Cancelled;
		//returns the payment back to the renter
		msg.sender.transfer(address(this).balance);	
	}


	//Invalidates the contract. This method can be called by the client if the provider
	//after the endDate + gracePeriod has failed to upload a Storage Proof.
	function invalidate() public 
		requiresClient()
		requiresStatus(Status.Active)
	{
		require(
			(block.timestamp * 1000 > endDate + gracePeriod),
			"The grace period has not passed since `endDate`."
		);
		status = Status.Invalid;

		emit TaskInvalidate(taskID);
	}


	//Getters

	function getTaskID() public view returns (bytes32){
		return taskID;
	}

	function getClientAddress() public view returns (address){
		return client;
}

	function getProviderAddress() public view returns (address){
		return provider;
	}

	function getPayment() public view returns (uint){
		return payment;
	}

	function getGuarantee() public view returns (uint) {
		return guarantee;
	}

	function getDuration() public view returns (uint) {
		return duration;
	}

	function getActivateDate() public view returns (uint) {
		return activateDate;
	}

	function getEndDate() public view returns (uint) {
		return endDate;
	}

	function getStatus() public view returns (int8) {
		if (status == Status.Inactive) {
			return 0;
		} else if (status == Status.Cancelled) {
			return 1;
		} else if (status == Status.Active) {
			return 2;
		} else if (status == Status.Complete) {
			return 3;
		} else if (status == Status.Invalid) {
			return 4;
		} else if (status == Status.Challenged) {
			return 5;
		} else {
			return -1;
		}
	}

	//Modifiers
	modifier requiresClient() {
		require(
			msg.sender == client,
			"Only Client can call this method."
		);
		_;
	}

	modifier requiresProvider() {
		require(
			msg.sender == provider,
			"Only provider can call this method."
		);
		_;
	}

	modifier requiresStatus(Status _status) {
		require(
			status == _status,
			"Invalid status."
		);
		_;
	}



}
