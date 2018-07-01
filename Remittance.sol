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
        bytes32 passcode;
    }

    mapping(address => Account) public accounts;

    event LogDeposit(address from, uint funds);
    event LogWithdrawl(address to, uint funds);

    /**
     * @dev Deposit funds into this contract that can only be withdrawn by the
     * give 'to' address and they must supply.
     *
     * @param to whom to transfer funds to.
     * @param code to protect the given funds.
     */
    function deposit(address to, bytes32 code) public payable {
        require(msg.value > 0, "Insufficient funds");
        require(to != address(0), "To Address must not be 0");
        require(code != bytes32(0), "Passcode is not strong enough");
        require(hasPendingFunds(to), "Only one pending transfer per address is allowed at a time");

        // create a new Account to store the deposit
        accounts[to] = Account(msg.value, code);
        emit LogDeposit(msg.sender, msg.value);
    }

    /**
    * @dev withdrawl funds for the senders accound, provided the supply the
    * two correct passwords.
    *
    * @param exchangePassword intermediary password.
    * @param recipientPassword final recipient password.
    */
    function withdrawl(bytes8 exchangePassword, bytes8 recipientPassword) public {
        require(hasPendingFunds(msg.sender), "No pending transfers");
        // todo prevent bruteforce attacks by locking accounts after a certain number is tries
        require(accounts[msg.sender].passcode == sha256(exchangePassword, recipientPassword),
                "Incorrect passcodes");

        uint funds = accounts[msg.sender].balance;
        // update state before sending funds to prevent reentry attacks
        accounts[msg.sender] = Account(0,0);

        if (msg.sender.send(funds)) {
            emit LogWithdrawl(msg.sender, funds);
            // todo notifiy depositer transfer complete
        } else {
            revert("Failed to send funds");
        }
    }

    function hasPendingFunds(address to) private view returns (bool) {
        return accounts[to].balance > 0;
    }

}
