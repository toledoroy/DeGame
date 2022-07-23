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
  //Game Extension: Court of Law
  // let extCourt = await deployContract("CourtExt", []);
  // await hubContract.assocAdd("GAME_COURT", extCourt.address);
  await deployContract("CourtExt", []).then(res => {
    hubContract.assocSet("GAME_MDAO", res.address);
    console.log("Deployed Game assocAdd Extension ", res.address);
    // verify(res.address, []);
  });
  //Game Extension: mDAO
  await deployContract("MicroDAOExt", []).then(res => {
    hubContract.assocSet("GAME_MDAO", res.address);
    console.log("Deployed Game MicroDAOExt Extension ", res.address);
    // verify(res.address, []);
  });
  //Game Extension: Fund Management
  await deployContract("FundManExt", []).then(res => {
    hubContract.assocAdd("GAME_MDAO", res.address);
    console.log("Deployed Game FundManExt Extension ", res.address);
    // verify(res.address, []);
  });
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



