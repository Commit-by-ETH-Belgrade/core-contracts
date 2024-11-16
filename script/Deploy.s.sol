// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/Commit.sol";
import { Script } from "forge-std/src/Script.sol";

contract Deploy is Script {
    Commit commit;

    function run() external {
        vm.startBroadcast();

        commit = new Commit();

        vm.stopBroadcast();
    }
}