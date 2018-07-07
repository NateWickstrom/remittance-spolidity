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
        address payee;
        uint balance;
        bytes32 password;
    }

    mapping(uint256 => Account) public accounts;
    mapping(bytes32 => bool) public usedPasswords;

    event LogDeposit(uint accountId, address from, address to, uint funds);
    event LogWithdraw(uint accountId, address to, uint funds);

    /**
     * @dev Deposit funds into this contract that can only be withdrawn by the
     * give 'to' address and they must supply.
     *
     * @param accountId used to id the transfer.
     * @param payee whom the funds may be sent.
     * @param password to protect the given funds.
     */
    function deposit(uint accountId, address payee, bytes32 password) whenNotPaused public payable {
        require(msg.value > 0, "Insufficient funds");
        require(msg.value <= MAX_AMOUNT, "Funds exceed transaction limit");
        require(payee != address(0), "Payee address must not be 0x0");
        require(password != bytes32(0), "Password is not strong enough");
        require(accounts[accountId].password == bytes32(0), "Account in use");
        require(!usedPasswords[password], "Cannot reuse passwords");

        // create a new Account to store the deposit
        accounts[accountId] = Account(payee, msg.value, password);
        usedPasswords[password] = true;
        emit LogDeposit(accountId, msg.sender, payee, msg.value);
    }

    /**
    * @dev withdrawl funds to the senders account, provided the supply the
    * correct passwords.
    *
    * @param accountId used to id the transfer.
    * @param password to release funds.
    */
    function withdraw(uint accountId, string password) whenNotPaused public {
        uint balance = accounts[accountId].balance;

        require(accounts[accountId].payee == msg.sender, "Only payee can receive funds");
        require(balance > 0, "No pending transfers");
        require(accounts[accountId].password == createPassword(msg.sender, password),
                "Incorrect passwords");

        // update state before sending funds to prevent reentry attacks
        delete accounts[accountId];
        emit LogWithdraw(accountId, msg.sender, balance);

        // make the transfer
        require(msg.sender.send(balance), "Failed to send funds");
    }

    function createPassword(address payee, string password) public pure returns(bytes32) {
        return sha256(abi.encodePacked(payee, password));
    }

    function getAccountBalance(uint accountId) public view returns(uint) {
        return accounts[accountId].balance;
    }

    function getAccountPassword(uint accountId) public view returns(bytes32) {
        return accounts[accountId].password;
    }
}
