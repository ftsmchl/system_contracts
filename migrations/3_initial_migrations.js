const UsersRegistry = artifacts.require("UsersRegistry");

module.exports = function (deployer) {
  deployer.deploy(UsersRegistry);
  console.log("egina deploy gamw th mana mou")
};
