var Remittance = artifacts.require("./Remittance.sol");
var UsePasswords = artifacts.require("./UsePasswords.sol");

module.exports = function(deployer) {
  deployer.deploy(UsePasswords)
    .then(() => deployer.deploy(Remittance, UsePasswords.address));
};
