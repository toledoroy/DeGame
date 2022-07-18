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
  //Game Extension: Court of Law
  let extCourt = await deployContract("CourtExt", []);
  await hubContract.assocAdd("GAME_COURT", extCourt.address);

}

/// Verify Contract on Etherscan
export const verify = async (contractAddress: string, args: any[]) => {
  console.log("Verifying contract...")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
  } catch (e: any) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!")
    } else {
      console.log(e)
    }
  }
}



