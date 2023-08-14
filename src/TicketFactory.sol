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

    modifier onlyGovernor() {
        require(msg.sender == globals.governor(), "TicketFactory: only governor");
        _;
    }

    //** Storage */

    IGlobals public globals;
    Ticket[] public tokens; //an array that contains different ERC1155 tokens contracrt deployed
    mapping(uint256 => address) public eventIdToAddr; //index to contract address mapping
    mapping(uint256 => address) public eventIdToOwner; //index to ERC1155 owner address, which is the event holder

    constructor(address _globals) {
        globals = IGlobals(_globals);
    }

    //** Normal Functions */

    /**
     * @dev deploys a ERC1155 token with given parameters
     * @param _contractName  name of our ERC1155 token
     * @param _baseURI resolving to our hosted metadata
     * @param _maxPerWallet maximum number of ERC1155 tokens that can be minted per wallet
     * @param _startTimestamp timestamp when minting starts
     * @param _endTimestamp timestamp when minting ends
     * @param _mintPrices prices for each ERC1155 token
     * @param _maxSupplys maximum supply for each ERC1155 token
     * @param _ids IDs the ERC1155 token should contain
     * @param _names Names each ID should map to. Case-sensitive.
     * @return _eventAddress address of deployed ERC1155 token
     * @return _eventId index of deployed ERC1155 token
     */
    function createEvent(
        string memory _contractName,
        string memory _baseURI,
        uint256 _maxPerWallet,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] memory _mintPrices,
        uint256[] memory _maxSupplys,
        string[] memory _names,
        uint8[] memory _ids
    ) public onlyEventHolder returns (address _eventAddress, uint256 _eventId) {
        Ticket t = new Ticket(
            _contractName,
            _baseURI,
            _maxPerWallet,
            _startTimestamp,
            _endTimestamp,
            _mintPrices,
            _maxSupplys,
            _names,
            _ids
        );
        tokens.push(t);
        _eventAddress = address(t);
        _eventId = tokens.length - 1;
        eventIdToAddr[_eventId] = _eventAddress;
        eventIdToOwner[_eventId] = msg.sender;
        emit ERC1155Created(msg.sender, _eventAddress);
    }

    // TODO: add whitelist functionality
    /**
     * @dev mints a ERC1155 token with given parameters
     * @param _eventId index position in our tokens array - represents which ERC1155 you want to interact with
     * @param _name Case-sensitive. Name of the token (this maps to the ID you created when deploying the token)
     * @param _amount amount of tokens you wish to mint
     */
    function mintEventTicket(uint256 _eventId, string memory _name, uint256 _amount) external {
        uint256 id = getIdByName(_eventId, _name);
        tokens[_eventId].mint(msg.sender, id, _amount);
        emit ERC1155Minted(msg.sender, address(tokens[_eventId]), _amount);
    }

    function setGlobals(address _globals) external onlyGovernor {
        require(_globals != address(0) && IGlobals(_globals).governor() != address(0), "TicketFactory: invalid globals");
        globals = IGlobals(_globals);
    }

    //** View Functions */

    function getAllEventAddr() external view returns (address[] memory) {
        address[] memory _tokens = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = address(tokens[i]);
        }
        return _tokens;
    }

    function getTicketBalanceOfById(address _account, uint256 _eventId, uint256 _tokenId)
        external
        view
        returns (uint256 _amount)
    {
        return tokens[_eventId].balanceOf(_account, _tokenId);
    }

    function getTicketBalanceOfByName(address _account, uint256 _eventId, string calldata _name)
        external
        view
        returns (uint256 _amount)
    {
        uint256 id = getIdByName(_eventId, _name);
        return tokens[_eventId].balanceOf(_account, id);
    }

    function getTicektInfoById(uint256 _eventId, uint256 _tokenId)
        public
        view
        returns (address _contract, address _evnetHolder, string memory _uri, uint256 supply)
    {
        Ticket token = tokens[_eventId];
        return (address(token), token.owner(), token.uri(_tokenId), token.totalSupply(_tokenId));
    }

    function governor() external view override returns (address) {
        return globals.governor();
    }

    //** Helper Functions */

    function getIdByName(uint256 _eventId, string memory _name) internal view returns (uint256) {
        return tokens[_eventId].nameToId(_name);
    }

    function getNameById(uint256 _eventId, uint256 _tokenId) internal view returns (string memory) {
        return tokens[_eventId].idToName(_tokenId);
    }
}
