// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

import { RewardBurner } from "./RewardBurner.sol";

/**
 * @title  PoolTogether V5 Prize Vault Factory
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice Factory contract for deploying new prize vaults using a standard underlying ERC4626 yield vault.
 */
contract RewardBurnerFactory {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a new RewardBurner has been deployed by this factory.
     * @param feeBurner The Fee Burner that was created
     * @param prizePool The prize pool the vault contributes to
     */
    event NewRewardBurner(
        RewardBurner indexed feeBurner,
        PrizePool indexed prizePool
    );

    /* ============ Variables ============ */

    /// @notice List of all vaults deployed by this factory.
    RewardBurner[] public allRewardBurners;

    /// @notice Mapping to verify if a Vault has been deployed via this factory.
    mapping(address vault => bool deployedByFactory) public deployedRewardBurners;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    /* ============ External Functions ============ */

    /**
     * @notice Deploy a new Fee Burner
     * @return RewardBurner The newly deployed RewardBurner
     */
    function deployRewardBurner(
        PrizePool _prizePool,
        address _creator
    ) external returns (RewardBurner) {
        RewardBurner _feeBurner = new RewardBurner{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _prizePool,
            _creator
        );

        allRewardBurners.push(_feeBurner);
        deployedRewardBurners[address(_feeBurner)] = true;

        emit NewRewardBurner(
            _feeBurner,
            _prizePool
        );

        return _feeBurner;
    }

    /// @notice Computes the deployment address for a new Reward Burner contract
    /// @param _prizePool The prize pool that the rewards are coming from
    /// @param _creator The address that will be the creator of the vault
    function computeDeploymentAddress(
        PrizePool _prizePool,
        address _creator
    ) external view returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            keccak256(abi.encode(msg.sender, deployerNonces[msg.sender])),
            keccak256(abi.encodePacked(
                type(RewardBurner).creationCode,
                abi.encode(_prizePool, _creator)
            ))
        )))));
    }

    /**
     * @notice Total number of vaults deployed by this factory.
     * @return uint256 Number of vaults deployed by this factory.
     */
    function totalVaults() external view returns (uint256) {
        return allRewardBurners.length;
    }
}
