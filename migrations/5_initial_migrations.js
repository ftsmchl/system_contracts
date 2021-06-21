const ContractsRegistry = artifacts.require("ContractsRegistry");
const AuctionFactory = artifacts.require("AuctionFactory");

module.exports = function (deployer) {
  deployer.deploy(ContractsRegistry).then(function() {
	 return deployer.deploy(AuctionFactory, ContractsRegistry.address);
  });
};
