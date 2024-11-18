// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is AccessControl {
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    uint256 public invariant;
    address public tokenA;
    address public tokenB;
    uint256 feebps = 3;

    event Swap(address indexed _inToken, address indexed _outToken, uint256 inAmt, uint256 outAmt);
    event LiquidityProvision(address indexed _from, uint256 AQty, uint256 BQty);
    event Withdrawal(address indexed _from, address indexed recipient, uint256 AQty, uint256 BQty);

    constructor(address _tokenA, address _tokenB) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LP_ROLE, msg.sender);

        require(_tokenA != address(0), 'Token address cannot be 0');
        require(_tokenB != address(0), 'Token address cannot be 0');
        require(_tokenA != _tokenB, 'Tokens cannot be the same');
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getTokenAddress(uint256 index) public view returns(address) {
        require(index < 2, 'Only two tokens');
        return index == 0 ? tokenA : tokenB;
    }

    function tradeTokens(address sellToken, uint256 sellAmount) public {
        require(invariant > 0, 'No liquidity');
        require(sellToken == tokenA || sellToken == tokenB, 'Invalid token');
        require(sellAmount > 0, 'Cannot trade 0');

        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));
        
        // Apply fee reduction to input amount
        uint256 actualInput = (sellAmount * (10000 - feebps)) / 10000;
        
        address outToken;
        uint256 outputAmount;
        
        if (sellToken == tokenA) {
            outToken = tokenB;
            outputAmount = (balanceB * actualInput) / (balanceA + actualInput);
            require(ERC20(tokenA).transferFrom(msg.sender, address(this), sellAmount), "Transfer failed");
            require(ERC20(tokenB).transfer(msg.sender, outputAmount), "Transfer failed");
        } else {
            outToken = tokenA;
            outputAmount = (balanceA * actualInput) / (balanceB + actualInput);
            require(ERC20(tokenB).transferFrom(msg.sender, address(this), sellAmount), "Transfer failed");
            require(ERC20(tokenA).transfer(msg.sender, outputAmount), "Tran
