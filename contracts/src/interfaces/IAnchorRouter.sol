// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IAnchorRouter {
  function depositStable(uint256 _amount) external;
  function redeemStable(uint256 _amount) external;
}