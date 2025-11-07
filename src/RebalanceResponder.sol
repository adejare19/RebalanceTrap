// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces for the required external contracts
interface IRebalanceExecutor {
    function executeRebalance(string calldata reason) external;
}

interface IFeeSkimmer {
    // The skim function needs to be marked payable if it can receive ETH
    function skim(uint256 grossProfit) external payable returns (uint256 netAmount);
}

contract RebalanceResponder {
    address public immutable droseraRelay;
    IRebalanceExecutor public executor;
    IFeeSkimmer public feeSkimmer;

    event RebalanceAlert(
        address poolA, address poolB,
        uint256 priceA, uint256 priceB,
        uint256 deviationBps, uint256 blockNumber, address executor
    );
    
    // Note: You must pass the Drosera Relay address from drosera.toml
    constructor(
        address _droseraRelay,
        address _executor,
        address _feeSkimmer
    ) {
        droseraRelay = _droseraRelay;
        executor = IRebalanceExecutor(_executor);
        feeSkimmer = IFeeSkimmer(_feeSkimmer);
        require(_droseraRelay != address(0), "Invalid Relay");
    }

    modifier onlyRelay() {
        require(msg.sender == droseraRelay, "Unauthorized Relay");
        _;
    }

    /**
     * @notice Handler called by the Drosera operator when the trap triggers.
     * @dev This matches the 'response_function = "handle(bytes)"' in the TOML.
     * @param payload Encoded data from RebalanceTrapStateless.shouldRespond()
     */
    function handle(bytes calldata payload) external onlyRelay {
        // Decode the data returned by RebalanceTrapStateless.shouldRespond
        (
            address pA, address pB, 
            uint256 a, uint256 b, 
            uint256 devBps, uint256 blk
        ) = abi.decode(payload, (address,address,uint256,uint256,uint256,uint256));

        // 1. Emit Alert/Log
        emit RebalanceAlert(pA, pB, a, b, devBps, blk, msg.sender);
        
        // 2. Execute Rebalance Logic
        executor.executeRebalance("Price deviation detected");

        // Skimming logic (optional, keep commented out unless you want to use it)
        /*
        uint256 currentBalance = address(this).balance;
        if (currentBalance > 0) {
            feeSkimmer.skim{value: currentBalance}(currentBalance);
        }
        */
    }
}
