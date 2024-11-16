// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/Commit.sol";
import { Script } from "forge-std/src/Script.sol";

contract Deploy is Script {
    Commit commit;

    IChronicle chronicle = IChronicle(address(0));
    ISelfKisser selfKiss = ISelfKisser(address(0));

    function run() external {
        vm.startBroadcast();

        commit = new Commit(chronicle, selfKiss);

        vm.stopBroadcast();
    }
}
