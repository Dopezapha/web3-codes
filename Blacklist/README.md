### STX-Blacklist-Manager Smart Contract

### ABOUT
The STX-Blacklist-Manager is a Clarity smart contract designed for the Stacks blockchain. It provides a mechanism to manage a blacklist for STX token transfers. This contract allows for controlled transfers of STX tokens while respecting a blacklist of addresses.

## Features

1. Blacklist management (add/remove addresses)
2. Blacklist-aware STX transfers
3. Controlled transfers by contract owner
4. Contract ownership management
5. Balance checking

### Contract Functions
## Blacklist Management

add-to-blacklist (address principal) -> (response bool uint)

Adds an address to the blacklist.
Only callable by the contract owner.


remove-from-blacklist (address principal) -> (response bool uint)

Removes an address from the blacklist.
Only callable by the contract owner.


is-blacklisted (address principal) -> bool

Checks if an address is blacklisted.
Read-only function, callable by anyone.



## STX Transfers

transfer-stx (amount uint) (sender principal) (recipient principal) -> (response bool uint)

Transfers STX tokens from sender to recipient.
Checks if neither sender nor recipient is blacklisted.
Can only be called by the sender.


controlled-transfer (amount uint) (sender principal) (recipient principal) -> (response bool uint)

Allows the contract owner to transfer STX between any two non-blacklisted addresses.
Only callable by the contract owner.



## Balance Checking

get-stx-balance (address principal) -> uint

Returns the STX balance of the given address.
Read-only function, callable by anyone.



## Contract Management

set-contract-owner (new-owner principal) -> (response bool uint)

Changes the contract owner to the provided address.
Only callable by the current contract owner.


get-contract-owner () -> principal

Returns the current contract owner's address.
Read-only function, callable by anyone.



## Error Codes

ERR-NOT-AUTHORIZED (u100): Caller is not authorized to perform this action.
ERR-ALREADY-BLACKLISTED (u101): Address is already blacklisted.
ERR-NOT-BLACKLISTED (u102): Address is not blacklisted.
ERR-BLACKLISTED (u103): Operation involves a blacklisted address.
ERR-TRANSFER-FAILED (u104): STX transfer failed.

## Setup and Deployment

Ensure you have the Stacks CLI installed and configured.
Clone this repository or copy the contract code.
Deploy the contract to the Stacks blockchain:
Note the contract address after successful deployment.

## Security Considerations

This contract does not prevent direct STX transfers outside of its scope.
Ensure that only trusted addresses are given contract owner privileges.
Regularly audit the blacklist to maintain its integrity.

## Limitations

The contract relies on users and integrating systems to use its functions for transfers.
It does not automatically sync with any external blacklists.

## Contributing

Contributions to improve the STX-Blacklist-Manager are welcome. Please submit pull requests or open issues to discuss proposed changes.

## AUTHOR
Chukwudi Daniel Nwaneri