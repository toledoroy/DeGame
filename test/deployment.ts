import { expect } from "chai";
import { Contract, ContractReceipt, Signer } from "ethers";
import { ethers } from "hardhat";
import { deployContract, deployUUPS } from "../utils/deployment";
const { upgrades } = require("hardhat");


//Test Data
// const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
// let test_uri = "ipfs://QmQxkoWcpFgMa7bCzxaANWtSt43J1iMgksjNnT4vM1Apd7"; //"TEST_URI";

describe("Deployment", function () {
    let gameContract: Contract;
    let reactionContract: Contract;
    let hubContract: Contract;
    // let Contract: Contract;
    let actionRepoContract: Contract;
    let openRepoContract: Contract;
    let SoulUpgradable: Contract;
    // let actionContract: Contract;
    let oldHubContract: Contract;

    //Addresses
    let account1: Signer;
    let account2: Signer;

    before(async function () {
        //Populate Accounts
        [account1, account2] = await ethers.getSigners();

        //--- OpenRepo (UUPS)
        openRepoContract = await deployUUPS("OpenRepoUpgradable", []);

        //--- Game Implementation
        gameContract = await ethers.getContractFactory("GameUpgradable").then(res => res.deploy());
        await gameContract.deployed();

        //--- Reaction Implementation
        reactionContract = await ethers.getContractFactory("ReactionUpgradable").then(res => res.deploy());
        await reactionContract.deployed();
    });

    it("Should Deploy Upgradable Hub Contract", async function () {
        //Deploy Hub Upgradable
        const proxyHub = await deployUUPS("HubUpgradable", [
            openRepoContract.address,
            gameContract.address,
            reactionContract.address
        ]);
        await proxyHub.deployed();
        // console.log("HubUpgradable deployed to:", proxyHub.address);
        hubContract = proxyHub;
    });

    it("Should Change Hub", async function () {
       //Deploy Another Hub Upgradable
        const proxyHub2 = await deployUUPS("HubUpgradable", [
            openRepoContract.address,
            gameContract.address,
            reactionContract.address
        ]);
        await proxyHub2.deployed();
       
        // console.log("Hub Address:", hubContract.address);
    
        proxyHub2.hubChange(hubContract.address);
    });

    it("Should Deploy Upgradable Soul Contract", async function () {
        //Deploy Soul Upgradable
        const proxyAvatar = await deployUUPS("SoulUpgradable", [hubContract.address]);
        await proxyAvatar.deployed();
        this.avatarContract = proxyAvatar;
        //Set Avatar Contract to Hub
        hubContract.assocSet("SBT", proxyAvatar.address);
        // console.log("SoulUpgradable deployed to:", proxyAvatar.address);
    });

    it("Should Create an Unownd Soul", async function () {
        await this.avatarContract.add("");
    });

    it("Should Deploy History (ActionRepo)", async function () {
        //Deploy Action Repository
        const proxyActionRepo = await deployUUPS("ActionRepoTrackerUp", [hubContract.address]);
        await proxyActionRepo.deployed();
        //Set Avatar Contract to Hub
        hubContract.assocSet("history", proxyActionRepo.address);
        // this.historyContract = proxyActionRepo;
        // console.log("ActionRepoTrackerUp deployed to:", proxyActionRepo.address);
    });

    describe("Mock", function () {
        it("Should Deploy Mock Hub Contract", async function () {
            //--- Mock Hub
            let mockHub = await ethers.getContractFactory("HubMock").then(res => res.deploy(
                openRepoContract.address,
                gameContract.address,
                reactionContract.address
            ));
            await mockHub.deployed();
            // console.log("MockHub Deployed to:", mockHub.address);
        });
    });

});


