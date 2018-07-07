pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';

/**
 * @title Remittance
 *
 * @dev The Remittance contract allows the owner to deposit funds and the receiver
 * to receive them as long as they supply the correct passcodes.
 */
contract Remittance is Pausable {

    // maximum amount of wei that can be transfered at a time
    uint constant MAX_AMOUNT = 1000000000;

    struct Account {
        uint balance;
        bytes32 password;
    }

    mapping(uint256 => Account) public accounts;
    mapping(bytes32 => bool) public usedPasswords;

    event LogDeposit(uint accountId, address from, uint funds);
    event LogWithdraw(uint accountId, address to, uint funds);

    /**
     * @dev Deposit funds into this contract that can only be withdrawn by the
     * give 'to' address and they must supply.
     *
     * @param accountId used to id the transfer.
     * @param password to protect the given funds.
     */
    function deposit(uint accountId, bytes32 password) whenNotPaused public payable {
        require(msg.value > 0, "Insufficient funds");
        require(msg.value <= MAX_AMOUNT, "Funds exceed transaction limit");
        require(password != bytes32(0), "Password is not strong enough");
        require(accounts[accountId].password == bytes32(0), "Account in use");
        require(!usedPasswords[password], "Cannot reuse passwords");

        // create a new Account to store the deposit
        accounts[accountId] = Account(msg.value, password);
        usedPasswords[password] = true;
        emit LogDeposit(accountId, msg.sender, msg.value);
    }

    /**
    * @dev withdrawl funds to the senders account, provided the supply the
    * correct passwords.
    *
    * @param accountId used to id the transfer.
    * @param exchangePassword intermediary password.
    * @param recipientPassword final recipient password.
    */
    function withdraw(uint accountId, string exchangePassword, string recipientPassword) whenNotPaused public {
        uint balance = accounts[accountId].balance;
        bytes32 password = accounts[accountId].password;

        require(balance > 0, "No pending transfers");
        require(password == createPassword(exchangePassword, recipientPassword),
                "Incorrect passwords");

        // update state before sending funds to prevent reentry attacks
        delete accounts[accountId];
        emit LogWithdraw(accountId, msg.sender, balance);

        // make the transfer
        require(msg.sender.send(balance), "Failed to send funds");
    }

    function createPassword(string part1, string part2) public pure returns(bytes32) {
        return sha256(abi.encodePacked(part1, part2));
    }

    function getAccountBalance(uint accountId) public view returns(uint) {
        return accounts[accountId].balance;
    }

    function getAccountPassword(uint accountId) public view returns(bytes32) {
        return accounts[accountId].password;
    }
}
