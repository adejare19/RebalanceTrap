// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILiquidityPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getBalance(address user) external view returns (uint256);
}

contract RebalanceExecutor {
    ILiquidityPool public poolA;
    ILiquidityPool public poolB;
    address public owner;
    uint256 public feeBps = 200; // 2%

    event RebalanceExecuted(
        address indexed executor,
        uint256 amountMoved,
        string direction,
        uint256 timestamp
    );

    constructor(address _poolA, address _poolB) {
        poolA = ILiquidityPool(_poolA);
        poolB = ILiquidityPool(_poolB);
        owner = msg.sender;
    }

    /// @notice Drosera calls this when the trap signals rebalance
    function executeRebalance(string calldata reason) external {
        uint256 balanceA = poolA.getBalance(address(this));
        uint256 balanceB = poolB.getBalance(address(this));

        if (balanceA > balanceB) {
            uint256 delta = (balanceA - balanceB) / 2;
            poolA.withdraw(delta);
            poolB.deposit(delta);
            emit RebalanceExecuted(msg.sender, delta, "A->B", block.timestamp);
        } else {
            uint256 delta = (balanceB - balanceA) / 2;
            poolB.withdraw(delta);
            poolA.deposit(delta);
            emit RebalanceExecuted(msg.sender, delta, "B->A", block.timestamp);
        }
    }

    function updateFee(uint256 _bps) external {
        require(msg.sender == owner, "Not owner");
        feeBps = _bps;
    }
}
