// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import "../src/Commit.sol";

contract TestCommit is Test {
    IChronicle chronicle = IChronicle(0xea347Db6ef446e03745c441c17018eF3d641Bc8f);
    ISelfKisser selfKiss = ISelfKisser(0x70E58b7A1c884fFFE7dbce5249337603a28b8422);

    address user = 0x8558FE88F8439dDcd7453ccAd6671Dfd90657a32;

    Commit commit;

    function setUp() public {
        vm.createSelectFork("https://mainnet.base.org");

        commit = new Commit(chronicle, selfKiss);
    }

    function testStakeETH() internal {
        commit.createEvent(50_000_000_000_000_000);

        vm.deal(user, 10 ether);

        // (uint256 value,) = commit.getETHPrice(50_000_000_000_000_000_000);

        vm.prank(user);

        commit.stake{ value: 50_000_000_000_000_000 }(0);
    }

    function testSlash() public {
        testStakeETH();

        commit.slashUser(user, 0);
    }

    function testWithdraw() public {
        testStakeETH();

        vm.prank(user);
        commit.unstake(0);
    }
}
