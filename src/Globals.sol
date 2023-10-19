// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {IGlobals} from "./interfaces/IGlobals.sol";

contract Globals is IGlobals, Initializable, UUPSUpgradeable {
    //** Modifier */
    modifier onlyGovernor() {
        require(msg.sender == governor, "Globals: only governor");
        _;
    }

    //** Storage */
    address public override governor;
    mapping(address => bool) public isEventHolders;
    uint256 public override createEventFee = 0 ether;

    //** UUPS functions */
    function initialize(address _governor) public initializer {
        require(_governor != address(0), "Globals: _governor is zero address");
        governor = _governor;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernor {}

    //** allow list function */
    function setValidEventHolder(address _eventHolder, bool _isValid) external override onlyGovernor {
        require(_eventHolder != address(0), "Globals: _eventHolder is zero address");
        isEventHolders[_eventHolder] = _isValid;
        emit ValidEventHolderSet(_eventHolder, _isValid);
    }

    //** Setter Functions */
    function setCreateEventFee(uint256 _fee) external override onlyGovernor {
        createEventFee = _fee;
        emit CreateEventFeeSet(_fee);
    }

    //** Governor Transfer Functions */
    function transferGovernor(address _newGovernor) external override onlyGovernor {
        require(_newGovernor != address(0), "Globals: _newGovernor is zero address");
        emit GovernorTransferred(governor, _newGovernor);
        governor = _newGovernor;
    }

    //** view function */
    function isValidEventHolder(address _eventHolder) external view override returns (bool) {
        return isEventHolders[_eventHolder];
    }
}
