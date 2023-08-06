// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ITicket} from "./interfaces/ITicket.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Ticket is ITicket, ERC1155, Ownable {
    string[] public names; //string array of names
    uint256[] public ids; //uint array of ids
    uint256[] public mintPrices;
    uint256[] public maxSupplys;

    string public baseMetadataURI; //the token metadata URI
    string public name; //the token mame
    uint256 public maxPerWallet; //the maximum number of tokens that can be minted per wallet
    uint256 public startTimestamp; //the timestamp when minting starts
    uint256 public endTimestamp; //the timestamp when minting ends

    mapping(string => uint256) public nameToId; //name to id mapping
    mapping(uint256 => string) public idToName; //id to name mapping
    mapping(uint256 => uint256) public idToPrice; //id to price mapping
    mapping(uint256 => uint256) public idToCurrentSupply; //id to supply mapping

    /*
    constructor is executed when the factory contract calls its own deployERC1155 method
    */
    constructor(
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

        transferOwnership(tx.origin);
    }

    /*
    creates a mapping of strings to ids (i.e ["one","two"], [1,2] - "one" maps to 1, vice versa.)
    */
    function createMapping() private {
        for (uint256 id = 0; id < ids.length; id++) {
            nameToId[names[id]] = ids[id];
            idToName[ids[id]] = names[id];
            idToPrice[ids[id]] = mintPrices[id];
        }
    }
    /*
    sets our URI and makes the ERC1155 OpenSea compatible
    */

    function uri(uint256 _tokenid) public view override returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(_tokenid), ".json"));
    }

    function getNames() public view returns (string[] memory) {
        return names;
    }

    /*
    used to change metadata, only owner access
    */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /*
    set a mint fee. only used for mint, not batch.
    */
    function setFeeById(uint256 _id, uint256 _fee) public onlyOwner {
        idToPrice[_id] = _fee;
    }

    /*
    mint(address account, uint _id, uint256 amount)

    account - address to mint the token to
    _id - the ID being minted
    amount - amount of tokens to mint
    */
    function mint(address account, uint256 _id, uint256 amount) public payable returns (uint256) {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(balanceOf(account, _id) + amount <= maxSupplys[_id], "Ticket: max supply exceeded");
        require(_checkMaxPerWalletWhenMint(amount), "Ticket: max per wallet exceeded");
        require(idToPrice[_id] == msg.value, "Ticket: incorrect mint fee");

        _mint(account, _id, amount, "");
        return _id;
    }

    /*
    mintBatch(address to, uint256[] memory _ids, uint256[] memory amounts, bytes memory data)

    to - address to mint the token to
    _ids - the IDs being minted
    amounts - amount of tokens to mint given ID
    bytes - additional field to pass data to function
    */
    function mintBatch(address to, uint256[] memory _ids, uint256[] memory amounts, bytes memory data) public {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(_checkMaxPerWalletWhenMintBatch(amounts), "Ticket: max per wallet exceeded");
        _mintBatch(to, _ids, amounts, data);
    }

    //** Help Function */

    function _checkMaxPerWalletWhenMint(uint256 amount) internal view returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(msg.sender, ids[i]);
        }
        return (total + amount <= maxPerWallet);
    }

    function _checkMaxPerWalletWhenMintBatch(uint256[] memory amounts) internal view returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(msg.sender, ids[i]);
            total += amounts[i];
        }
        return total <= maxPerWallet;
    }

    function _checkDuringMinting() internal view returns (bool) {
        return (block.timestamp >= startTimestamp && block.timestamp <= endTimestamp);
    }
}
