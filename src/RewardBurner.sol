// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

/// @title RewardBurner
/// @notice Exposes it's Prize Pool rewards as an ILiquidationSource
contract RewardBurner is ILiquidationSource {

    /// @notice The address to which tokens are sent to be burned
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice The prize pool from whom the rewards will be burned.
    PrizePool public immutable prizePool;

    /// @notice The address that deployed this contract
    address public immutable creator;    

    /// @notice The liquidation pair that is authorized to liquidate the rewards
    address public liquidationPair;
    
    /// @notice Constructs a new RewardBurner
    constructor(PrizePool _prizePool, address _creator) {
        prizePool = _prizePool;
        creator = _creator;
    }

    /// @notice Allows the creator to set the liquidation pair; can only be called if the pair has not been set.
    /// @param _liquidationPair The address of the liquidation pair
    function setLiquidationPair(address _liquidationPair) external {
        require(liquidationPair == address(0), "RewardBurner: Liquidation pair already set");
        require(msg.sender == creator, "RewardBurner: Only creator can set liquidation pair");
        liquidationPair = _liquidationPair;
        emit LiquidationPairSet(address(prizePool.prizeToken()), _liquidationPair);
    }

    /// @inheritdoc ILiquidationSource
    function liquidatableBalanceOf(address tokenOut) external returns (uint256) {
        if (tokenOut != address(prizePool.prizeToken())) {
            return 0;
        }
        return prizePool.rewardBalance(address(this));
    }

    /// @inheritdoc ILiquidationSource
    function transferTokensOut(
        address sender,
        address receiver,
        address tokenOut,
        uint256 amountOut
    ) external onlyLiquidationPair returns (bytes memory) {
        require(tokenOut == address(prizePool.prizeToken()), "RewardBurner: Invalid tokenOut");
        prizePool.withdrawRewards(receiver, amountOut);
    }

    /// @inheritdoc ILiquidationSource
    function verifyTokensIn(
        address tokenIn,
        uint256 amountIn,
        bytes calldata transferTokensOutData
    ) external {
    }

    /// @inheritdoc ILiquidationSource
    function targetOf(address tokenIn) external returns (address) {
        return DEAD_ADDRESS;
    }

    /// @inheritdoc ILiquidationSource
    function isLiquidationPair(address _tokenOut, address _liquidationPair) external returns (bool) {
        if (_tokenOut != address(prizePool.prizeToken())) {
            return false;
        }
        return liquidationPair == _liquidationPair;
    }

    /// @notice Modifier that only allows the liquidation pair to call the function
    modifier onlyLiquidationPair() {
        require(msg.sender == liquidationPair, "RewardBurner: Only liquidation pair");
        _;
    }
}
