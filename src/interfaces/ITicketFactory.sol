// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ITicketFactory {
    //** events */

    event ERC1155Created(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event ERC1155Minted(address owner, address tokenContract, uint256 amount); //emited when ERC1155 token is minted

    //** view function */

    //** normal function */

    function createEvent(
        string memory _contractName,
        string memory _baseURI,
        uint256 _maxPerWallet,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] memory _mintPrices,
        uint256[] memory _maxSupplys,
        uint256[] memory _ids,
        string[] memory _names
    ) external returns (address _eventAddress, uint256 _eventId);
}
