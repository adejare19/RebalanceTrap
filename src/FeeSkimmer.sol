// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FeeSkimmer
 * @notice Handles ETH-based performance and execution fees for RebalanceTrap.
 *         Later, this contract can be upgraded to handle the $DRO token once deployed.
 *         ✅ Works on Hoodi ETH mainnet/testnet without needing WETH.
 */
contract FeeSkimmer {
    address public owner;
    address public treasury;           // Where collected fees are sent

    uint256 public performanceFeeBps;  // 200 = 2%
    uint256 public executionFeeBps;    // 10 = 0.1%

    event FeesSkimmed(
        uint256 performanceFee,
        uint256 executionFee,
        address indexed executor
    );

    event TreasuryUpdated(address indexed treasury);
    event FeesUpdated(uint256 performanceFeeBps, uint256 executionFeeBps);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _treasury) {
        owner = msg.sender;
        treasury = _treasury;
        performanceFeeBps = 200; // default 2%
        executionFeeBps = 10;    // default 0.1%
    }

    /**
     * @notice Called by the trap after profit realization in ETH
     * @param grossProfit Total profit (in wei) generated from rebalancing
     */
    function skim(uint256 grossProfit) external payable returns (uint256 netAmount) {
        require(msg.value == grossProfit, "Incorrect ETH amount");

        uint256 perfFee = (grossProfit * performanceFeeBps) / 10_000;
        uint256 execFee = (grossProfit * executionFeeBps) / 10_000;
        uint256 totalFee = perfFee + execFee;
        netAmount = grossProfit - totalFee;

        // Transfer the fees to the treasury
        (bool sent, ) = payable(treasury).call{value: totalFee}("");
        require(sent, "Fee transfer failed");

        emit FeesSkimmed(perfFee, execFee, msg.sender);
    }

    /**
     * @notice Update fee rates (max 10% performance, 1% execution)
     */
    function setFees(uint256 _perf, uint256 _exec) external onlyOwner {
        require(_perf <= 1000 && _exec <= 100, "Fee too high");
        performanceFeeBps = _perf;
        executionFeeBps = _exec;
        emit FeesUpdated(_perf, _exec);
    }

    /**
     * @notice Update treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @notice Withdraw any ETH accidentally stuck in the contract
     */
    function rescueETH() external onlyOwner {
        uint256 bal = address(this).balance;
        (bool sent, ) = payable(owner).call{value: bal}("");
        require(sent, "Rescue failed");
    }

    // ---------------------------------------------------------------
    // ⚠️ FUTURE UPGRADE: Once $DRO token is deployed
    // Replace ETH logic with ERC20 transfer functions:
    //
    // IERC20 public dro; // <-- declare DRO token
    // dro.transferFrom(msg.sender, treasury, totalFee);
    //
    // or add dual-mode (ETH + DRO) fee handling.
    // ---------------------------------------------------------------
}
