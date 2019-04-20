const Supply = artifacts.require("SupplyChain");
const Inventory = artifacts.require("Inventory");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Supply);
  deployer.deploy(Inventory);
  // Deploying inventory contract is temporary for direct testing
};
