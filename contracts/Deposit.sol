// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20/extensions/IERC20Metadata.sol";

contract Deposit {
    
    address public manager;
    IERC20Metadata private _token;
    
    mapping(address => mapping(string => uint)) public balances;   
    mapping(string => IERC20Metadata) public tokensSupported;

    constructor (){
       manager = msg.sender; 
    }

    modifier OnlyManager() {
     require(msg.sender == manager, "Only manager can run this function");
         _;
    }

    modifier SupportedToken(string memory symbol) {
        require(tokensSupported[symbol].totalSupply() > 0,'Token not supported');
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


    // Deposit amount of ETH to contract
    function deposit() public payable {
        require(msg.value > 0, "The value can`t be empty");
        balances[payable(msg.sender)]["ETH"] += msg.value;
        emit DepositSuccess(msg.sender, msg.value, block.timestamp);
    }

    // Deposit supported token
    function depositTocken(string calldata tokenSymbol, uint amount) public SupportedToken(tokenSymbol) {
        
        IERC20Metadata token = tokensSupported[tokenSymbol];
        
        require(amount > 0, 'Amount of tockens cant be empty');
        require(token.balanceOf(msg.sender) >= amount, "You dont have enough tokens");

        token.allowance(msg.sender, address(this));
        token.transferFrom(msg.sender, address(this), amount);
        
        balances[msg.sender][tokenSymbol] += amount;
        
        emit DepositSuccess(msg.sender, amount, block.timestamp);
    }

    // Withdraw amount of ETH to contract
    function withdraw(uint amount) public payable {
        
        require(amount <= balances[msg.sender]["ETH"], "The requested amount is greater than the current deposit");
        payable(msg.sender).transfer(amount);
        balances[msg.sender]["ETH"] -= amount;
        
        emit WithdrawSuccess(msg.sender, amount, balances[msg.sender]["ETH"],block.timestamp );
    }

    // Get contract Ether balans for account
    function getBalance() public view returns(uint) {
        return balances[msg.sender]["ETH"];
    }
    
    // Get account tocken balance 
    function getAccountTockenBalance(string calldata tokenSymbol) public view returns(uint)  {
        return tokensSupported[tokenSymbol].balanceOf(msg.sender);
    }
    
    // Get contract supported token balans for account
    function getTockenBalance(string calldata tokenSymbol) public view returns(uint) {
        return balances[msg.sender][tokenSymbol];
    }
    

    // add Support for token 
    function supportTocken(address  tokenAddress) public OnlyManager{
        _token = IERC20Metadata(tokenAddress);
        tokensSupported[_token.symbol()] = _token;
    }

}