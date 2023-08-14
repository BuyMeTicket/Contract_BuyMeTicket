// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Ticket is ERC1155, ERC1155Burnable, Ownable {
    IERC20 public asset; // the asset used to mint tickets
    string[] public names; // string array of names
    uint256[] public ids; // uint array of ids
    uint256[] public mintPrices;
    uint256[] public maxSupplys;

    string public baseMetadataURI; // the token metadata URI
    string public name; // the token mame
    uint256 public maxPerWallet; // the maximum number of tokens that can be minted per wallet
    uint256 public startTimestamp; // the timestamp when minting starts
    uint256 public endTimestamp; // the timestamp when minting ends

    mapping(string => uint256) public nameToId; // name to id mapping
    mapping(uint256 => string) public idToName; // id to name mapping
    mapping(uint256 => uint256) public idToPrice; // id to price mapping
    mapping(uint256 => uint256) public totalSupply; // id to supply mapping

    constructor(
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
    function mint(address _receiver, uint256 _id, uint256 amount) public returns (uint256) {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(_checkMaxPerWalletWhenMint(amount), "Ticket: max per wallet exceeded");
        require(totalSupply[_id] + amount <= maxSupplys[_id], "Ticket: max supply exceeded");
        totalSupply[_id] += amount;
        // transfer asset to contract
        SafeERC20.safeTransferFrom(asset, tx.origin, address(this), idToPrice[_id] * amount);
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
    function mintBatch(address to, uint256[] memory _ids, uint256[] memory amounts, bytes memory data) public {
        require(_checkDuringMinting(), "Ticket: minting has not started or has ended");
        require(_checkMaxPerWalletWhenMintBatch(amounts), "Ticket: max per wallet exceeded");
        _mintBatch(to, _ids, amounts, data);
    }

    // TODO: implement refund mechanism
    function refund(address _burner, uint256 _id, uint256 _amount) public {

    }

    // implement withdraw feature for owner
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //** Help Function */

    function _checkMaxPerWalletWhenMint(uint256 amount) internal view returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(tx.origin, ids[i]);
        }
        return (total + amount <= maxPerWallet);
    }

    function _checkMaxPerWalletWhenMintBatch(uint256[] memory amounts) internal view returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            total += balanceOf(tx.origin, ids[i]);
            total += amounts[i];
        }
        return total <= maxPerWallet;
    }

    function _checkDuringMinting() internal view returns (bool) {
        return (block.timestamp >= startTimestamp && block.timestamp <= endTimestamp);
    }
}
