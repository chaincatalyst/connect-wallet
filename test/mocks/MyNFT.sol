// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "./ERC721.sol";

contract MyNFT is ERC721 {

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "https://example.com";
    }
}
