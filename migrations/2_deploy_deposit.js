const Deposit = artifacts.require("Deposit");

module.exports = function(deployer){
    deployer.deploy(Deposit);
}