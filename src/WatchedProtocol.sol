// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WatchedProtocol {
    mapping(address => uint256) public balances;
    uint256 public totalVolume;

    event Swap(
        address indexed from,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);

    function swap(address to, uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "WatchedProtocol: zero amount");
        require(to != address(0), "WatchedProtocol: zero address");

        amountOut = (amountIn * 997) / 1000;
        totalVolume += amountIn;
        balances[msg.sender] -= amountIn;
        balances[to] += amountOut;

        emit Swap(msg.sender, to, amountIn, amountOut, block.timestamp);
        return amountOut;
    }

    function addLiquidity() external payable {
        balances[msg.sender] += msg.value;
        emit LiquidityAdded(msg.sender, msg.value);
    }

    function removeLiquidity(uint256 amount) external {
        require(balances[msg.sender] >= amount, "WatchedProtocol: insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit LiquidityRemoved(msg.sender, amount);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}
