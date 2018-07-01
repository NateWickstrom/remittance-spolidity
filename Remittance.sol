pragma solidity ^0.4.24;

/**
 * @title Remittance
 *
 * @dev The Remittance contract allows the owner to deposit funds and the receiver
 * to receive them as long as they supply the correct passcodes.
 */
contract Remittance {

    address owner;
    address receiver;
    bytes32 passcode;

    uint funds;

    event LogDeposit(address from, uint funds);
    event LogTransfer(address to, uint funds);

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can do this"); _;
    }

    modifier onlyReceiver {
        require(msg.sender == receiver, "Only the receiver can do this"); _;
    }

    constructor(address to, bytes32 code) public {
        require(to != address(0), "To Address must not be 0");
        require(code != bytes32(0), "Passcode is not strong enough");

        owner = msg.sender;
        receiver = to;
        passcode = code;
    }

    function send() public payable onlyOwner {
        require(msg.value > 0, "Insufficient funds");

        funds = msg.value;

        emit LogDeposit(msg.sender, msg.value);
    }

    function receive(bytes8 exchangePassword, bytes8 recipientPassword) public onlyReceiver returns (bool success) {
         require(funds > 0, "Insufficient funds");

        if (passcode != sha256(exchangePassword, recipientPassword)) {
            // Don't revert here because we want to make it expesive
            // to submit wrong passwords. Just log the failure and return early.
            return false;
        }

        if (receiver.send(funds)) {
            funds = 0;
            emit LogTransfer(receiver, funds);
            // todo notifiy owner
            return true;
        }

        revert("Failed to send funds");
    }

}
