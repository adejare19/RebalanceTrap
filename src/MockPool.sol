// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MockPool
/// @notice Minimal simulation of a liquidity pool for testing RebalanceTrap and RebalanceExecutor.
contract MockPool {
    uint256 public price;
    uint256 public reserves;
    address public owner;

    event PriceUpdated(uint256 newPrice);
    event ReservesAdjusted(uint256 newReserves);

    constructor(uint256 _initialPrice) {
        price = _initialPrice;
        reserves = 1000 ether; // mock reserve value
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Simulate a price change (manually controlled)
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    /// @notice Return the current pool price
    function getPrice() external view returns (uint256) {
        return price;
    }

    /// @notice Adjust pool reserves (mock rebalance behavior)
    function adjustReserves(int256 delta) external onlyOwner {
        if (delta > 0) {
            reserves += uint256(delta);
        } else {
            reserves -= uint256(-delta);
        }
        emit ReservesAdjusted(reserves);
    }
}
