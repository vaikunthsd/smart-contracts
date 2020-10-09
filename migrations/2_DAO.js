const Dao = artifacts.require("./dao.sol");
const Race = artifacts.require("./race.sol");
const Split = artifacts.require("./split.sol");
                                                                                 
module.exports = function(deployer) {                                           
  deployer.deploy(Dao);                                                  
  deployer.deploy(Race);                                                  
  deployer.deploy(Split);                                                  
};                                                                              
