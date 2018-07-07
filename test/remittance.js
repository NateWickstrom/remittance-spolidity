var Remittance = artifacts.require("./Remittance.sol");

contract('Remittance', function(accounts) {

  it("deposit should create a new account", function() {
        var meta;

        var account_one = accounts[0];

        var accountId = 1;
        var accountBalanceBefore;
        var accountBalanceAfter;
        var amount = 100;
        var password =  "secret";

        return Remittance.deployed().then(function(instance) {
          meta = instance;
          return meta.deposit(accountId, web3.fromUtf8(password),
                { from:account_one, value: amount, gas: 10000000,  gasPrice: 1 });
        }).then(function() {
          return meta.getAccountBalance.call(accountId);
        }).then(function(balance) {
          accountBalanceAfter = balance.toNumber();
        }).then(function() {
            assert.equal(amount, accountBalanceAfter,
              "account balance is iccorrect");
        });
  });

  it("withdraw should delete account", function() {
        var meta;

        var account_one = accounts[0];
        var account_two = accounts[1];

        var accountId = 2;
        var accountEndingBalance;
        var amount = 100;
        var passwordPart1 = "top";
        var passwordPart2 = "secret";
        var password;

        return Remittance.deployed().then(function(instance) {
          meta = instance;
          return meta.createPassword.call(passwordPart1, passwordPart2);
        }).then(function(pwd) {
          password = pwd;
          return meta.deposit(accountId, password,
                { from:account_one, value: amount, gas: 10000000,  gasPrice: 1 });
        }).then(function() {
          return meta.withdraw(accountId, passwordPart1, passwordPart2,
                { from:account_two, gas: 10000000,  gasPrice: 1 });
        }).then(function() {
          return meta.getAccountBalance.call(accountId);
        }).then(function(balance) {
          accountEndingBalance = balance.toNumber();
        }).then(function() {
          assert.equal(0, accountEndingBalance,
            "account balance is iccorrect after withdraw");
        });
  });

});
