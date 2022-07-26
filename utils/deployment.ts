import { Contract } from "ethers";
import { run } from "hardhat";
import { ethers } from "hardhat";
const { upgrades } = require("hardhat");
// import { deployments, ethers } from "hardhat"
// export const deployRepoRules = async (contractAddress: string, args: any[]) => {
// }

/// Deploy Regular Contrac
export const deployContract = async (contractName: string, args: any[]) => {
  return await ethers.getContractFactory(contractName).then(res => res.deploy(args));
}

/// Deploy Upgradable Contract (UUPS)
export const deployUUPS = async (contractName: string, args: any[]) => {
  return await ethers.getContractFactory(contractName)
    .then(Contract => upgrades.deployProxy(Contract, args, {kind: "uups", timeout: 120000}));
}

/// Deploy Game Extensions
export const deployGameExt = async (hubContract: Contract) => {
  console.log("Start Deploying Game Extensions...");
  let verification:any = [];
  //Game Extension: Court of Law
  await deployContract("CourtExt", []).then(async res => {
    await hubContract.assocSet("GAME_COURT", res.address);
    console.log("Deployed Game CourtExt Extension ", res.address);
    verification.push({name:"CourtExt", address:res.address, params:[]});
  });
  //Game Extension: mDAO
  await deployContract("MicroDAOExt", []).then(async res => {
    await hubContract.assocSet("GAME_MDAO", res.address);
    console.log("Deployed Game MicroDAOExt Extension ", res.address);
    verification.push({name:"MicroDAOExt", address:res.address, params:[]});
  });
  //Game Extension: Fund Management
  await deployContract("FundManExt", []).then(async res => {
    await hubContract.assocAdd("GAME_MDAO", res.address);
    console.log("Deployed Game FundManExt Extension ", res.address);
    verification.push({name:"FundManExt", address:res.address, params:[]});
  });
  //Game Extension: Project
  await deployContract("ProjectExt", []).then(async res => {
    await hubContract.assocSet("GAME_PROJECT", res.address);
    console.log("Deployed Game ProjectExt Extension ", res.address);
    verification.push({name:"ProjectExt", address:res.address, params:[]});
  });

  //Verify Contracts
  for(let item of verification){
    console.log("Verify Contract:", item);
    await verify(item.address, item.params);
  }
}

/// Deploy Hub
export const deployHub = async (openRepoAddress: String) => {
  
    //--- Game Upgradable Implementation
    let gameUpContract = await deployContract("GameUpgradable", []);

    //--- Claim Implementation
    let claimContract = await deployContract("ClaimUpgradable", []);
    
    //--- Task Implementation
    let taskContract = await deployContract("TaskUpgradable", []);
    
    //--- Hub Upgradable (UUPS)
    let hubContract = await deployUUPS("HubUpgradable", [
      openRepoAddress,
        gameUpContract.address, 
        claimContract.address,
        taskContract.address,
      ]);
    await hubContract.deployed();
    //Return
    return hubContract;
}

/// Verify Contract on Etherscan
export const verify = async (contractAddress: string, args: any[]) => {
  console.log("Verifying contract...")
  // try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
    .catch(error => {
      if (error.message.toLowerCase().includes("already verified")) {
        console.log("Already verified!");
      } else {
        console.log("[CAUGHT] Verification Error: ", error);
      }
    });

  // } catch (e: any) {
  //   if (e.message.toLowerCase().includes("already verified")) {
  //     console.log("Already verified!");
  //   } else {
  //     console.log(e);
  //   }
  // }
}



