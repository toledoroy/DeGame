// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { deployContract, deployUUPS } from "../utils/deployment";
const { upgrades } = require("hardhat");
const hre = require("hardhat");
const chain = hre.hardhatArguments.network;

//Track Addresses (Fill in present addresses to prevent new deplopyment)
import contractAddrs from "./_contractAddr";
const contractAddr = contractAddrs[chain];
import publicAddrs from "./_publicAddrs";
const publicAddr = publicAddrs[chain];

async function main() {

  //Validate Foundation
  if(!publicAddr.openRepo || publicAddr.ruleRepo) throw "Must First Deploy Foundation Contracts on Chain:'"+chain+"'";

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
  }

  //--- Claim Implementation
  if(!contractAddr.claim) {
    //Deploy Claim
    // let contract = await ethers.getContractFactory("ClaimUpgradable").then(res => res.deploy());
    let contract = await deployContract("ClaimUpgradable", []);
    await contract.deployed();
    //Set Address
    contractAddr.claim = contract.address;
    //Log
    console.log("Deployed Claim Contract to " + contractAddr.claim);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.claim);
  }

  //--- TEST: Upgradable Hub
  if(!contractAddr.hub) {
    //Deploy Hub Upgradable (UUPS)    
    hubContract = await deployUUPS("HubUpgradable",
      [
        publicAddr.openRepo,
        contractAddr.game,
        contractAddr.claim,
      ]);

    await hubContract.deployed();

    //Set RuleRepo to Hub
    hubContract.assocSet("RULE_REPO", publicAddr.ruleRepo.address);

    //Set Address
    contractAddr.hub = hubContract.address;

    console.log("HubUpgradable deployed to:", hubContract.address);

    try{
      //Set as Avatars
      if(!!contractAddr.avatar) await hubContract.assocSet("SBT", contractAddr.avatar);
      //Set as History
      if(!!contractAddr.history) await hubContract.assocSet("history", contractAddr.history);
    }
    catch(error) {
      console.error("Failed to Set Contracts to Hub", error);
    }

    //Log
    console.log("Deployed Hub Upgradable Contract to " + contractAddr.hub+ " game: "+contractAddr.game+ " Claim: "+ contractAddr.claim);
    console.log("Run: npx hardhat verify --network "+chain+" " + contractAddr.hub+" "+publicAddr.openRepo+" "+contractAddr.game+ " "+contractAddr.claim);
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
    if(!!hubContract) {  //If Deployed Together
      try{
        //Set to HUB
        await hubContract.assocSet("SBT", contractAddr.avatar);
        //Log
        console.log("Registered Avatar Contract to Hub");
      }
      catch(error) {
        console.error("Failed to Set Avatar Contract to Hub", error);
      }
    }
  }

  //--- Action Repo
  if(!contractAddr.history) {
    //Action Repository (History)
    const proxyActionRepo = await deployUUPS("ActionRepoTrackerUp", [contractAddr.hub]);
    await proxyActionRepo.deployed();
    
    console.log("Deployed History Contract", proxyActionRepo.address);

    //Set Address
    contractAddr.history = proxyActionRepo.address;
    //Log
    console.log("Deployed ActionRepo Contract to " + contractAddr.history);

    if(!!hubContract) {  //If Deployed Together
      try{
        //Log
        console.log("Will Register History to Hub");

        //Set to HUB
        await hubContract.assocSet("history", contractAddr.history);
      }
      catch(error) {
        console.error("Failed to Set History Contract to Hub", error);
      }
    }
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
