// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the required ITrap interface
interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

// Interface for the Mock Pools
interface IUniswapPoolLike {
    function getPrice() external view returns (uint256);
}

/**
 * @title RebalanceTrap
 * @notice Drosera-compatible trap that monitors two pools and triggers rebalancing
 * when price deviation exceeds a threshold.
 * @dev This contract is stateless and encodes all necessary data into the collect payload.
 */
contract RebalanceTrap is ITrap { 
       
    address constant POOL_A = 0x6175ce079012D411047325C48f93B90A2c74bD4B; 
    address constant POOL_B = 0x5ff177029f10Bb17363B9aa19F5A5002AFc1CE75; 
    
    uint256 constant THRESH_BPS = 200;      // 2% in bps
    uint256 constant MIN_PRICE = 1;         // Safety check

    // ------------------------------------------------------------------
    // Internal Helper: Safely call getPrice()
    // ------------------------------------------------------------------
    function _safePrice(address pool) private view returns (uint256) {
        // Use staticcall to read data without side effects
        (bool ok, bytes memory ret) = pool.staticcall(abi.encodeWithSelector(IUniswapPoolLike.getPrice.selector));
        if (!ok || ret.length < 32) return 0;
        return abi.decode(ret, (uint256));
    }
    
    // ------------------------------------------------------------------
    // 1. collect() - VIEW (Fetches ON-CHAIN data)
    // ------------------------------------------------------------------
    function collect() external view override returns (bytes memory) {
        uint256 a = _safePrice(POOL_A);
        uint256 b = _safePrice(POOL_B);
        
        // Safety: If prices are bad, return empty bytes to halt planning
        if (a < MIN_PRICE || b < MIN_PRICE) {
            return bytes("");
        }

        // Encode config (addresses, threshold) and the data (prices, block number)
        // This ensures shouldRespond() remains PURE.
        return abi.encode(POOL_A, POOL_B, THRESH_BPS, a, b, block.number);
    }

    // ------------------------------------------------------------------
    // 2. shouldRespond() - PURE (Processes provided data)
    // ------------------------------------------------------------------
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        // Decode the data collected by the last collect() call
        (address pA, address pB, uint256 threshBps, uint256 a, uint256 b, uint256 blk)
            = abi.decode(data[0], (address,address,uint256,uint256,uint256,uint256));

        if (a == 0 || b == 0) return (false, bytes(""));

        // Calculate deviation symmetrically
        uint256 base = a < b ? a : b; 
        uint256 diff = a > b ? (a - b) : (b - a);
        uint256 devBps = (diff * 10_000) / base;

        if (devBps >= threshBps) {
            // Return TRUE and a payload for the external responder
            return (true, abi.encode(pA, pB, a, b, devBps, blk));
        }
        return (false, bytes(""));
    }
}
