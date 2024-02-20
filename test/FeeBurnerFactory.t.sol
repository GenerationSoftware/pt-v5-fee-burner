// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { FeeBurner } from "../src/FeeBurner.sol";
import { FeeBurnerFactory } from "../src/FeeBurnerFactory.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract FeeBurnerTest is Test {

    FeeBurnerFactory factory;

    PrizePool prizePool = PrizePool(makeAddr("prizePool"));
    address burnToken = makeAddr("burnToken");
    address prizeToken = makeAddr("prizeToken");
    address liquidationPair = makeAddr("liquidationPair");

    function setUp() public {
        factory = new FeeBurnerFactory();
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.prizeToken.selector), abi.encode(prizeToken));
    }

    /// @dev Simple test. Run Forge with `-vvvv` to see stack traces.
    function test() external {
        address expectedAddress = factory.computeDeploymentAddress(prizePool, burnToken, liquidationPair);
        FeeBurner burner = factory.deployFeeBurner(
            prizePool,
            burnToken,
            liquidationPair
        );
        assertEq(address(burner), expectedAddress, "address was computed correctly");
        assertEq(burner.burnToken(), burnToken, "burn token");
        assertEq(address(burner.prizePool()), address(prizePool), "prize pool");
        assertEq(burner.liquidationPair(), liquidationPair, "liquidation pair");
    }
}
