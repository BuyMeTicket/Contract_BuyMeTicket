// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ITicketFactoryEvent} from "./ITicketFactoryEvent.sol";

interface ITicketFactory is ITicketFactoryEvent {
    //** view function */

    function getAllEventAddr() external view returns (address[] memory);

    function getTicketBalanceOfById(address _account, uint256 _eventId, uint256 _tokenId)
        external
        view
        returns (uint256 _amount);

    function getTicketBalanceOfByName(address _account, uint256 _eventId, string calldata _name)
        external
        view
        returns (uint256 _amount);

    function getTicektInfoById(uint256 _eventId, uint256 _tokenId)
        external
        view
        returns (address _contract, address _evnetHolder, string memory _uri, uint256 supply);

    function governor() external view returns (address);

    //** normal function */

    function setGlobals(address _globals) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function createEvent(
        address _asset,
        string memory _contractName,
        string memory _baseURI,
        uint256 _maxPerWallet,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] memory _mintPrices,
        uint256[] memory _maxSupplys,
        string[] memory _names,
        uint256[] memory _ids
    ) external returns (address _eventAddress, uint256 _eventId);

    function mintEventTicket(uint256 _eventId, string memory _name, uint256 _amount) external;

    function mintEventTicket(uint256 _eventId, uint256 _tokenId, uint256 _amount) external;

    function mintBatchEventTicket(uint256 _eventId, string[] memory _names, uint256[] memory _amounts) external;

    function mintBatchEventTicket(uint256 _eventId, uint256[] memory _tokenIds, uint256[] memory _amounts) external;

    function refundEventTicket(uint256 _eventId, string memory _name, uint256 _amount)
        external
        returns (uint256 refundAmount);

    function refundEventTicket(uint256 _eventId, uint256 _id, uint256 _amount)
        external
        returns (uint256 refundAmount);

    function refundBatchEventTicket(uint256 _eventId, string[] memory _names, uint256[] memory _amounts)
        external
        returns (uint256 refundAmount);

    function refundBatchEventTicket(uint256 _eventId, uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        returns (uint256 refundAmount);
}
