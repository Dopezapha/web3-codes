# STX Dividend Distribution Smart Contract

## ABOUT

This Clarity smart contract implements a dividend distribution system for STX token holders. It allows the contract owner to add dividends, which are then automatically distributed to STX holders based on their token balance. Token holders can claim their dividends at any time.

## Features

- Dividend distribution proportional to STX holdings
- On-demand claiming of dividends by token holders
- Automatic calculation of dividends per token
- Protection against double-claiming
- Owner-only functions for adding dividends

## Contract Details

### Constants

- `contract-owner`: The address that deployed the contract
- `err-owner-only`: Error code for unauthorized access attempts
- `err-no-dividends`: Error code when there are no dividends to claim
- `err-transfer-failed`: Error code for failed STX transfers

### Data Variables

- `total-dividends`: Total amount of dividends distributed
- `dividends-per-token`: Amount of dividends per STX token
- `last-distribution-block`: Block height of the last dividend distribution

### Data Maps

- `claimed-dividends`: Tracks the amount of dividends claimed by each account

### Read-Only Functions

1. `get-dividends-per-token()`
   - Returns the current amount of dividends per token

2. `get-claimable-amount(account: principal)`
   - Calculates the claimable dividends for a given account
   - Parameters:
     - `account`: The principal (address) to check for claimable dividends

### Public Functions

1. `add-dividends(amount: uint)`
   - Allows the contract owner to add new dividends for distribution
   - Parameters:
     - `amount`: The amount of STX to add as dividends
   - Requirements:
     - Only the contract owner can call this function
     - The amount must be greater than zero
   - Effects:
     - Transfers STX from the owner to the contract
     - Updates total dividends and dividends per token
     - Updates the last distribution block

2. `claim-dividends()`
   - Allows STX token holders to claim their dividends
   - Requirements:
     - The caller must have claimable dividends
   - Effects:
     - Transfers claimable STX to the caller
     - Updates the claimed dividends for the caller

## Usage

### For the Contract Owner

1. Deploy the contract
2. Call `add-dividends` to distribute dividends to STX holders

### For STX Holders

1. Check claimable dividends using `get-claimable-amount`
2. Call `claim-dividends` to receive your share of the dividends

## Security Considerations

- The contract uses `as-contract` to ensure proper token transfers
- Only the contract owner can add dividends
- The contract prevents claiming more dividends than allocated
- Arithmetic operations are protected against overflow and division by zero

## Limitations

- The contract assumes STX as the native token
- Dividends are distributed based on current token holdings, not historical snapshots
- There's no mechanism to remove or reduce dividends once added

## Development and Testing

To interact with this contract:

1. Deploy the contract to a Stacks blockchain (testnet or mainnet)
2. Use a Stacks wallet or SDK to call the contract functions
3. For testing, use the Clarinet testing framework to write and run unit tests

## Author
Chukwudi Daniel Nwaneri
