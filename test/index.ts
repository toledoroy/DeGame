        // DataTypes.Rule memory rule = ruleGet(ruleId);
import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { task } from "hardhat/config";
import { 
  deployContract, 
  deployUUPS, 
  deployGameExt, 
  deployHub 
} from "../utils/deployment";
const { upgrades } = require("hardhat");

//Test Data
const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
let test_uri = "ipfs://QmQxkoWcpFgMa7bCzxaANWtSt43J1iMgksjNnT4vM1Apd7"; //"TEST_URI";
let test_uri2 = "ipfs://TEST2";
let actionGUID = "";
let soulTokenId = 1;  //Try to keep track of Current Soul Token ID
const soulTokens: any = {};  //Soul Token Assignment

describe("Protocol", function () {
  //Contract Instances
  let hubContract: Contract;
  let avatarContract: Contract;
  let actionContract: Contract;
  let gameContract: Contract;
  // let unOwnedTokenId: number;

  //Addresses
  let owner: Signer;
  let admin: Signer;
  let admin2: Signer;
  let tester: Signer;
  let tester2: Signer;
  let tester3: Signer;
  let tester4: Signer;
  let tester5: Signer;
  let authority: Signer;
  let addrs: Signer[];


  before(async function () {

    //Populate Accounts
    [owner, admin, admin2, tester, tester2, tester3, tester4, tester5, authority, ...addrs] = await ethers.getSigners();

    //Addresses
    this.ownerAddr = await owner.getAddress();
    this.adminAddr = await admin.getAddress();
    this.admin2Addr = await admin2.getAddress();
    this.testerAddr = await tester.getAddress();
    this.tester2Addr = await tester2.getAddress();
    this.tester3Addr = await tester3.getAddress();
    this.tester4Addr = await tester4.getAddress();
    this.tester5Addr = await tester5.getAddress();
    this.authorityAddr = await authority.getAddress();


    //--- Deploy Mock ERC20 Token
    this.token = await deployContract("Token", []);
    //Mint 
    this.token.mint(this.ownerAddr, 1000);
    this.token.mint(this.adminAddr, 1000);
    this.token.mint(this.testerAddr, 1000);

    //--- OpenRepo Upgradable (UUPS)
    this.openRepo = await deployUUPS("OpenRepoUpgradable", []);


    /* MOVED TO deployHub()
    //--- Game Upgradable Implementation
    this.gameUpContract = await deployContract("GameUpgradable", []);

    //--- Claim Implementation
    this.claimContract = await deployContract("ClaimUpgradable", []);
    
    //--- Task Implementation
    this.taskContract = await deployContract("TaskUpgradable", []);
    
    //--- Hub Upgradable (UUPS)
    hubContract = await deployUUPS("HubUpgradable", [
        this.openRepo.address,
        this.gameUpContract.address, 
        this.claimContract.address
      ]);
    await hubContract.deployed();
    */

    hubContract = await deployHub(this.openRepo.address);

    //--- Game Extensions  
    //Game Extension: Court of Law
    // let extCourt = await deployContract("CourtExt", []);
    // await hubContract.assocAdd("GAME_COURT", extCourt.address);
    //Deploy All Game Extensions
    deployGameExt(hubContract);

  
    //--- Rule Repository
    this.ruleRepo = await deployContract("RuleRepo", []);
    //Set to Hub
    await hubContract.assocSet("RULE_REPO", this.ruleRepo.address);

    //--- Soul Upgradable (UUPS)
    avatarContract = await deployUUPS("SoulUpgradable", [hubContract.address]);

    //Set Avatar Contract to Hub
    await hubContract.assocSet("SBT", avatarContract.address);

    //--- History Upgradable (UUPS)
    actionContract = await deployUUPS("ActionRepoTrackerUp", [hubContract.address]);

    //Set Avatar Contract to Hub
    await hubContract.assocSet("history", actionContract.address);

  });


  describe("OpenRepo", function () {

    it("Should Get Empty Value", async function () {
      //Change to Closed Game
      await this.openRepo.stringGet("TestKey");
      await this.openRepo.boolGet("TestKey");
      await this.openRepo.addressGet("TestKey");
    });

  });

  /**
   * Action Repository
   */
   describe("Action Repository", function () {
  
    it("Should store Actions", async function () {
      let action = {
        subject: "founder",     //Accused Role
        verb: "breach",
        object: "contract",
        tool: "",
      };

      // actionGUID = '0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2'; //Wrong GUID
      actionGUID = await actionContract.actionHash(action); //Gets hash if exists or not
      // console.log("actionGUID:", actionGUID);
      let tx = await actionContract.actionAdd(action, test_uri);
      await tx.wait();
      //Expect Added Event
      await expect(tx).to.emit(actionContract, 'ActionAdded').withArgs(1, actionGUID, action.subject, action.verb, action.object, action.tool);
      // await expect(tx).to.emit(actionContract, 'URI').withArgs(actionGUID, test_uri);

      //Fetch Action's Struct
      let actionRet = await actionContract.actionGet(actionGUID);
      
      // console.log("actionGet:", actionRet);
      // expect(Object.values(actionRet)).to.eql(Object.values(action));
      expect(actionRet).to.include.members(Object.values(action));
      // expect(actionRet).to.eql(action);  //Fails
      // expect(actionRet).to.include(action); //Fails
      // expect(actionRet).to.own.include(action); //Fails

      //Additional Rule Data
      expect(await actionContract.actionGetURI(actionGUID)).to.equal(test_uri);
      // expect(await actionContract.actionGetConfirmation(actionGUID)).to.include.members(["authority", true]);    //TODO: Find a better way to check this
    });

  }); //Action Repository

  describe("Soul", function () {

    it("Should inherit protocol owner", async function () {
      expect(await avatarContract.owner()).to.equal(this.ownerAddr);
    });
    
    it("Can mint", async function () {
      //SBT Tokens
      
      let tx = await avatarContract.connect(tester).mint(test_uri);
      tx.wait();
      //Fetch Token
      let result = await avatarContract.ownerOf(soulTokenId);
      //Check Owner
      expect(result).to.equal(this.testerAddr);
      //Check URI
      expect(await avatarContract.tokenURI(soulTokenId)).to.equal(test_uri);
      ++soulTokenId;
      
      await avatarContract.connect(tester2).mint(test_uri);
      soulTokens.tester2 = await avatarContract.tokenByAddress(this.tester2Addr);
      ++soulTokenId;

      await avatarContract.connect(admin2).mint(test_uri);
      soulTokens.admin2 = await avatarContract.tokenByAddress(this.admin2Addr);
      ++soulTokenId;
    });

    it("Can mint only one", async function () {
      //Another Mint Call for Same Account Should Fail
      await expect(
        avatarContract.connect(tester).mint(test_uri)
      ).to.be.revertedWith("Requesting account already has a token");
    });

    it("Should Index Addresses", async function () {
      //Expected Token ID
      let tokenId = 1;
      //Fetch Token ID By Address
      let result = await avatarContract.tokenByAddress(this.testerAddr);
      //Check Token
      expect(result).to.equal(tokenId);
    });

    it("Allow Multiple Owner Accounts per Avatar", async function () {
      let miscAddr = await addrs[0].getAddress();
      let tokenId = 1;
      //Fetch Token ID By Address
      let tx = await avatarContract.tokenOwnerAdd(miscAddr, tokenId);
      tx.wait();
      //Expected Event
      await expect(tx).to.emit(avatarContract, 'Transfer').withArgs(ZERO_ADDR, miscAddr, tokenId);
      //Fetch Token For Owner
      let result = await avatarContract.tokenByAddress(miscAddr);
      //Validate
      expect(result).to.equal(tokenId);
    });

    it("Should Post as Owned-Soul", async function () {
      soulTokens.tester = await avatarContract.tokenByAddress(this.testerAddr);
      let post = {
        tokenId: soulTokens.tester,
        uri:test_uri,
      };

      //Validate Permissions
      await expect(
        //Failed Post
        avatarContract.connect(tester4).post(post.tokenId, post.uri)
      ).to.be.revertedWith("POST:SOUL_NOT_YOURS");

      //Successful Post
      let tx = await avatarContract.connect(tester).post(post.tokenId, post.uri);
      await tx.wait();  //wait until the transaction is mined
      //Expect Event
      await expect(tx).to.emit(avatarContract, 'Post').withArgs(this.testerAddr, post.tokenId, post.uri);
    });

    /* CANCELLED Lost-Souls Feature
    it("Can add other people", async function () {
      unOwnedTokenId = await avatarContract.connect(tester).callStatic.add(test_uri);
      await avatarContract.connect(tester).add(test_uri);
      await avatarContract.connect(tester).add(test_uri);
      let tx = await avatarContract.connect(tester).add(test_uri);
      soulTokenId = soulTokenId + 3;
      tx.wait();
      // console.log("minting", tx);
      //Fetch Token
      let result = await avatarContract.ownerOf(unOwnedTokenId);
      //Check Owner
      expect(result).to.equal(await avatarContract.address);
      //Check URI
      expect(await avatarContract.tokenURI(3)).to.equal(test_uri);
    });
    
    it("Should Post as a Lost-Soul", async function () {
      let post = {
        tokenId: unOwnedTokenId,
        uri: test_uri,
      };
      //Validate Permissions
      await expect(
        //Failed Post
        avatarContract.connect(tester4).post(post.tokenId, post.uri)
      ).to.be.revertedWith("POST:SOUL_NOT_YOURS");

      //Successful Post
      let tx = await avatarContract.post(post.tokenId, post.uri);
      await tx.wait();  //wait until the transaction is mined
      //Expect Event
      await expect(tx).to.emit(avatarContract, 'Post').withArgs(this.ownerAddr, post.tokenId, post.uri);
    });
    */

    // it("[TBD] Should Merge Avatars", async function () {

    // });
    
    it("Should NOT be transferable", async function () {
      //Should Fail to transfer -- "Sorry, assets are non-transferable"
      let fromAddr = await tester.getAddress();
      let toAddr = await tester2.getAddress();
      await expect(
        avatarContract.connect(tester).transferFrom(fromAddr, toAddr, 1)
      ).to.be.revertedWith("Sorry, assets are non-transferable");
    });

    it("Can update token's metadata", async function () {
      let test_uri = "TEST_URI_UPDATED";
      //Update URI
      await avatarContract.connect(tester).update(1, test_uri);
      //Check URI
      expect(await avatarContract.connect(tester).tokenURI(1)).to.equal(test_uri);
    });

    it("Should protect from unauthorized reputation changes", async function () {
      //Rep Call Data      
      let repCall = { tokenId:1, domain:"personal", rating:1, amount:2};
      //Should Fail - Require Permissions
      await expect(
        avatarContract.repAdd(repCall.tokenId, repCall.domain, repCall.rating, repCall.amount)
      ).to.be.revertedWith("UNAUTHORIZED_ACCESS");
    });

  }); //Soul

  /**
   * Game Contract
   */
  describe("Game", function () {
    
    before(async function () {
      //Mint Avatars for Participants
      await avatarContract.connect(owner).mint(test_uri);
      await avatarContract.connect(admin).mint(test_uri);
      // await avatarContract.connect(tester3).mint(test_uri);
      await avatarContract.connect(tester4).mint(test_uri);
      await avatarContract.connect(tester5).mint(test_uri);
      await avatarContract.connect(authority).mint(test_uri);
      soulTokenId = soulTokenId + 5;
      let game = {
        name: "Test Game",
        type: "",
      };

      //Simulate to Get New Game Address
      let gameAddr = await hubContract.callStatic.gameMake(game.type, game.name, test_uri);
      // let gameAddr = await hubContract.connect(admin).callStatic.gameMake(game.type, game.name, test_uri);

      //Create New Game
      // let tx = await hubContract.connect(admin).gameMake(game.type, game.name, test_uri);
      let tx = await hubContract.gameMake(game.type, game.name, test_uri);
      //Expect Valid Address
      expect(gameAddr).to.be.properAddress;
      //Expect Claim Created Event
      await expect(tx).to.emit(hubContract, 'ContractCreated').withArgs("game", gameAddr);
      await expect(tx).to.emit(avatarContract, 'SoulType').withArgs(soulTokenId, "GAME");
      // console.log("Current soulTokenId", soulTokenId);
      ++soulTokenId;
      //Init Game Contract Object
      gameContract = await ethers.getContractFactory("GameUpgradable").then(res => res.attach(gameAddr));
      this.gameContract = gameContract;
    });

    it("Should Update Contract URI", async function () {
      //Before
      expect(await this.gameContract.contractURI()).to.equal(test_uri);
      //Change
      await this.gameContract.setContractURI(test_uri2);
      //After
      expect(await this.gameContract.contractURI()).to.equal(test_uri2);
    });

    it("Users can join as a member", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.testerAddr, "member")).to.equal(false);
      //Join Game
      await this.gameContract.connect(tester).join();
      //Check After
      expect(await this.gameContract.roleHas(this.testerAddr, "member")).to.equal(true);
    });

    it("Role Should Track Avatar Owner", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.tester5Addr, "member")).to.equal(false);
      // expect(await this.gameContract.roleHas(this.tester5Addr, "member")).to.equal(false);
      //Join Game
      await this.gameContract.connect(tester5).join();
      //Check
      expect(await this.gameContract.roleHas(this.tester5Addr, "member")).to.equal(true);
      //Get Tester5's Avatar TokenID
      let tokenId = await avatarContract.tokenByAddress(this.tester5Addr);
      // console.log("Tester5 Avatar Token ID: ", tokenId);
      //Move Avatar Token to Tester3
      let tx = await avatarContract.transferFrom(this.tester5Addr, this.tester3Addr, tokenId);
      await tx.wait();
      await expect(tx).to.emit(avatarContract, 'Transfer').withArgs(this.tester5Addr, this.tester3Addr, tokenId);
      //Expect Change of Ownership
      expect(await avatarContract.ownerOf(tokenId)).to.equal(this.tester3Addr);
      //Check Membership
      expect(await this.gameContract.roleHas(this.tester3Addr, "member")).to.equal(true);
      // expect(await this.gameContract.roleHas(this.tester5Addr, "member")).to.equal(false);
      //Should Fail - No Avatar For Contract
      await expect(
        this.gameContract.roleHas(this.tester5Addr, "member")
      ).to.be.revertedWith("ERC1155Tracker: requested account not found on source contract");
    });

    it("Users can leave", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.testerAddr, "member")).to.equal(true);
      //Join Game
      await this.gameContract.connect(tester).leave();
      //Check After
      expect(await this.gameContract.roleHas(this.testerAddr, "member")).to.equal(false);
    });

    it("Owner can appoint Admin", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.adminAddr, "admin")).to.equal(false);
      //Should Fail - Require Permissions
      await expect(
        this.gameContract.connect(tester).roleAssign(this.adminAddr, "admin")
      ).to.be.revertedWith("INVALID_PERMISSIONS");
      //Assign Admin
      await this.gameContract.roleAssign(this.adminAddr, "admin");
      //Check After
      expect(await this.gameContract.roleHas(this.adminAddr, "admin")).to.equal(true);
    });

    it("Admin can appoint authority", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.authorityAddr, "authority")).to.equal(false);
      //Should Fail - Require Permissions
      await expect(
        this.gameContract.connect(tester2).roleAssign(this.authorityAddr, "authority")
      ).to.be.revertedWith("INVALID_PERMISSIONS");
      //Assign Authority
      await this.gameContract.connect(admin).roleAssign(this.authorityAddr, "authority");
      //Check After
      expect(await this.gameContract.roleHas(this.authorityAddr, "authority")).to.equal(true);
    });
    
    /* CANCELLED Lost-Souls Feature
    it("Admin can Assign Roles to Lost-Souls", async function () {
      //Check Before
      expect(await this.gameContract.roleHasByToken(unOwnedTokenId, "authority")).to.equal(false);
      //Assign Authority
      await this.gameContract.connect(admin).roleAssignToToken(unOwnedTokenId, "authority")
      //Check After
      expect(await this.gameContract.roleHasByToken(unOwnedTokenId, "authority")).to.equal(true);
    });
    */

    it("Can change Roles (Promote / Demote)", async function () {
      //Check Before
      expect(await this.gameContract.roleHas(this.tester4Addr, "admin")).to.equal(false);
      //Join Game
      let tx = await this.gameContract.connect(tester4).join();
      await tx.wait();
      //Check Before
      expect(await this.gameContract.roleHas(this.tester4Addr, "member")).to.equal(true);
      //Upgrade to Admin
      await this.gameContract.roleChange(this.tester4Addr, "member", "admin");
      //Check After
      expect(await this.gameContract.roleHas(this.tester4Addr, "admin")).to.equal(true);
    });
    
    it("Should store Rules", async function () {
      // let actionGUID = '0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2';//await actionContract.callStatic.actionAdd(action);
      let confirmation = {
        ruling: "authority",  //Decision Maker
        evidence: true, //Require Evidence
        witness: 1,  //Minimal number of witnesses
      };
      let rule = {
        // uint256 about;    //About What (Token URI +? Contract Address)
        about: actionGUID, //"0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2",
        affected: "investor",  //Beneficiary
        // string uri;     //Text, Conditions & additional data
        uri: "ADDITIONAL_DATA_URI",
        // bool negation;  //false - Commision  true - Omission
        negation: false,
      };
      // Effect Object (Describes Changes to Rating By Type)
      let effects1 = [
        {name:'professional', value:5, direction:false},
        {name:'social', value:5, direction:true},
      ];
      let rule2 = {
        // uint256 about;    //About What (Token URI +? Contract Address)
        about: actionGUID, //"0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2",
        affected: "god",  //Beneficiary
        // string uri;     //Text, Conditions & additional data
        uri: "ADDITIONAL_DATA_URI",
        // bool negation;  //false - Commision  true - Omission
        negation: false,
      };
      // Effect Object (Describes Changes to Rating By Type)
      let  effects2 = [
        {name:'environmental', value:10, direction:false},
        {name:'personal', value:4, direction:true},
      ];
     
      //Add Rule
      let tx = await gameContract.connect(admin).ruleAdd(rule, confirmation, effects1);
      // const gameRules = await ethers.getContractAt("IRules", this.gameContract.address);
      // let tx = await gameRules.connect(admin).ruleAdd(rule, confirmation, effects1);
      
      // wait until the transaction is mined
      await tx.wait();
      // const receipt = await tx.wait()
      // console.log("Rule Added", receipt.logs);
      // console.log("Rule Added Events: ", receipt.events);

      //Expect Event
      await expect(tx).to.emit(this.ruleRepo, 'Rule').withArgs(gameContract.address, 1, rule.about, rule.affected, rule.uri, rule.negation);
      
      // await expect(tx).to.emit(this.ruleRepo, 'RuleEffects').withArgs(gameContract.address, 1, rule.effects.environmental, rule.effects.personal, rule.effects.social, rule.effects.professional);
      for(let effect of effects1) {
        await expect(tx).to.emit(this.ruleRepo, 'RuleEffect').withArgs(gameContract.address, 1, effect.direction, effect.value, effect.name);
      }
      await expect(tx).to.emit(this.ruleRepo, 'Confirmation').withArgs(gameContract.address, 1, confirmation.ruling, confirmation.evidence, confirmation.witness);

      //Add Another Rule
      let tx2 = await gameContract.connect(admin).ruleAdd(rule2, confirmation, effects2);
      
            
      //Expect Event
      await expect(tx2).to.emit(this.ruleRepo, 'Rule').withArgs(gameContract.address, 2, rule2.about, rule2.affected, rule2.uri, rule2.negation);
      // await expect(tx2).to.emit(this.ruleRepo, 'RuleEffects').withArgs(gameContract.address, 2, rule2.effects.environmental, rule2.effects.personal, rule2.effects.social, rule2.effects.professional);
      await expect(tx2).to.emit(this.ruleRepo, 'Confirmation').withArgs(gameContract.address, 2, confirmation.ruling, confirmation.evidence, confirmation.witness);

      // expect(await gameContract.ruleAdd(actionContract.address)).to.equal("Hello, world!");
      // let ruleData = await gameContract.ruleGet(1);
      
      // console.log("Rule Getter:", typeof ruleData, ruleData);   //some kind of object array crossbread
      // console.log("Rule Getter Effs:", ruleData.effects);  //V
      // console.log("Rule Getter:", JSON.stringify(ruleData)); //As array. No Keys
      
      // await expect(ruleData).to.include.members(Object.values(rule));
    });

    it("Should Update Rule", async function () {
      let actionGUID = '0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2';
      let rule = {
        about: actionGUID, //"0xa7440c99ff5cd38fc9e0bff1d6dbf583cc757a83a3424bdc4f5fd6021a2e90e2",
        affected: "god",  //Beneficiary
        uri: "ADDITIONAL_DATA_URI",
        negation: false,
      };
      let  effects = [
        {name:'environmental', value:1, direction:false},
        {name:'personal', value:1, direction:true},
      ];
      let tx = await gameContract.connect(admin).ruleUpdate(2, rule, effects);

      // let curEffects = await gameContract.effectsGet(2);
      // console.log("Effects", curEffects);
      // expect(curEffects).to.include.members(Object.values(effects));    //Doesn't Work...

    });

    it("Should Write a Post", async function () {
      let post = {
        entRole:"member",
        tokenId: soulTokens.tester,
        uri:test_uri,
      };

      //Join Game
      let tx1 = await this.gameContract.connect(tester).join();
      await tx1.wait();
      //Make Sure Account Has Role
      expect(await this.gameContract.roleHas(this.testerAddr, "member")).to.equal(true);

      //Validate Permissions
      await expect(
        //Failed Post
        this.gameContract.connect(tester4).post(post.entRole, post.tokenId, post.uri)
      ).to.be.revertedWith("POST:SOUL_NOT_YOURS");

      //Successful Post
      let tx2 = await this.gameContract.connect(tester).post(post.entRole, post.tokenId, post.uri);
      await tx2.wait();  //wait until the transaction is mined
      //Expect Event
      await expect(tx2).to.emit(this.gameContract, 'Post').withArgs(this.testerAddr, post.tokenId, post.entRole, post.uri);
    });
    
    it("Should Update Membership Token URI", async function () {
      //Protected
      await expect(
        gameContract.connect(tester3).setRoleURI("admin", test_uri)
      ).to.be.revertedWith("INVALID_PERMISSIONS");
      //Set Admin Token URI
      await gameContract.connect(admin).setRoleURI("admin", test_uri);
      //Validate
      expect(await gameContract.roleURI("admin")).to.equal(test_uri);
    });

    describe("Closed Game", function () {

      it("Can Close Game", async function () {
        //Change to Closed Game
        let tx = await this.gameContract.connect(admin).confSet("isClosed", "true");
        //Expect Claim Created Event
        await expect(tx).to.emit(this.openRepo, 'StringSet').withArgs(this.gameContract.address, "isClosed", "true");
        //Validate
        expect(await this.gameContract.confGet("isClosed")).to.equal("true");
      });

      it("Should Fail to Join Game", async function () {
        //Validate Permissions
        await expect(
          gameContract.connect(tester4).join()
        ).to.be.revertedWith("CLOSED_SPACE");
      });
      
      it("Can Apply to Join", async function () {
        //Apply to Join Game
        let tx = await this.gameContract.connect(tester).nominate(soulTokens.tester, test_uri);
        await tx.wait();
        //Expect Event
        await expect(tx).to.emit(gameContract, 'Nominate').withArgs(this.testerAddr, soulTokens.tester, test_uri);
      });

      it("Can Re-Open Game", async function () {
        //Change to Closed Game
        await this.gameContract.connect(admin).confSet("isClosed", "false");
        //Validate
        expect(await this.gameContract.confGet("isClosed")).to.equal("false");
      });
      
    }); //Closed Game

    
    it("Should Report Event", async function () {
      let eventData = {
        ruleId: 1,
        account: this.tester2Addr,
        uri: test_uri,
      };
      
      //Report Event
      let tx = await this.gameContract.connect(authority).reportEvent(eventData.ruleId, eventData.account, eventData.uri);

      // const receipt = await tx.wait();
      // console.log("Rule Added", receipt.logs);
      // console.log("Rule Added Events: ", receipt.events);

      //Validate
      await expect(tx).to.emit(this.gameContract, 'EffectsExecuted').withArgs(soulTokens.tester2, eventData.ruleId, "0x");
    });
    
    describe("Game Extensions", function () {

      it("Should Set DAO Extension Contract", async function () {
        //Deploy Extensions
        let dummyContract1 = await deployContract("Dummy", []);
        let dummyContract2 = await deployContract("Dummy2", []);
        //Set DAO Extension Contract
        await hubContract.assocAdd("GAME_DAO", dummyContract1.address);
        await hubContract.assocAdd("GAME_DAO", dummyContract2.address);
        // console.log("Setting GAME_DAO Extension: ", dummyContract1.address);
        // console.log("Setting GAME_DAO Extension: ", dummyContract2.address);
      });

      it("Should Set Game Type", async function () {
        //Change Game Type
        await this.gameContract.connect(admin).confSet("type", "DAO");
        //Validate
        expect(await this.gameContract.confGet("type")).to.equal("DAO");
      });

      it("Should Fallback to Extension Function", async function () {
        this.daoContract = await ethers.getContractFactory("Dummy2").then(res => res.attach(this.gameContract.address));
        this.daoContract2 = await ethers.getContractFactory("Dummy2").then(res => res.attach(this.gameContract.address));
        //First Dummy        
        expect(await await this.daoContract.debugFunc()).to.equal("Hello World Dummy");
        //Second Dummy
        expect(await await this.daoContract2.debugFunc2()).to.equal("Hello World Dummy 2");
        //Second Dummy Extracts Data from Main Game Contract
        expect(await await this.daoContract2.useSelf()).to.equal("Game Type: DAO");
      });

    }); //Game Extensions
    
  }); //Game

  /**
   * Projects Flow
   */
  describe("Task (Bounty) Flow", function () {

    before(async function () {


      //-- Deploy MicroDAO Game Extension
      // let mDAOExtContract = await deployContract("MicroDAOExt", []);
      //Set Project Extension Contract
      // await hubContract.assocAdd("GAME_MDAO", mDAOExtContract.address);
        
      // //Game Extension: mDAO
      // await deployContract("MicroDAOExt", []).then(res => {
      //   hubContract.assocAdd("GAME_MDAO", res.address);
      // });
      
      // //Game Extension: Fund Management
      // await deployContract("FundManExt", []).then(res => {
      //   hubContract.assocAdd("GAME_MDAO", res.address);
      // });

      //Deploy All Game Extensions
    // deployGameExt(hubContract);



      //-- Deploy a new Game:MicroDAO
      let gameMDAOData = {name: "Test mDAO", type: "MDAO"};
      //Simulate to Get New Game Address
      let gameMDAOAddr = await hubContract.connect(admin2).callStatic.gameMake(gameMDAOData.type, gameMDAOData.name, test_uri);
      // let gameAddr = await hubContract.callStatic.gameMake(game.type, game.name, test_uri);
      //Create New Game
      await hubContract.connect(admin2).gameMake(gameMDAOData.type, gameMDAOData.name, test_uri);
      // await hubContract.gameMake(game.type, game.name, test_uri);
      ++soulTokenId;
      //Init Game Contract Object
      this.mDAOGameContract = await ethers.getContractFactory("GameUpgradable").then(res => res.attach(gameMDAOAddr));
      //Attach Project Functionality
      this.mDAOContract = await ethers.getContractFactory("MicroDAOExt").then(res => res.attach(gameMDAOAddr));
      //Attach Project Functionality
      this.mDAOFundsContract = await ethers.getContractFactory("FundManExt").then(res => res.attach(gameMDAOAddr));

      //-- Deploy Project Game Extension
      let projectExtContract = await deployContract("ProjectExt", []);
      //Set Project Extension Contract
      await hubContract.assocAdd("GAME_PROJECT", projectExtContract.address);

      //-- Deploy a new Game:Project        
      let game = {name: "Test Project", type: "PROJECT"};
      //Simulate to Get New Game Address
      let gameProjAddr = await hubContract.connect(admin).callStatic.gameMake(game.type, game.name, test_uri);
      // let gameProjAddr = await hubContract.callStatic.gameMake(game.type, game.name, test_uri);
      //Create New Game
      await hubContract.connect(admin).gameMake(game.type, game.name, test_uri);
      // await hubContract.gameMake(game.type, game.name, test_uri);
      ++soulTokenId;

      //Init Game Contract Object
      this.projectGameContract = await ethers.getContractFactory("GameUpgradable").then(res => res.attach(gameProjAddr));
      //Attach Project Functionality
      this.projectContract = await ethers.getContractFactory("ProjectExt").then(res => res.attach(gameProjAddr));

      //Soul Tokens
      soulTokens.mDAO1 = await avatarContract.tokenByAddress(gameMDAOAddr);
      soulTokens.proj1 = await avatarContract.tokenByAddress(gameProjAddr);
      // console.log("[DEBUG] mDAO is:", soulTokens.mDAO1, gameMDAOAddr);
    });

    it("Game Should be of Type:PROJECT", async function () {
      //Change Game Type to Court
      // await this.projectContract.connect(admin).confSet("type", "PROJECT");
      //Validate
      expect(await this.projectGameContract.confGet("type")).to.equal("PROJECT");
    });

    it("Project Should Create a Task ", async function () {
      let value = 100; //ethers.utils.parseEther(0.001);
      let taskData = {name: "Test Task", uri: test_uri2};
      let taskAddr = await this.projectContract.connect(admin).callStatic.taskMake(taskData.name, taskData.uri);
      // this.projectContract.connect(admin).taskMake(taskData.name, taskData.uri);
      this.projectContract.connect(admin).taskMake(taskData.name, taskData.uri, {value}); //Fund on Creation
      //Attach
      this.task1 = await ethers.getContractFactory("TaskUpgradable").then(res => res.attach(taskAddr));
    });

    it("Should Fund Task (ETH)", async function () {
      let curBalance = await this.task1.contractBalance(ZERO_ADDR);
      let value = 100; //ethers.utils.parseEther(0.001);
      //Sent Native Tokens
      await admin.sendTransaction({to: this.task1.address, value});
      //Validate Balance
      expect(await this.task1.contractBalance(ZERO_ADDR))
        .to.equal(Number(curBalance) + Number(value));
    });

    it("Should Fund Task (ERC20)", async function () {
      await this.token.transfer(this.task1.address, 1);
      //Verify Transfer
      expect(await this.token.balanceOf(this.task1.address))
        .to.equal(1);
      expect(await this.task1.contractBalance(this.token.address))
        .to.equal(1);
    });

    it("Should Apply to Project (as Individual)", async function () {
      /// Apply (Nominte Self)
      let tx = await this.task1.connect(tester).application(test_uri);
      //Expect Event
      await expect(tx).to.emit(this.task1, 'Nominate').withArgs(this.testerAddr, soulTokens.tester, test_uri);
    });

    it("Should Apply to Project (as mDAO)", async function () {
      /// Apply (Nominte Self)
      let tx = await this.mDAOContract.connect(admin2).applyToTask(this.task1.address, test_uri);
      //Expect Event
      await expect(tx).to.emit(this.task1, 'Nominate').withArgs(this.mDAOContract.address, soulTokens.mDAO1, test_uri);
    });

    /// TODO: Reject Applicant (Jusdt Ignore for now / dApp Function)
    // it("Should Reject Applicant", async function () { });

    /// Accept Application (Assign Role)
    it("Should Accept mDAO as Applicant", async function () {
      //Should Fail - Require Permissions
      await expect(
        this.task1.connect(tester).acceptApplicant(soulTokens.mDAO1)
      ).to.be.revertedWith("INVALID_PERMISSIONS");
      //Accept Applicant (to Role)
      await this.task1.connect(admin).acceptApplicant(soulTokens.mDAO1);
      //Validate
      expect(await this.task1.roleHasByToken(soulTokens.mDAO1, "applicant")).to.equal(true);
    });

    /// Deliver a Task
    it("Should Post a Delivery (as mDAO)", async function () {
      let post = {taskAddr: this.task1.address, uri: test_uri2};
      //Validate Permissions
      await expect(
        this.mDAOContract.connect(tester4).deliverTask(post.taskAddr, post.uri)
      // ).to.be.revertedWith("ADMIN_ONLY");  //Would work once the proxy returns errors
      ).to.be.reverted;
      /// Apply (Nominte Self)
      let tx = await this.mDAOContract.connect(admin2).deliverTask(post.taskAddr, post.uri);
      //Expect Event
      await expect(tx).to.emit(this.task1, 'Post').withArgs(this.admin2Addr, soulTokens.mDAO1, "applicant", test_uri2);
    });

    /// Reject Delivery / Request for Changes
    it("Should Reject Delivery / Request for Changes (with a message)", async function () {
      await this.task1.connect(admin).deliveryReject(soulTokens.mDAO1, test_uri2);
    });
    
    /// Approve Delivery (Close Case w/Positive Verdict)
    it("Should Apporove Delivery", async function () {
      //Should Fail - Require Permissions
      await expect(
        this.task1.connect(tester).deliveryApprove(soulTokens.mDAO1)
      ).to.be.revertedWith("INVALID_PERMISSIONS");
      //Accept Applicant (to Role)
      await this.task1.connect(admin).deliveryApprove(soulTokens.mDAO1);
      //Check After
      expect(await this.task1.roleHasByToken(soulTokens.mDAO1, "subject")).to.equal(true);
    });

    /// Disburse funds to participants
    it("Should Disburse funds to winner(s)", async function () {
      let balanceBefore:any = {};
      balanceBefore.native = await this.task1.contractBalance(ZERO_ADDR);
      balanceBefore.token = await this.task1.contractBalance(this.token.address);
      // console.log("Before Token Balance", balanceBefore);
      //Execute with Token Relevant Contract Addresses
      await this.task1.connect(admin).stageExecusion([this.token.address]);
      //Check mDAO Balance
      // expect(await this.token.balanceOf(this.mDAOContract.address))
      expect(await this.mDAOFundsContract.contractBalance(this.token.address))
        .to.equal(balanceBefore.token);
      expect(await this.mDAOFundsContract.contractBalance(ZERO_ADDR))
        .to.equal(balanceBefore.native);
    });

    /// TODO: Deposit (Anyone can send funds at any point)

    /// Disburse funds to participants
    it("[TODO] Should Disburse additional late-funds to winner(s)", async function () {
      //Send More

      //Disbures
      await this.task1.connect(admin).disburse([this.token.address]);

      //Validate

    });

    /// Cancel Task
    // it("[TODO] Should Cancel Task", async function () { });

    /// Refund -- Send Tokens back to Task Creator
    // it("[TODO] Should Refund Toknes to Task Creator", async function () { });


  }); //Projects Flow

  /**
   * Claim Contract
   */
  describe("Claim", function () {

    describe("Court Game Flow", function () {

      before(async function () {
        //Attach Court Functionality
        this.courtContract = await ethers.getContractFactory("CourtExt").then(res => res.attach(gameContract.address));
      });
      
      it("Should Set COURT Extension Contract", async function () {
        //Change Game Type to Court
        await gameContract.connect(admin).confSet("type", "COURT");
        //Validate
        expect(await gameContract.confGet("type")).to.equal("COURT");
      });

      it("Should be Created (by Game)", async function () {
        //Soul Tokens
        soulTokens.admin = await avatarContract.tokenByAddress(this.adminAddr);
        soulTokens.tester3 = await avatarContract.tokenByAddress(this.tester3Addr);
      
        let claimName = "Test Claim #1";
        let ruleRefArr = [
          {
            game: gameContract.address, 
            ruleId: 1,
          }
        ];
        let roleRefArr = [
          {
            role: "subject",
            tokenId: soulTokens.tester2,
          },
          {
            role: "affected",
            // tokenId: unOwnedTokenId,
            tokenId: soulTokens.tester3,
          },
        ];
        let posts = [
          {
            tokenId: soulTokens.admin, 
            entRole: "admin",
            uri: test_uri,
          }
        ];

        //Join Game (as member)
        await gameContract.connect(admin).join();
        //Assign Admin as Member
        // await this.gameContract.roleAssign(this.adminAddr, "member");

        //Simulate - Get New Claim Address
        let claimAddr = await this.courtContract.connect(admin).callStatic.caseMake(claimName, test_uri, ruleRefArr, roleRefArr, posts);
        // console.log("New Claim Address: ", claimAddr);

        //Create New Claim
        let tx = await this.courtContract.connect(admin).caseMake(claimName, test_uri, ruleRefArr, roleRefArr, posts);
        //Expect Valid Address
        expect(claimAddr).to.be.properAddress;

        //Init Claim Contract
        this.claimContract = await ethers.getContractFactory("ClaimUpgradable").then(res => res.attach(claimAddr));

        //Expect Claim Created Event
        // await expect(tx).to.emit(gameContract, 'ClaimCreated').withArgs(1, claimAddr);   //DEPRECATED
        await expect(tx).to.emit(hubContract, 'ContractCreated').withArgs("claim", claimAddr);
        
        //Expect Post Event
        await expect(tx).to.emit(this.claimContract, 'Post').withArgs(this.adminAddr, posts[0].tokenId, posts[0].entRole, posts[0].uri);
      });
      
      it("Should be Created & Opened (by Game)", async function () {
        let claimName = "Test Claim #1";
        let ruleRefArr = [
          {
            game: gameContract.address, 
            ruleId: 1,
          }
        ];
        let roleRefArr = [
          {
            role: "subject",
            tokenId: soulTokens.tester2,
          },
          {
            role: "witness",
            tokenId: soulTokens.tester3,
          }
        ];
        let posts = [
          {
            tokenId: soulTokens.admin, 
            entRole: "admin",
            uri: test_uri,
          }
        ];
        //Simulate - Get New Claim Address
        let claimAddr = await this.courtContract.connect(admin).callStatic.caseMakeOpen(claimName, test_uri, ruleRefArr, roleRefArr, posts);
        //Create New Claim
        let tx = await this.courtContract.connect(admin).caseMakeOpen(claimName, test_uri, ruleRefArr, roleRefArr, posts);
        //Expect Valid Address
        expect(claimAddr).to.be.properAddress;
        //Init Claim Contract
        let claimContract = await ethers.getContractFactory("ClaimUpgradable").then(res => res.attach(claimAddr));
        
        //Expect Claim Created Event
        // await expect(tx).to.emit(gameContract, 'ClaimCreated').withArgs(2, claimAddr); //DEPRECATED
        await expect(tx).to.emit(hubContract, 'ContractCreated').withArgs("claim", claimAddr);

        //Expect Post Event
        // await expect(tx).to.emit(claimContract, 'Post').withArgs(this.adminAddr, posts[0].tokenId, posts[0].entRole, posts[0].postRole, posts[0].uri);
        await expect(tx).to.emit(claimContract, 'Post').withArgs(this.adminAddr, posts[0].tokenId, posts[0].entRole, posts[0].uri);
      });


      it("Should be Created & Closed (by Game)", async function () {
        //Soul Tokens
        soulTokens.authority = await avatarContract.tokenByAddress(this.authorityAddr);

        let claimName = "Test Claim #3";
        let ruleRefArr = [
          {
            game: gameContract.address, 
            ruleId: 1,
          }
        ];
        let roleRefArr = [
          {
            role: "subject",
            tokenId: soulTokens.tester2,
          },
          {
            role: "witness",
            tokenId: soulTokens.tester3,
          },
        ];
        let posts: any = [
          // {
          //   tokenId: soulTokens.authority, 
          //   entRole: "authority",
          //   uri: test_uri,
          // }
        ];

        //Assign as a Member (Needs to be both a member and an authority)
        // await gameContract.connect(authority).join();
        await gameContract.connect(admin).roleAssign(this.authorityAddr, "member");

        //Simulate - Get New Claim Address
        let claimAddr = await this.courtContract.connect(authority).callStatic.caseMakeClosed(claimName, test_uri, ruleRefArr, roleRefArr, posts, test_uri2);
        //Create New Claim
        let tx = await this.courtContract.connect(authority).caseMakeClosed(claimName, test_uri, ruleRefArr, roleRefArr, posts, test_uri2);
        //Expect Valid Address
        expect(claimAddr).to.be.properAddress;
        //Init Claim Contract
        let claimContract = await ethers.getContractFactory("ClaimUpgradable").then(res => res.attach(claimAddr));
        
        //Expect Claim Created Event
        // await expect(tx).to.emit(gameContract, 'ClaimCreated').withArgs(3, claimAddr);  //DEPRECATED
        await expect(tx).to.emit(hubContract, 'ContractCreated').withArgs("claim", claimAddr);

        //Expect Post Event
        // await expect(tx).to.emit(claimContract, 'Post').withArgs(this.authorityAddr, posts[0].tokenId, posts[0].entRole, posts[0].uri);

        //Expect State Change Events
        await expect(tx).to.emit(claimContract, "Stage").withArgs(1); //Open
        await expect(tx).to.emit(claimContract, "Stage").withArgs(2);  //Verdict
        await expect(tx).to.emit(claimContract, "Stage").withArgs(6);  //Closed
      });
      
      it("Should Update Claim Contract URI", async function () {
        //Before
        expect(await this.claimContract.contractURI()).to.equal(test_uri);
        //Change
        await this.claimContract.setContractURI(test_uri2);
        //After
        expect(await this.claimContract.contractURI()).to.equal(test_uri2);
      });

      it("Should Auto-Appoint creator as Admin", async function () {
        expect(
          await this.claimContract.roleHas(this.adminAddr, "admin")
        ).to.equal(true);
      });

      it("Tester expected to be in the subject role", async function () {
        expect(
          await this.claimContract.roleHas(this.tester2Addr, "subject")
        ).to.equal(true);
      });

      it("Users Can Apply to Join", async function () {
        //Apply to Join Game
        let tx = await this.claimContract.connect(tester).nominate(soulTokens.tester, test_uri);
        await tx.wait();
        //Expect Event
        await expect(tx).to.emit(this.claimContract, 'Nominate').withArgs(this.testerAddr, soulTokens.tester, test_uri);
      });

      it("Should Update", async function () {
        // let testClaimContract = await ethers.getContractFactory("ClaimUpgradable").then(res => res.deploy());
        let testClaimContract = await deployContract("ClaimUpgradable", []);
        await testClaimContract.deployed();
        //Update Claim Beacon (to the same implementation)
        hubContract.upgradeImplementation("claim", testClaimContract.address);
      });

      it("Should Add Rules", async function () {
        let ruleRef = {
          game: gameContract.address, 
          id: 2, 
          // affected: "investor",
        };
        // await this.claimContract.ruleRefAdd(ruleRef.game,  ruleRef.id, ruleRef.affected);
        await this.claimContract.connect(admin).ruleRefAdd(ruleRef.game,  ruleRef.id);
      });
      
      it("Should Write a Post", async function () {
        let post = {
          tokenId: soulTokens.tester2,
          entRole:"subject",
          uri:test_uri,
        };

        //Validate Permissions
        await expect(
          //Failed Post
          this.claimContract.connect(tester).post(post.entRole, post.tokenId, post.uri)
        ).to.be.revertedWith("POST:SOUL_NOT_YOURS");

        //Successful Post
        let tx = await this.claimContract.connect(tester2).post(post.entRole, post.tokenId, post.uri);
        // wait until the transaction is mined
        await tx.wait();
        //Expect Event
        await expect(tx).to.emit(this.claimContract, 'Post').withArgs(this.tester2Addr, post.tokenId, post.entRole, post.uri);
      });

      it("Should Update Token URI", async function () {
        //Protected
        await expect(
          this.claimContract.connect(tester3).setRoleURI("admin", test_uri)
        ).to.be.revertedWith("INVALID_PERMISSIONS");
        //Set Admin Token URI
        await this.claimContract.connect(admin).setRoleURI("admin", test_uri);
        //Validate
        expect(await this.claimContract.roleURI("admin")).to.equal(test_uri);
      });

      it("Should Assign Witness", async function () {
        //Assign Admin
        await this.claimContract.connect(admin).roleAssign(this.tester3Addr, "witness");
        //Validate
        expect(await this.claimContract.roleHas(this.tester3Addr, "witness")).to.equal(true);
      });

      it("Game Authoritys Can Assign Themselves to Claim", async function () {
        //Assign as Game Authority
        gameContract.connect(admin).roleAssign(this.tester4Addr, "authority")
        //Assign Claim Authority
        await this.claimContract.connect(tester4).roleAssign(this.tester4Addr, "authority");
        //Validate
        expect(await this.claimContract.roleHas(this.tester4Addr, "authority")).to.equal(true);
      });

      it("User Can Open Claim", async function () {
        //Validate
        await expect(
          this.claimContract.connect(tester2).stageFile()
        ).to.be.revertedWith("ROLE:CREATOR_OR_ADMIN");
        //File Claim
        let tx = await this.claimContract.connect(admin).stageFile();
        //Expect State Event
        await expect(tx).to.emit(this.claimContract, "Stage").withArgs(1);
      });

      it("Should Validate Authority with parent game", async function () {
        //Validate
        await expect(
          this.claimContract.connect(admin).roleAssign(this.tester3Addr, "authority")
        ).to.be.revertedWith("User Required to hold same role in the Game context");
      });

      it("Anyone Can Apply to Join", async function () {
        //Apply to Join Game
        let tx = await this.claimContract.connect(tester).nominate(soulTokens.tester, test_uri);
        await tx.wait();
        //Expect Event
        await expect(tx).to.emit(this.claimContract, 'Nominate').withArgs(this.testerAddr, soulTokens.tester, test_uri);
      });

      it("Should Accept a Authority From the parent game", async function () {
        //Check Before
        // expect(await this.gameContract.roleHas(this.testerAddr, "authority")).to.equal(true);
        //Assign Authority
        await this.claimContract.connect(admin).roleAssign(this.authorityAddr, "authority");
        //Check After
        expect(await this.claimContract.roleHas(this.authorityAddr, "authority")).to.equal(true);
      });
      
      it("Should Wait for Verdict Stage", async function () {
        //File Claim
        let tx = await this.claimContract.connect(authority).stageWaitForDecision();
        //Expect State Event
        await expect(tx).to.emit(this.claimContract, "Stage").withArgs(2);
      });

      it("Should Wait for authority", async function () {
        let verdict = [{ ruleId:1, decision: true }];
        //File Claim -- Expect Failure
        await expect(
          this.claimContract.connect(tester2).stageDecision(verdict, test_uri)
        ).to.be.revertedWith("ROLE:AUTHORITY_ONLY");
      });

      it("Should Accept Verdict URI & Close Claim", async function () {
        let verdict = [{ruleId:1, decision:true}];
        //Submit Verdict & Close Claim
        let tx = await this.claimContract.connect(authority).stageDecision(verdict, test_uri);
        //Expect Verdict Event
        await expect(tx).to.emit(this.claimContract, 'Verdict').withArgs(test_uri, this.authorityAddr);
        //Expect State Event
        await expect(tx).to.emit(this.claimContract, "Stage").withArgs(6);
      });

      // it("[TODO] Can Change Rating", async function () {

        //TODO: Tests for Collect Rating
        // let repCall = { tokenId:?, domain:?, rating:?};
        // let result = this.gameContract.getRepForDomain(avatarContract.address,repCall. tokenId, repCall.domain, repCall.rating);

        // //Expect Event
        // await expect(tx).to.emit(avatarContract, 'ReputationChange').withArgs(repCall.tokenId, repCall.domain, repCall.rating, repCall.amount);

        //Validate State
        // getRepForDomain(address contractAddr, uint256 tokenId, string domain, bool rating) public view override returns (uint256) {

        // let rep = await avatarContract.getRepForDomain(repCall.tokenId, repCall.domain, repCall.rating);
        // expect(rep).to.equal(repCall.amount);

        // //Other Domain Rep - Should be 0
        // expect(await avatarContract.getRepForDomain(repCall.tokenId, repCall.domain + 1, repCall.rating)).to.equal(0);

      // });

    }); //Court Game

  }); //Claim
    
});
