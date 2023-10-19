// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IFundraisingPoolFactory {
    //** events */

    event FundraisingPoolCreated(address indexed owner, address indexed tokenContract, uint256 indexed eventId); //emitted when funding pool is deployed

    //** view functions */

    //** normal functions */

    function createPool(address _fundAsset, uint256 _startTimestamp, uint256 _endTimestamp, uint256 _targetAmount)
        external
        returns (address _poolAddress, uint256 _poolId);
}
