// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auth {
    address private _administrator;

    constructor(address deployer) {
        _administrator = deployer;
    }

    function isAdministrator(address user) public view returns (bool) {
        return user == _administrator;
    }
}

contract Box {
    uint256 private _value;
    Auth private _auth;

    event ValueChanged(uint256 value);

    constructor() {
        _auth = new Auth(msg.sender);
    }

    function store(uint256 value) public {
        require(_auth.isAdministrator(msg.sender), "Unauthorized");
        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }
}