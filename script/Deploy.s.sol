// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "../src/RebalanceExecutor.sol";
import "../src/FeeSkimmer.sol";

// interface ILiquidityPool {  <-- REMOVE THIS BLOCK
//     // Include the functions the Executor calls (e.g., getPrice, swap, etc.)
// }

contract Deploy is Script {
    // 🛑 REPLACE THESE WITH YOUR ACTUAL DEPLOYED ADDRESSES 🛑
    address constant EXISTING_POOL_A = 0x6175ce079012D411047325C48f93B90A2c74bD4B; 
    address constant EXISTING_POOL_B = 0x5ff177029f10Bb17363B9aa19F5A5002AFc1CE75; 

    function run() external {
        vm.startBroadcast();

        // 1️⃣ Use EXISTING Mock Pool Addresses
        address poolA = EXISTING_POOL_A;
        address poolB = EXISTING_POOL_B;

        // 2️⃣ Deploy FeeSkimmer
        // Treasury is set to the deployer (msg.sender)
        FeeSkimmer skimmer = new FeeSkimmer(payable(msg.sender));

        // 3️⃣ Deploy Executor
        RebalanceExecutor executor = new RebalanceExecutor(poolA, poolB);

        // 4️⃣ Log addresses
        console.log("Existing Pool A:", poolA);
        console.log("Existing Pool B:", poolB);
        console.log("FeeSkimmer:", address(skimmer));
        console.log("RebalanceExecutor:", address(executor));

        vm.stopBroadcast();
    }
}
