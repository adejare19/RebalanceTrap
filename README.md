# **RebalanceTrap**

## **Overview**

The **RebalanceTrap** is a Drosera-compatible monitoring contract that tracks **price deviation between two liquidity pools** (e.g., Uniswap-style Pool A vs. Pool B) and automatically determines when the deviation exceeds a configurable threshold.

Once deployed inside the Drosera network, the trap enables fully automated **liquidity imbalance detection**, serving as the basis for advanced DeFi automation strategies such as:

* liquidity syncing between DEXes
* cross-pool arbitrage monitoring
* yield-optimizing vault execution
* multi-DEX rebalancing strategies

This repository contains the full smart-contract suite, executor, fee routing module, and mock pools for testing.

---

## **What It Does**

✅ Reads price data from **two independent pools**
✅ Computes the **delta** and deviation in **basis points (bps)**
✅ Detects when the **spread exceeds a configurable threshold (default: 2%)**
✅ Emits `RebalanceTriggered()` when a deviation is detected
✅ Supports simulated profit routing through `FeeSkimmer`

The trap follows Drosera’s deterministic execution model:

* **collect()** → gather data
* **shouldRespond()** → evaluate conditions
* **respond()** → execute action

---

## **Key Files**

| File                        | Description                                                |
| --------------------------- | ---------------------------------------------------------- |
| `src/RebalanceTrap.sol`     | Core trap containing deviation-detection logic             |
| `src/RebalanceExecutor.sol` | Optional mock contract that simulates a rebalance action   |
| `src/MockPool.sol`          | Simulated AMM pools for testing prices and reserve changes |
| `src/FeeSkimmer.sol`        | Handles performance + execution fee logic                  |
| `drosera.toml`              | Configuration used for running the trap on Drosera         |

---

## **Detection Logic**

The trap follows Drosera’s two-phase sampling cycle:

### **1. collect()**

During sampling, the trap:

* reads `getPrice()` from both pools
* returns the data encoded as:

```
(priceA, priceB)
```

Example:

```
(1000, 950)
```

---

### **2. shouldRespond()**

Drosera passes the collected samples into:

```solidity
function shouldRespond(bytes[] calldata data)
```

The trap then:

1. Decodes the latest price pair.
2. Computes:

```solidity
delta = priceA – priceB
absDelta = |delta|
deviationBps = absDelta * 1e4 / priceB
```

3. If `deviationBps > threshold`, it returns:

```solidity
(true, "Rebalance needed")
```

Otherwise:

```solidity
(false, "")
```

This design ensures the trap remains:

✅ deterministic
✅ safe for planning
✅ free of side-effects

---

## ⚙️ **Solidity Logic (Key View Only)**

```solidity
function shouldRespond(bytes[] calldata data)
    external
    pure
    override
    returns (bool, bytes memory)
{
    (uint256 priceA, uint256 priceB) = abi.decode(data[0], (uint256, uint256));

    int256 delta = int256(priceA) - int256(priceB);
    uint256 deviationBps =
        uint256(delta > 0 ? delta : -delta) * 1e4 / priceB;

    if (deviationBps > 200) {
        return (true, abi.encode("Rebalance needed"));
    }

    return (false, "");
}
```

---

## **Execution Logic (respond())**

When Drosera decides the trap must execute, it calls:

```solidity
respond()
```

The trap performs:

1. Fetch updated pool prices
2. Update internal state
3. Emit `RebalanceTriggered()`
4. Forward simulated profit to `FeeSkimmer`

```solidity
uint256 simulatedProfit = address(this).balance;
if (simulatedProfit > 0) {
    skimmer.skim(simulatedProfit);
}
```

This design can be upgraded to handle **real vault yield** in later versions.

---

## **Implementation Details and Key Concepts**

### ✅ Monitoring Metric

Cross-pool **price deviation** in basis points.

### ✅ Simple & Robust Data Model

Uses only two values: `(priceA, priceB)` — no AMM math required.

### ✅ Threshold

Default:

```
threshold = 200 bps  // 2%
```

### ✅ Event Surface

The frontend can index:

```
RebalanceTriggered(uint256 blockNumber, int256 delta, address executor)
```

Useful for:

* deviation graphs
* APY projections
* historical automation logs

### ✅ Fee Model

`FeeSkimmer` supports:

* performance fee
* execution fee
* configurable treasury routing

Fully extendable to integrate `DRO` token after TGE.

---

## ✅ **How to Test It**

### Using Foundry

```
forge test --match-contract RebalanceTrap
```

### Manually simulate price changes

```
cast send <poolAddress> "setPrice(uint256)" 870 --rpc-url <rpc>
```

Test deviation manually:

```
cast call <trapAddress> "collect()" [...]
cast call <trapAddress> "shouldRespond(bytes[])" [...]
```

---

## ✅ **Deployment Notes**

Your deploy script will output:

* Pool A
* Pool B
* FeeSkimmer
* RebalanceTrap
* RebalanceExecutor

These values are referenced in:

```
drosera.toml
```

ou want a cleaner GitHub aesthetic (badges, architecture diagram, code snippets, cover image), I can format it.
