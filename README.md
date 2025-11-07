
#  Rebalance Trap

## Overview

This trap is designed to monitor and respond to significant shifts in the balance of a specific Automated Market Maker (AMM) **Liquidity Pool** (e.g., a Uniswap V3 Pool). It serves as a detection mechanism for a pool becoming critically imbalanced or suffering from large price divergence, which is the precursor for a profitable (and necessary) rebalance operation.

-----

## What It Does

  * Monitors the liquidity and price ratio of a designated **TARGET pool** at the end of each sampling epoch.
  * Triggers if the current pool state (e.g., token ratio, utilization, or effective price) moves outside of a pre-defined range or **THRESHOLD**.
  * It demonstrates the essential Drosera trap pattern using deterministic off-chain logic to analyze complex on-chain state data.

-----

## Key Files

  * **`src/RebalanceTrap.sol`** – The core trap contract containing the monitoring logic.
  * **`src/RebalanceResponder.sol`** – The required external response contract that executes the complex rebalance action (e.g., swapping tokens to restore balance).
  * **`drosera.toml`** – The deployment, configuration, and operator-specific settings file.

-----

## Detection Logic

The trap uses Drosera's deterministic planning model to detect imbalance in the pool state. It collects the current state (PoolState) and then reduces the data to a single value, comparing the state to a fixed threshold.

During each planning epoch, the logic performs the following steps:

### `collect()`

1.  Fetches the complex state variables from the **TARGET Pool** contract (e.g., `token0/token1 reserves`, `current tick`, or `liquidity`).
2.  Calculates a simple metric (e.g., a deviation percentage or a critical tick distance) from the raw data.
3.  Encodes the collected data as a tuple: `(uint256 currentDeviationMetric, uint256 currentBlockNumber)`.

### `shouldRespond()`

1.  Safely guards against empty or incomplete data during the planning process.
2.  Decodes the newest sample as a single metric: `(currMetric, currBlk)`.
3.  Compares the `currMetric` against the pre-defined **THRESHOLD**.
4.  Returns `(true, abi.encode(currMetric))` if the current state exceeds the configurable **THRESHOLD** (e.g., a deviation greater than 5%).

-----

## ⚙️ Solidity Implementation (Key Logic)

The trap logic simplifies the complex pool state into a single, easy-to-check metric.

```solidity
function shouldRespond(bytes[] calldata data)
    external
    pure
    override
    returns (bool, bytes memory)
{
    // Safety guards...
    // Decodes the current metric (uint256) and block number
    (uint256 currMetric, ) = abi.decode(data[0], (uint256, uint256));
    
    // THRESHOLD is a constant representing max allowed deviation (e.g., 500 = 5%)
    if (currMetric > THRESHOLD) {
        // Return true and the deviation metric for the responder to use
        return (true, abi.encode(currMetric)); 
    }

    return (false, abi.encode(uint256(0)));
}
```

-----

## Implementation Details and Key Concepts

  * **Monitoring Metric:** Watching the calculated deviation of the pool's price/reserves from an acceptable target.
  * **Resilience:** The trap logic only relies on the instantaneous pool state, ensuring determinism across all operators at the same block height.
  * **Threshold:** The `THRESHOLD` constant defines the maximum allowable deviation before a rebalance is considered profitable or necessary.
  * **Response Mechanism:** On trigger, the trap returns the **current deviation metric**, which the external `RebalanceResponder` contract consumes via the expected `handle(bytes)` function to calculate and execute the optimal rebalancing trade.

-----

## Test It

To verify the trap logic using Foundry, run the following command (assuming a test file has been created, e.g., `test/RebalanceTrap.t.sol`):

```bash
forge test --match-contract RebalanceTrap
```# RebalanceTrap
