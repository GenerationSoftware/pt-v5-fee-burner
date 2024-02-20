// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

contract FeeBurner is ILiquidationSource {

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    PrizePool public immutable prizePool;
    address public immutable burnToken;
    address public immutable creator;    
    address public liquidationPair;
    
    constructor(PrizePool _prizePool, address _burnToken, address _creator) {
        prizePool = _prizePool;
        burnToken = _burnToken;
        creator = _creator;
    }

    function setLiquidationPair(address _liquidationPair) external {
        require(liquidationPair == address(0), "FeeBurner: Liquidation pair already set");
        require(msg.sender == creator, "FeeBurner: Only creator can set liquidation pair");
        liquidationPair = _liquidationPair;
        emit LiquidationPairSet(address(prizePool.prizeToken()), _liquidationPair);
    }

    function liquidatableBalanceOf(address tokenOut) external returns (uint256) {
        if (tokenOut != address(prizePool.prizeToken())) {
            return 0;
        }
        return prizePool.rewardBalance(address(this));
    }

    function transferTokensOut(
        address sender,
        address receiver,
        address tokenOut,
        uint256 amountOut
    ) external onlyLiquidationPair returns (bytes memory) {
        require(tokenOut == address(prizePool.prizeToken()), "FeeBurner: Invalid tokenOut");
        prizePool.withdrawRewards(receiver, amountOut);
    }

    function verifyTokensIn(
        address tokenIn,
        uint256 amountIn,
        bytes calldata transferTokensOutData
    ) external {
        require(tokenIn == burnToken, "FeeBurner: Invalid tokenIn");
    }

    function targetOf(address tokenIn) external returns (address) {
        return DEAD_ADDRESS;
    }

    function isLiquidationPair(address _tokenOut, address _liquidationPair) external returns (bool) {
        if (_tokenOut != address(prizePool.prizeToken())) {
            return false;
        }
        return liquidationPair == _liquidationPair;
    }

    modifier onlyLiquidationPair() {
        require(msg.sender == liquidationPair, "FeeBurner: Only liquidation pair");
        _;
    }
}