// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20/IERC20.sol";

contract Deposit {
    
    address public manager;
    
    mapping(address => uint) public balances;
    mapping(address => uint) public balanceETH;   
    mapping(address => bool) public tokensSupported;

    constructor (){
       manager = msg.sender; 
    }

    modifier OnlyManager() {
     require(msg.sender == manager, "Only manager can run this function");
         _;
    }

    modifier SupportedToken(address tokenAddress) {
        require(tokensSupported[tokenAddress],'Token not supported');
        _;
    }
    
    //Events
    event DepositSuccess(
        address from,
        uint amount, 
        uint256 date
    );

    event WithdrawSuccess(
        address to,
        uint amount, 
        uint leftOnContract, 
        uint256 date
    );


    // add token support
    function addTokenSupport(address tokenAddress) public OnlyManager{
        tokensSupported[tokenAddress] = true;
    }

    // remove token support

    function removeTokenSupport(address tokenAddress) public OnlyManager {
        delete tokensSupported[tokenAddress];
    }

    // Deposit amount of ETH to contract
    function depositETH() public payable {
        require(msg.value > 0, "The value can`t be empty");
        balanceETH[payable(msg.sender)] += msg.value;
        emit DepositSuccess(msg.sender, msg.value, block.timestamp);
    }

    // Deposit supported token
    function depositToken(address tokenAddress, uint amount) public SupportedToken(tokenAddress) {
        IERC20 token = IERC20(tokenAddress);
        require(amount > 0, 'Amount of tockens cant be empty');
        require(token.balanceOf(msg.sender) >= amount, "You dont have enough tokens");
      
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        
        emit DepositSuccess(msg.sender, amount, block.timestamp);
    }

    // Withdraw amount of ETH to contract
    function withdrawETH(uint amount) public payable {
        require(amount <= balanceETH[msg.sender], "The requested amount is greater than the current deposit");
        payable(msg.sender).transfer(amount); 
        balanceETH[msg.sender] -= amount;
        
        emit WithdrawSuccess(msg.sender, amount, balanceETH[msg.sender],block.timestamp );
    }

    function withdrawToken(address tokenAddress, uint amount) public SupportedToken(tokenAddress) {
        IERC20 token = IERC20(tokenAddress);
        require(amount <= balances[msg.sender], "The requested amount is greater than the current deposit");

        token.transfer(msg.sender, amount); 
        balances[msg.sender] -= amount;
        
        emit WithdrawSuccess(msg.sender, amount, balances[msg.sender],block.timestamp);
    }

    // Get contract Ether balans for account
    function getBalanceETH() public view returns(uint) {
        return balanceETH[msg.sender];
    }

    // Get token balans for account

     function getBalanceToken(address tokenAddress) public view SupportedToken(tokenAddress) returns(uint) {
        return balances[msg.sender];
    }
    
}