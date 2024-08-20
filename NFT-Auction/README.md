# Clarity smart contract on NFT Auction

This smart contract is written in Clarity for the Stacks blockchain. It facilitates the creation and management of NFT auctions, allowing users to bid on NFTs and transfer ownership to the highest bidder at the end of the auction.

## Features

- **Create Auction**: Allows a user to create an auction for an NFT they own.
- **Place Bid**: Allows users to place bids on active auctions.
- **End Auction**: Ends the auction and transfers the NFT to the highest bidder.
- **Get Auction Details**: Retrieves details of a specific auction.

## Functions

### `create-auction`

Creates a new auction for an NFT.

#### Parameters:
- `nft-contract` (principal): The contract address of the NFT.
- `nft-id` (uint): The ID of the NFT.
- `start-price` (uint): The starting price of the auction.
- `duration` (uint): The duration of the auction in blocks.

#### Returns:
- `auction-id` (uint): The ID of the created auction.

### `place-bid`

Places a bid on an active auction.

#### Parameters:
- `auction-id` (uint): The ID of the auction.
- `bid-amount` (uint): The amount of the bid.

#### Returns:
- `true` if the bid is successfully placed.

### `end-auction`

Ends the auction and transfers the NFT to the highest bidder.

#### Parameters:
- `auction-id` (uint): The ID of the auction.

#### Returns:
- `true` if the auction is successfully ended.

### `get-auction-details`

Retrieves details of a specific auction.

#### Parameters:
- `auction-id` (uint): The ID of the auction.

#### Returns:
- A tuple containing the auction details.

## Data Structures

### `auctions` Map

Stores the details of each auction.

#### Keys:
- `auction-id` (uint): The ID of the auction.

#### Values:
- `seller` (principal): The address of the seller.
- `nft-asset` (optional (tuple (contract-address principal) (token-id uint))): The NFT being auctioned.
- `start-price` (uint): The starting price of the auction.
- `end-block` (uint): The block height at which the auction ends.
- `highest-bidder` (optional principal): The address of the highest bidder.
- `highest-bid` (uint): The highest bid amount.

## Error Codes

- `u1`: The sender is not the owner of the NFT.
- `u2`: Failed to transfer the NFT to the contract.
- `u3`: Auction not found.
- `u4`: Auction has already ended.
- `u5`: Bid amount is not higher than the current highest bid.
- `u6`: Bid amount is not higher than the starting price.
- `u7`: NFT asset is not valid.
- `u8`: Auction not found.
- `u9`: Auction has not ended yet.
- `u10`: NFT asset is not valid.
- `u11`: No bids were placed.

## Usage

1. **Create an Auction**: Call the `create-auction` function with the NFT contract address, NFT ID, starting price, and duration.
2. **Place a Bid**: Call the `place-bid` function with the auction ID and bid amount.
3. **End the Auction**: Call the `end-auction` function with the auction ID to transfer the NFT to the highest bidder.
4. **Get Auction Details**: Call the `get-auction-details` function with the auction ID to retrieve auction details.

## Example

```clarity
;; Create an auction
(create-auction 'SP2J4... 'u1 'u100 'u144)

;; Place a bid
(place-bid 'u1 'u150)

;; End the auction
(end-auction 'u1)

;; Get auction details
(get-auction-details 'u1)

## Author
Chukwudi Daniel Nwaneri