// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IFundingPool {
    //** events */
    event Deposit(address indexed _user, uint256 _amount);

    event Withdraw(address indexed _admin, uint256 _amount);

    event Redeem(address indexed _user, uint256 _amount);

    event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);

    event FundAssetChanged(address indexed _oldFundAsset, address indexed _newFundAsset);

    event StartTimestampChanged(uint256 indexed _oldStartTimestamp, uint256 indexed _newStartTimestamp);

    event EndTimestampChanged(uint256 indexed _oldEndTimestamp, uint256 indexed _newEndTimestamp);

    event TargetAmountChanged(uint256 indexed _oldTargetAmount, uint256 indexed _newTargetAmount);

    //** view functions */
    function isPoolOpen() external view returns (bool _isOpen);

    //** normal functions */
    function deposit(uint256 _amount) external;

    function withdraw() external;

    function redeem() external;

    function setAdmin(address _admin) external;

    function setFundAsset(address _fundAsset) external;

    function setStartTimestamp(uint256 _startTimestamp) external;

    function setEndTimestamp(uint256 _endTimestamp) external;

    function setTargetAmount(uint256 _targetAmount) external;
}
