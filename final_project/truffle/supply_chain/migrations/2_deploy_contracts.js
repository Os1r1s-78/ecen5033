const Supply = artifacts.require("SupplyChain");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Supply);
};
