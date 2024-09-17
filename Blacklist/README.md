# STX-Blacklist-Manager Smart Contract

## ABOUT
The STX-Blacklist-Manager is a Clarity smart contract designed for the Stacks blockchain. It provides a comprehensive mechanism to manage token transfers, including a restricted list, whitelist, transaction limits, and fee management for STX token transfers. This contract allows for controlled and secure transfers of STX tokens while respecting various security and compliance measures.

## Features

- Restricted address management (restrict/unrestrict addresses)
- Whitelist management
- Transaction limit management
- Restriction-aware STX transfers with fee calculation
- Controlled transfers by admin and trusted deputies
- Admin and trusted deputy management
- Contract pause/unpause functionality
- STX balance checking
- Transfer fee management

## Contract Functions

### Restricted Address Management

- `restrict-address (target principal) -> (response bool uint)`
  - Adds an address to the restricted list.
  - Callable by the admin or trusted deputies.

- `unrestrict-address (target principal) -> (response bool uint)`
  - Removes an address from the restricted list.
  - Callable by the admin or trusted deputies.

- `is-restricted (target principal) -> bool`
  - Checks if an address is restricted.
  - Read-only function, callable by anyone.

### Whitelist Management

- `whitelist-address (target principal) -> (response bool uint)`
  - Adds an address to the whitelist.
  - Callable by the admin or trusted deputies.

- `remove-from-whitelist (target principal) -> (response bool uint)`
  - Removes an address from the whitelist.
  - Callable by the admin or trusted deputies.

- `is-whitelisted (target principal) -> bool`
  - Checks if an address is whitelisted.
  - Read-only function, callable by anyone.

### Transaction Limit Management

- `set-transaction-limit (target principal) (daily-limit uint) -> (response bool uint)`
  - Sets a daily transaction limit for a specific address.
  - Callable by the admin or trusted deputies.

### STX Transfers

- `send-stx (amount uint) (from principal) (to principal) -> (response bool uint)`
  - Transfers STX from sender to recipient.
  - Checks if neither sender nor recipient is restricted.
  - Applies transaction limits and transfer fees.
  - Can only be called by the sender.

- `admin-transfer (amount uint) (from principal) (to principal) -> (response bool uint)`
  - Allows the admin or trusted deputies to transfer STX between any two non-restricted addresses.
  - Bypasses transaction limits and fees.

### Balance Checking

- `check-stx-balance (target principal) -> uint`
  - Returns the STX balance of the given address.
  - Read-only function, callable by anyone.

### Contract Management

- `update-admin (new-admin principal) -> (response bool uint)`
  - Changes the admin to the provided address.
  - Only callable by the current admin.
  - Implements a time lock for added security.

- `get-admin () -> principal`
  - Returns the current admin's address.
  - Read-only function, callable by anyone.

- `get-next-admin-change-time () -> uint`
  - Returns the block height when the next admin change is possible.
  - Read-only function, callable by anyone.

### Trusted Deputy Management

- `add-trusted-deputy (deputy principal) -> (response bool uint)`
  - Adds a trusted deputy.
  - Only callable by the admin.

- `remove-trusted-deputy (deputy principal) -> (response bool uint)`
  - Removes a trusted deputy.
  - Only callable by the admin.

- `is-deputy (address principal) -> bool`
  - Checks if an address is a trusted deputy.
  - Read-only function, callable by anyone.

### Fee Management

- `set-transfer-fee (new-fee uint) -> (response bool uint)`
  - Sets the transfer fee percentage (max 10%).
  - Only callable by the admin.

- `get-transfer-fee () -> uint`
  - Returns the current transfer fee percentage.
  - Read-only function, callable by anyone.

- `set-fee-recipient (new-recipient principal) -> (response bool uint)`
  - Sets the recipient address for collected fees.
  - Only callable by the admin.

- `get-fee-recipient () -> principal`
  - Returns the current fee recipient address.
  - Read-only function, callable by anyone.

### Contract Pause Functionality

- `pause-contract () -> (response bool uint)`
  - Pauses the contract, preventing most operations.
  - Only callable by the admin.

- `unpause-contract () -> (response bool uint)`
  - Unpauses the contract, allowing operations to resume.
  - Only callable by the admin.

- `is-contract-paused () -> bool`
  - Checks if the contract is currently paused.
  - Read-only function, callable by anyone.

## Error Codes

- ERROR-UNAUTHORIZED (u100): Caller is not authorized to perform this action.
- ERROR-ALREADY-LISTED (u101): Address is already listed (restricted or whitelisted).
- ERROR-NOT-LISTED (u102): Address is not listed (restricted or whitelisted).
- ERROR-RESTRICTED (u103): Operation involves a restricted address.
- ERROR-TRANSFER-UNSUCCESSFUL (u104): STX transfer failed.
- ERROR-INVALID-AMOUNT (u105): Invalid transfer amount.
- ERROR-INVALID-TIME-LOCK (u106): Admin change time lock has not expired.
- ERROR-INSUFFICIENT-FEE (u107): Insufficient balance to cover the transfer fee.
- ERROR-CONTRACT-PAUSED (u108): Contract is paused and cannot perform the operation.
- ERROR-INVALID-INPUT (u109): Invalid input parameters.

## Setup and Deployment

1. Ensure you have the Stacks CLI installed and configured.
2. Clone this repository or copy the contract code.
3. Deploy the contract to the Stacks blockchain.
4. Note the contract address after successful deployment.

## Security Considerations

- This contract includes checks for valid transfer amounts, sufficient balances, and various authorization levels.
- The contract prevents setting a restricted address as the new admin or fee recipient.
- A time lock is implemented for admin changes to provide an additional security layer.
- The contract can be paused in case of emergencies.
- Ensure that only trusted addresses are given admin and deputy privileges.
- Regularly audit the restricted address list, whitelist, and transaction limits to maintain their integrity.

## Limitations

- The contract relies on users and integrating systems to use its functions for transfers.
- It does not automatically sync with any external restricted lists or whitelist.
- The effectiveness of transaction limits depends on the block height and may not align perfectly with calendar days.

## Contributing

Contributions to improve the STX-Blacklist-Manager are welcome. Please submit pull requests or open issues to discuss proposed changes.

## AUTHOR
Chukwudi Daniel Nwaneri