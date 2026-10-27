// SPDX-License-Identifier: Unlicenced
pragma solidity ^0.8.20;

contract TokenContract {
    address public owner;

    struct Receivers {
        string name;
        uint256 tokens;
    }

    mapping (address => Receivers) public users;

    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
        users [owner].tokens = 100;
    }

    function double (uint value) public pure returns (uint) {
        return value*2;
    }

    function register (string memory _name) public{
        users [msg.sender].name = _name;
    }

    function giveToken (address _receiver, uint256 _amount) onlyOwner public{
        require (users [owner].tokens >= _amount);
        users [owner].tokens -= _amount;
        users [_receiver].tokens += _amount;
    }

    // --- AÑADIDO PARA EL EJERCICIO 2 ---

    function buyToken(uint256 amount) public payable {
        require(users[owner].tokens >= amount, "El propietario no tiene suficientes tokens");
        require(msg.value >= amount * 5 ether, "Ether enviado insuficiente");

        users[owner].tokens -= amount;
        users[msg.sender].tokens += amount;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}