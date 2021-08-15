const { BN } = require('@openzeppelin/test-helpers');
const assert = require("assert");

const GertsCoin = artifacts.require("GertsCoin");
const Deposit = artifacts.require("Deposit");

contract("Deposit", function (accounts) {
  const [initialHolder, otherAccount] = accounts;

  beforeEach(async function () {
    coin = await GertsCoin.new();
    deposit = await Deposit.new();
  });

  describe("Deposit Contract", () => {
    it("deploys a contract", () => {
      assert.ok(deposit.address);
    });

    it("manager set", async () => {
      assert.equal(await this.deposit.manager(), initialHolder);
    });
  });

  describe("addTokenSupport", () => {
    it("token added to deposit", async () => {
      await deposit.addTokenSupport(coin.address, { from: initialHolder });
      assert.equal(await deposit.tokensSupported(coin.address), true);
    });

    it("only manager can add token", async () => {
      try {
        await deposit.addTokenSupport(coin.address, { from: otherAccount });
      } catch (error) {
        assert.equal(error.reason , "Only manager can run this function");
      }
    });
  });

  describe("removeTokenSupport", () => {
    it("token removed from contract", async () => {
      await deposit.addTokenSupport(coin.address, { from: initialHolder });
      await deposit.removeTokenSupport(coin.address, { from: initialHolder });

      assert.equal(await deposit.tokensSupported(coin.address), 0);
    });

    it("only manager can remove token", async () => {
      try {
        await deposit.addTokenSupport(coin.address, { from: initialHolder });
        await deposit.removeTokenSupport(coin.address, { from: otherAccount });
      } catch (error) {
        assert.equal(error.reason , "Only manager can run this function");
      }
    });
  });

  describe("depositETH", () => {
    it("user can deposit to contract", async () => {
      await deposit.depositETH({
        from: otherAccount,
        value: web3.utils.toWei("2", "ether"),
      });
      assert.equal(
        await deposit.balanceETH(otherAccount),
        web3.utils.toWei("2", "ether")
      );
    });

    it("value cant be empty", async () => {
      try {
        await deposit.depositETH({
          from: otherAccount,
          value: 0,
        });
      } catch (error) {
        assert.equal(error.reason , "The value can`t be empty");
      }
    });
  });

  describe("depositToken",async () => {
    it("amount must be greater then 0", async () =>{
      await deposit.addTokenSupport(coin.address);
      try {
        await deposit.depositToken(coin.address, 0, {from: initialHolder});
      } catch (error) {
        assert.equal(error.reason , "Amount of tockens cant be empty");
      }
    });
    it("sender token balance must be greater then amount", async () => {
      
      await deposit.addTokenSupport(coin.address);

      await coin.transfer(otherAccount, 1, {from: initialHolder});
      await coin.approve(deposit.address, 2, {from: otherAccount});

      try {
        await deposit.depositToken(coin.address, 2, {from: otherAccount});
      } catch(error){
        assert.equal(error.reason , "You dont have enough tokens");
      }
    });
    it("account deposit token to contract successfully", async () => {
      await deposit.addTokenSupport(coin.address);
      await coin.approve(deposit.address, 10, {from: initialHolder});

      await deposit.depositToken(coin.address, 10, {from:initialHolder});
      assert.equal(await deposit.balances(initialHolder), 10);
    });

  });

  describe("withdrawETH", () => {
    it("requested amount must be equal or lower then current deposit", async () => {
      await deposit.depositETH({from: initialHolder, value: web3.utils.toWei("3", "ether")});
      try {
        await deposit.withdrawETH(web3.utils.toWei("4", "ether"),{from: initialHolder});
      } catch(error) {
        assert.equal(error.reason, "The requested amount is greater than the current deposit");
      }
    });

    it("requested amount sent to user account", async () => {
      await deposit.depositETH({from: initialHolder, value: web3.utils.toWei("2", "ether")});
      
      const initialBalance = await web3.eth.getBalance(initialHolder);
      await deposit.withdrawETH(web3.utils.toWei("2", "ether"),{ from:initialHolder});
      const finalBalance = await web3.eth.getBalance(initialHolder);
      const difference = finalBalance - initialBalance;

      assert(difference > web3.utils.toWei("1.8", "ether"));
    });
  });

  describe("withdrawToken", () => {
    it("requested amount must be equal or lower then current deposit", async () => {
      await deposit.addTokenSupport(coin.address);
      await coin.approve(deposit.address, 10, {from: initialHolder});
      await deposit.depositToken(coin.address, 10, {from:initialHolder});

      try {
        await deposit.withdrawToken(coin.address, 11,{from: initialHolder});
      } catch(error) {
        assert.equal(error.reason, "The requested amount is greater than the current deposit");
      }
    });

    it("requested token amount sent to user account", async () => {
      
      await deposit.addTokenSupport(coin.address);
      await coin.transfer(otherAccount, 4, {from: initialHolder});

      await coin.approve(deposit.address, 2, {from: otherAccount});
      await deposit.depositToken(coin.address, 2 , {from: otherAccount});

      const initialBalance = await coin.balanceOf(otherAccount);
      await deposit.withdrawToken(coin.address, 2,{ from:otherAccount});
      const finalBalance = await coin.balanceOf(otherAccount);
      const difference = finalBalance - initialBalance;
      assert.equal(difference, web3.utils.toWei("2", "wei"));
    });
  });
});
