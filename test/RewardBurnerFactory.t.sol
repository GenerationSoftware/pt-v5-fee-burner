// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "forge-std/Test.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { RewardBurner } from "../src/RewardBurner.sol";
import { RewardBurnerFactory } from "../src/RewardBurnerFactory.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract RewardBurnerTest is Test {

    RewardBurnerFactory factory;

    PrizePool prizePool = PrizePool(makeAddr("prizePool"));
    address prizeToken = makeAddr("prizeToken");
    address liquidationPair = makeAddr("liquidationPair");

    function setUp() public {
        factory = new RewardBurnerFactory();
        vm.mockCall(address(prizePool), abi.encodeWithSelector(prizePool.prizeToken.selector), abi.encode(prizeToken));
    }

    /// @dev Simple test. Run Forge with `-vvvv` to see stack traces.
    function test() external {
        address expectedAddress = factory.computeDeploymentAddress(prizePool, address(this));
        RewardBurner burner = factory.deployRewardBurner(
            prizePool,
            address(this)
        );
        assertEq(address(burner), expectedAddress, "address was computed correctly");
        assertEq(address(burner.prizePool()), address(prizePool), "prize pool");
        assertEq(burner.creator(), address(this), "creator");
        assertEq(burner.liquidationPair(), address(0), "liquidation pair");
    }
}
