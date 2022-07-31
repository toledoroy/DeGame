// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { Contract } from "ethers";
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
/**
 * MISC COMMANDS
 * 
 */
async function main() {
    // let hubContract: Contract;

    //Hub Associations & Validation 
    if(contractAddr.hub){
        let hubContract = await ethers.getContractFactory("HubUpgradable").then(res => res.attach(contractAddr.hub));
        console.log("Deploy All Game Extensions & Set to Hub");
        if(hubContract){
            //Deploy All Game Extensions & Set to Hub
            deployGameExt(hubContract);
        }
    }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
