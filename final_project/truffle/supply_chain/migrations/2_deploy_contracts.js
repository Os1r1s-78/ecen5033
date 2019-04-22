const Supply = artifacts.require("SupplyChain");
const Inventory = artifacts.require("Inventory");
const ProductRegistry = artifacts.require("ProductRegistry");
const StructMapping = artifacts.require("StructMapping");
const StructAccess = artifacts.require("StructAccess");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Supply);
  deployer.deploy(Inventory);
  deployer.deploy(ProductRegistry);
  deployer.deploy(StructMapping);
  deployer.deploy(StructAccess);
  // Deploying inventory contract is temporary for direct testing
};
