pragma solidity ^0.4.24;

contract UsedPasswordsInterface {
    function add(bytes32 password) public;
    function contains(bytes32 password) public view returns (bool);
}

contract UsePasswords is UsedPasswordsInterface {

    event LogPasswordAdded(bytes32 password);

    mapping(bytes32 => bool) usedPasswords;

    function add(bytes32 password) public {
        require(!usedPasswords[password], "Password is already added");

        usedPasswords[password] = true;

        emit LogPasswordAdded(password);
    }

    function contains(bytes32 password) public view returns (bool) {
        return usedPasswords[password];
    }

}
