// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @notice ERC20 asset details.
 * @param token The token address for the erc20 asset.
 * @param tokenAmount The amount of erc20 tokens.
 */
struct ERC20Asset {
    address token;
    uint256 tokenAmount;
}

/**
 * @notice ERC721 asset details.
 * @param token The token address for the erc721 asset.
 * @param tokenId The token id of the erc721 assset.
 */
struct ERC721Asset {
    address token;
    uint256 tokenId;
}

/**
 * @notice Order details.
 * @param maker The maker of the order.
 * @param isCall Whether or not the order is for a call or put option.
 * @param isLong Whether or not the order is long or short.
 * @param baseAsset The erc20 contract to use for the strike and premium.
 * @param strike The strike amount.
 * @param premium The premium amount.
 * @param duration The duration of the option contract (in seconds).
 * @param expiration The timestamp after which the order is no longer (unix).
 * @param nonce A random number for each order to prevent hash collisions and also check order validity.
 * @param whitelist A list of addresses that are allowed to fill this order - if empty then anyone can fill.
 * @param floorTokens A list of erc721 contract addresses for the underlying.
 * @param erc20Assets A list of erc20 assets for the underlying.
 * @param erc721Assets A list of erc721 assets for the underlying.
 */
struct Order {
    address maker;
    bool isCall;
    bool isLong;
    address baseAsset;
    uint256 strike;
    uint256 premium;
    uint256 duration;
    uint256 expiration;
    uint256 nonce;
    address[] whitelist;
    address[] floorTokens;
    ERC20Asset[] erc20Assets;
    ERC721Asset[] erc721Assets;
}
