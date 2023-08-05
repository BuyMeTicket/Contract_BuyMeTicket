// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Ticket} from "./Ticket.sol";
import {ITicketFactory} from "./interfaces/ITicketFactory.sol";
import {IGlobals} from "./interfaces/IGlobals.sol";

contract TicketFactory is ITicketFactory {
    //** Modifier */

    modifier onlyEventHolder() {
        require(globals.isValidEventHolder(msg.sender), "TicketFactory: only valid event holder");
        _;
    }

    //** Storage */

    IGlobals public globals;
    Ticket[] public tokens; //an array that contains different ERC1155 tokens deployed
    mapping(uint256 => address) public indexToContract; //index to contract address mapping
    mapping(uint256 => address) public indexToOwner; //index to ERC1155 owner address

    constructor(address _globals) {
        globals = IGlobals(_globals);
    }

    //** Normal Functions */

    /**
     * @dev createEvent - deploys a ERC1155 token with given parameters
     * @param _contractName - name of our ERC1155 token
     * @param _baseURI - URI resolving to our hosted metadata
     * @param _maxPerWallet - maximum number of ERC1155 tokens that can be minted per wallet
     * @param _startTimestamp - timestamp when minting starts
     * @param _endTimestamp - timestamp when minting ends
     * @param _mintPrices - prices for each ERC1155 token
     * @param _maxSupplys - maximum supply for each ERC1155 token
     * @param _ids - IDs the ERC1155 token should contain
     * @param _names - Names each ID should map to. Case-sensitive.
     * @return _eventAddress - address of deployed ERC1155 token
     * @return _eventId - index of deployed ERC1155 token
     */
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
    ) public onlyEventHolder returns (address _eventAddress, uint256 _eventId) {
        Ticket t = new Ticket(
            _contractName,
            _baseURI,
            _names,
            _ids
        );
        tokens.push(t);
        _eventAddress = address(t);
        _eventId = tokens.length - 1;
        indexToContract[_eventId] = _eventAddress;
        indexToOwner[_eventId] = tx.origin;
        emit ERC1155Created(msg.sender, _eventAddress);
    }
}
