const RPS = artifacts.require("RPS");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(RPS);
};
