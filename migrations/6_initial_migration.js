const Tryecdsa= artifacts.require("tryecdsa");

module.exports = function (deployer) {
  deployer.deploy(Tryecdsa);
};
