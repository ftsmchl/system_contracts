pragma solidity ^0.5.0;

contract ContractsRegistry {

	address[] public storageContracts;

	
	function registerStorageContract(address storagecontract) public {
		storageContracts.push(storagecontract);

	}	

	function deleteStorageContract(address storageContract) public returns (bool){
		uint selectedIndex;
		uint storageContractsLength = storageContracts.length;
		for (uint i = 0; i < storageContractsLength; i++) {
			if (storageContract == storageContracts[i]) {
				selectedIndex = i;
				break;
			}
		}
		delete storageContracts[selectedIndex];
		//Fixme : shift element for eliminating gaps after deletion;
		return true;
	}
}
