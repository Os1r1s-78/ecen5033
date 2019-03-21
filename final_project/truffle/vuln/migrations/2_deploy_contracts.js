const Vuln = artifacts.require("Vuln");
//const Steal = artifacts.require("Steal");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Vuln);
  //deployer.deploy(Steal);
};
