// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { verify, deployContract, deployUUPS, deployGameExt } from "../utils/deployment";
const { upgrades } = require("hardhat");
const hre = require("hardhat");
const chain = hre.hardhatArguments.network;
const ZERO_ADDR = '0x0000000000000000000000000000000000000000';

//Track Addresses (Fill in present addresses to prevent new deplopyment)
import contractAddrs from "./_contractAddr";
const contractAddr = contractAddrs[chain];
import publicAddrs from "./_publicAddrs";
const publicAddr = publicAddrs[chain];
let deployed: any = [];

async function main() {

  //Validate Foundation
  if(!publicAddr.openRepo || !publicAddr.ruleRepo) throw "Must First Deploy Foundation Contracts on Chain:'"+chain+"'";

  console.log("Running on Chain: ", chain);

  let hubContract;

  //--- Game Implementation
  if(!contractAddr.game) {
    //Deploy Game
    // let contract = await ethers.getContractFactory("GameUpgradable").then(res => res.deploy());
    let contract = await deployContract("GameUpgradable", []);
    await contract.deployed();
    
    //Set Address
    contractAddr.game = contract.address;
    //Log
    console.log("Deployed Game Contract to " + contractAddr.game);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.game);
    //Verify on Etherscan
    await verify(contract.address, []);
    // deployed.push({address:contract.address, params:[]}); //TODO: Verification at the end?
  }

  //--- Claim Implementation
  if(!contractAddr.claim) {
    //Deploy Claim
    let contract = await deployContract("ClaimUpgradable", []);
    await contract.deployed();
        
    //Set Address
    contractAddr.claim = contract.address;
    //Log
    console.log("Deployed Claim Contract to " + contractAddr.claim);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.claim);
    //Verify on Etherscan
    await verify(contract.address, []);
    
  }

  //--- Task Implementation
  if(!contractAddr.task) {
    //Deploy Task
    let contract = await deployContract("TaskUpgradable", []);
    await contract.deployed();
    
    //Set Address
    contractAddr.task = contract.address;
    //Log
    console.log("Deployed Task Contract to " + contractAddr.task);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.task);
    //Verify on Etherscan
    await verify(contract.address, []);
  }

  //--- TEST: Upgradable Hub
  if(!contractAddr.hub) {
    const params = [
      publicAddr.openRepo,
      contractAddr.game,
      contractAddr.claim,
      contractAddr.task,
    ];
    //Deploy Hub Upgradable (UUPS)    
    hubContract = await deployUUPS("HubUpgradable", params);
    await hubContract.deployed();

    //Deploy All Game Extensions & Set to Hub
    deployGameExt(hubContract);

    //Set RuleRepo to Hub
    hubContract.assocSet("RULE_REPO", publicAddr.ruleRepo);

    //Set Address
    contractAddr.hub = hubContract.address;
    // console.log("HubUpgradable deployed to:", hubContract.address);    

    //Log
    console.log("Deployed Hub Upgradable Contract to " + contractAddr.hub+ " game: "+contractAddr.game+ " Claim: "+ contractAddr.claim);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.hub);

    /* Fails
    try{
      //Verify on Etherscan
      await verify(hubContract.address, params);
    }catch(error){console.error("[CAUGHT] Contract Verification Error", error);}
    */
  }

  //--- Soul Upgradable
  if(!contractAddr.avatar) {
    //Deploy Soul Upgradable
    const proxyAvatar = await deployUUPS("SoulUpgradable", [contractAddr.hub]);
    await proxyAvatar.deployed();

    contractAddr.avatar = proxyAvatar.address;
    //Log
    console.log("Deployed Avatar Proxy Contract to " + contractAddr.avatar);
    // console.log("Run: npx hardhat verify --network "+chain+" "+contractAddr.avatar);

    /* Fails on Solidity Version (0.8.2) (Proxy)
    try{
      //Verify on Etherscan
      await verify(proxyAvatar.address, [contractAddr.hub]);
    }catch(error){console.error("[CAUGHT] Verification Error", error);}
    */
  }

  //--- Action Repo
  if(!contractAddr.history) {
    //Action Repository (History)
    const proxyActionRepo = await deployUUPS("ActionRepoTrackerUp", [contractAddr.hub]);
    await proxyActionRepo.deployed();
    //Set Address
    contractAddr.history = proxyActionRepo.address;
    //Log
    console.log("Deployed History Contract to " + contractAddr.history);

    /* Fails on Solidity Version (0.8.2) (Proxy)
    //Verify on Etherscan
    await verify(proxyActionRepo.address, [contractAddr.hub]);
    */
  }

  //Hub Associations & Validation
  if(!hubContract && contractAddr.hub) hubContract = await ethers.getContractFactory("HubUpgradable").then(res => res.attach(contractAddr.hub));
  if(hubContract){
    console.log("Validate Hub ", hubContract.address);
    let assoc: any = {};
    assoc.sbt = await hubContract.assocGet("SBT");
    assoc.history = await hubContract.assocGet("history");
    // console.log("Hub: ", hubContract.address, " Assoc:", assoc, contractAddr);
    if(assoc.sbt == ZERO_ADDR){
      await hubContract.assocSet("SBT", contractAddr.avatar);
      console.log("Updated SBT to: ", contractAddr.avatar);
    }
    if(assoc.history == ZERO_ADDR){
      await hubContract.assocSet("history", contractAddr.history);
      console.log("Updated History to: ", contractAddr.history);
    }
    // else console.log("Not the same", contractAddr.history, ZERO_ADDR, (assoc.history == ZERO_ADDR));
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
