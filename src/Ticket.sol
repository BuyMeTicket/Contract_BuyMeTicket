// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {ITicket} from "./interfaces/ITicket.sol";

contract Ticket is ERC1155, Ownable, ITicket {
    IERC20 public asset; // the asset used to mint tickets
    string[] public names; // string array of names
    uint256[] public ids; // uint array of ids
    uint256[] public mintPrices;
    uint256[] public maxSupplys;

    address immutable EVENT_HOLDER; // the address of the event holder
    string public baseMetadataURI; // the token metadata URI
    string public name; // the token mame
    uint256 public maxPerWallet; // the maximum number of tokens that can be minted per wallet
    uint256 public startTimestamp; // the timestamp when minting starts
    uint256 public endTimestamp; // the timestamp when minting ends

    mapping(string => uint256) public nameToId; // name to id mapping
    mapping(uint256 => string) public idToName; // id to name mapping
    mapping(uint256 => uint256) public idToPrice; // id to price mapping
    mapping(uint256 => uint256) public totalSupply; // id to supply mapping

    bool public isEventOpen;

    constructor(
        address _eventHolder,
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
    ) ERC1155(_baseURI) {
        require(_asset != address(0), "Ticket: asset is zero address");
        require(_eventHolder != address(0), "Ticket: event holder is zero address");
        EVENT_HOLDER = _eventHolder;
        asset = IERC20(_asset);
        names = _names;
        ids = _ids;
        mintPrices = _mintPrices;
        maxSupplys = _maxSupplys;
        createMapping();
        setURI(_baseURI);
        baseMetadataURI = _baseURI;
        name = _contractName;
        maxPerWallet = _maxPerWallet;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        isEventOpen = true;
    }

    function setEventStatus(bool _isEventOpen) public onlyOwner {
        isEventOpen = _isEventOpen;
    }

    /*
    used to change metadata, only owner access
    */
    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    /*
    set a mint fee. only used for mint, not batch.
    */
    function setPriceById(uint256 _id, uint256 _price) public onlyOwner {
        idToPrice[_id] = _price;
    }

    /*
    mint(address account, uint _id, uint256 amount)

    account - address to mint the token to
    _id - the ID being minted
    amount - amount of tokens to mint
    */
    function mint(address _receiver, uint256 _id, uint256 amount)
        public
        onlyTicketFactory
        onlyEventOpen
        returns (uint256)
    {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(_checkMaxPerWalletWhenMint(_receiver, amount), "Ticket: max per wallet exceeded");
        require(totalSupply[_id] + amount <= maxSupplys[_id], "Ticket: max supply exceeded");
        totalSupply[_id] += amount;
        // transfer asset to contract
        SafeERC20.safeTransferFrom(asset, _receiver, address(this), idToPrice[_id] * amount);
        _mint(_receiver, _id, amount, "");
        return _id;
    }

    /*
    mintBatch(address to, uint256[] memory _ids, uint256[] memory amounts, bytes memory data)

    to - address to mint the token to
    _ids - the IDs being minted
    amounts - amount of tokens to mint given ID
    bytes - additional field to pass data to function
    */
    function mintBatch(address _receiver, uint256[] memory _ids, uint256[] memory amounts, bytes memory data)
        public
        onlyTicketFactory
        onlyEventOpen
    {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(_checkMaxPerWalletWhenMintBatch(_receiver, amounts), "Ticket: max per wallet exceeded");

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(totalSupply[_ids[i]] + amounts[i] <= maxSupplys[_ids[i]], "Ticket: max supply exceeded");
            totalSupply[_ids[i]] += amounts[i];
            totalPrice += idToPrice[_ids[i]] * amounts[i];
        }

        SafeERC20.safeTransferFrom(asset, _receiver, address(this), totalPrice);
        _mintBatch(_receiver, _ids, amounts, data);
    }

    function refund(address _burner, uint256 _id, uint256 _amount)
        public
        onlyTicketFactory
        returns (uint256 refundAmount)
    {
        require(_checkCanRefund(), "Ticket: refunding is not allowed");
        refundAmount = (ud(idToPrice[_id] * _amount).mul(_getRefundRate())).intoUint256();
        _burn(_burner, _id, _amount);
        // approve asset to TicketFactory
        asset.approve(msg.sender, refundAmount);
        SafeERC20.safeTransfer(asset, _burner, refundAmount);
    }

    function refundBatch(address _burner, uint256[] memory _ids, uint256[] memory _amounts)
        public
        onlyTicketFactory
        returns (uint256 refundAmount)
    {
        require(_checkCanRefund(), "Ticket: refunding is not allowed");
        refundAmount = 0;
        for (uint256 i = 0; i < _ids.length; ++i) {
            refundAmount += (ud(idToPrice[_ids[i]] * _amounts[i]).mul(_getRefundRate())).intoUint256();
        }
        _burnBatch(_burner, _ids, _amounts);
        // approve asset to TicketFactory
        asset.approve(msg.sender, refundAmount);
        SafeERC20.safeTransfer(asset, _burner, refundAmount);
    }

    // TODO: implement withdraw feature for event holder
    function withdraw() public {
        require(msg.sender == EVENT_HOLDER, "Ticket: caller is not the event holder");
        require(block.timestamp > endTimestamp, "Ticket: event is not ended yet");
        // transfer asset to event holder
        emit Withdrawn(EVENT_HOLDER, asset.balanceOf(address(this)));
        SafeERC20.safeTransfer(asset, EVENT_HOLDER, asset.balanceOf(address(this)));
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
        public
        override
    {
        // silence compiler warning
        _from;
        _to;
        _id;
        _amount;
        _data;
        // we forbid transfer in this contract
        revert("Ticket: transfer not allowed");
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        // silence compiler warning
        _from;
        _to;
        _ids;
        _amounts;
        _data;
        // we forbid transfer in this contract
        revert("Ticket: transfer not allowed");
    }

    //** View Function */

    // notice: the decimals of refund rate is 18
    function getRefundRate() external view returns (uint256 _refundRate) {
        _refundRate = _getRefundRate().intoUint256();
    }

    // sets our URI and makes the ERC1155 OpenSea compatible
    function uri(uint256 _tokenid) public view override returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenid), ".json"));
    }

    function getNames() public view returns (string[] memory) {
        return names;
    }

    //** Modifier */

    modifier onlyEventOpen() {
        require(isEventOpen, "Ticket: event is shutdown right now");
        _;
    }

    modifier onlyTicketFactory() {
        require(msg.sender == owner(), "Ticket: caller is not the owner");
        _;
    }

    //** Help Function */

    function _getRefundRate() internal view returns (UD60x18 _refundRate) {
        _refundRate = _max(ud(endTimestamp - block.timestamp).div(ud(endTimestamp - startTimestamp)), ud(0.2e18));
        _refundRate = _refundRate.div(ud(1e18));
    }

    function _max(UD60x18 _a, UD60x18 _b) internal pure returns (UD60x18 _maximum) {
        _maximum = _a.gt(_b) ? _a : _b;
    }

    function _checkMaxPerWalletWhenMint(address _receiver, uint256 _amount) internal view returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(_receiver, ids[i]);
        }
        return (total + _amount <= maxPerWallet);
    }

    function _checkMaxPerWalletWhenMintBatch(address _receiver, uint256[] memory _amounts)
        internal
        view
        returns (bool)
    {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(_receiver, ids[i]);
            total += _amounts[i];
        }
        return total <= maxPerWallet;
    }

    function _checkDuringMinting() internal view returns (bool) {
        return (block.timestamp >= startTimestamp && block.timestamp <= endTimestamp);
    }

    function _checkCanRefund() internal view returns (bool) {
        return (block.timestamp < endTimestamp - 4 days);
    }

    // creates a mapping of strings to ids (i.e ["one","two"], [1,2] - "one" maps to 1, vice versa.)
    function createMapping() private {
        for (uint256 id = 0; id < ids.length; id++) {
            nameToId[names[id]] = ids[id];
            idToName[ids[id]] = names[id];
            idToPrice[ids[id]] = mintPrices[id];
        }
    }
}
