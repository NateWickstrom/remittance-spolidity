pragma solidity ^0.4.24;


/**
 * @title Remittance
 *
 * @dev The Remittance contract allows the owner to deposit funds and the receiver
 * to receive them as long as they supply the correct passcodes.
 */
contract Remittance {

    struct Account {
        uint balance;
        address payee;
        bytes32 password;
    }

    mapping(uint256 => Account) public accounts;

    event LogDeposit( uint accountId, address from, address to, uint funds);
    event LogWithdraw(uint accountId, address to, uint funds);

    /**
     * @dev Deposit funds into this contract that can only be withdrawn by the
     * give 'to' address and they must supply.
     *
     * @param accountId used to id the transfer.
     * @param payee to transfer funds to.
     * @param password to protect the given funds.
     */
    function deposit(uint accountId, address payee, bytes32 password) public payable {
        require(msg.value > 0, "Insufficient funds");
        require(payee != address(0), "To Address must not be 0");
        require(password != bytes32(0), "Password is not strong enough");
        require(accounts[accountId].password != bytes32(0), "Account in use");

        // create a new Account to store the deposit
        accounts[accountId] = Account(msg.value, payee, password);
        emit LogDeposit(accountId, msg.sender, payee, msg.value);
    }

    /**
    * @dev withdrawl funds for the senders accound, provided the supply the
    * two correct passwords.
    *
    * @param accountId used to id the transfer.
    * @param exchangePassword intermediary password.
    * @param recipientPassword final recipient password.
    */
    function withdraw(uint accountId, string exchangePassword, string recipientPassword) public {
        uint balance = accounts[accountId].balance;
        bytes32 password = accounts[accountId].password;
        address payee = accounts[accountId].payee;

        require(msg.sender == payee, "Only the payee can do this");
        require(balance > 0, "No pending transfers");
        require(password == sha256(exchangePassword, recipientPassword), "Incorrect passwords");

        // update state before sending funds to prevent reentry attacks
        delete accounts[accountId];

        // make the transfer
        require(msg.sender.send(balance), "Failed to send funds");
        emit LogWithdraw(accountId, msg.sender, balance);
    }

}
