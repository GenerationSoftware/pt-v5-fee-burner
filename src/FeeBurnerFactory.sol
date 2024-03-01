// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

import { FeeBurner } from "./FeeBurner.sol";

/**
 * @title  PoolTogether V5 Prize Vault Factory
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice Factory contract for deploying new prize vaults using a standard underlying ERC4626 yield vault.
 */
contract FeeBurnerFactory {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a new FeeBurner has been deployed by this factory.
     * @param feeBurner The Fee Burner that was created
     * @param prizePool The prize pool the vault contributes to
     */
    event NewFeeBurner(
        FeeBurner indexed feeBurner,
        PrizePool indexed prizePool
    );

    /* ============ Variables ============ */

    /// @notice List of all vaults deployed by this factory.
    FeeBurner[] public allFeeBurners;

    /// @notice Mapping to verify if a Vault has been deployed via this factory.
    mapping(address vault => bool deployedByFactory) public deployedFeeBurners;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    /* ============ External Functions ============ */

    /**
     * @notice Deploy a new Fee Burner
     * @return FeeBurner The newly deployed FeeBurner
     */
    function deployFeeBurner(
        PrizePool _prizePool,
        address _burnToken,
        address _creator
    ) external returns (FeeBurner) {
        FeeBurner _feeBurner = new FeeBurner{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _prizePool,
            _burnToken,
            _creator
        );

        allFeeBurners.push(_feeBurner);
        deployedFeeBurners[address(_feeBurner)] = true;

        emit NewFeeBurner(
            _feeBurner,
            _prizePool
        );

        return _feeBurner;
    }

    function computeDeploymentAddress(
        PrizePool _prizePool,
        address _burnToken,
        address _creator
    ) external view returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            keccak256(abi.encode(msg.sender, deployerNonces[msg.sender])),
            keccak256(abi.encodePacked(
                type(FeeBurner).creationCode,
                abi.encode(_prizePool, _burnToken, _creator)
            ))
        )))));
    }

    /**
     * @notice Total number of vaults deployed by this factory.
     * @return uint256 Number of vaults deployed by this factory.
     */
    function totalVaults() external view returns (uint256) {
        return allFeeBurners.length;
    }
}
