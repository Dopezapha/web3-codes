### STX-Blacklist-Manager Smart Contract

## ABOUT
The STX-Blacklist-Manager is a Clarity smart contract designed for the Stacks blockchain. It provides a mechanism to manage a restricted list for STX token transfers. This contract allows for controlled transfers of STX tokens while respecting a list of restricted addresses.

## Features

Restricted address management (restrict/unrestrict addresses)
Restriction-aware STX transfers
Controlled transfers by admin
Admin management
STX balance checking

### Contract Functions
## Restricted Address Management

restrict-address (target principal) -> (response bool uint)

Adds an address to the restricted list.
Only callable by the admin.


unrestrict-address (target principal) -> (response bool uint)

Removes an address from the restricted list.
Only callable by the admin.


is-restricted (target principal) -> bool

Checks if an address is restricted.
Read-only function, callable by anyone.



## STX Transfers

send-stx (amount uint) (from principal) (to principal) -> (response bool uint)

Transfers STX from sender to recipient.
Checks if neither sender nor recipient is restricted.
Can only be called by the sender.
Verifies that the amount is valid and the sender has sufficient balance.


admin-transfer (amount uint) (from principal) (to principal) -> (response bool uint)

Allows the admin to transfer STX between any two non-restricted addresses.
Only callable by the admin.
Verifies that the amount is valid and the sender has sufficient balance.



## Balance Checking

check-stx-balance (target principal) -> uint

Returns the STX balance of the given address.
Read-only function, callable by anyone.



## Contract Management

update-admin (new-admin principal) -> (response bool uint)

Changes the admin to the provided address.
Only callable by the current admin.
Ensures the new admin is not on the restricted list.


get-admin () -> principal

Returns the current admin's address.
Read-only function, callable by anyone.



## Error Codes

ERROR-UNAUTHORIZED (u100): Caller is not authorized to perform this action.
ERROR-ALREADY-LISTED (u101): Address is already restricted.
ERROR-NOT-LISTED (u102): Address is not restricted.
ERROR-RESTRICTED (u103): Operation involves a restricted address.
ERROR-TRANSFER-UNSUCCESSFUL (u104): STX transfer failed.
ERROR-INVALID-AMOUNT (u105): Invalid transfer amount.

## Setup and Deployment

Ensure you have the Stacks CLI installed and configured.
Clone this repository or copy the contract code.
Deploy the contract to the Stacks blockchain.
Note the contract address after successful deployment.

## Security Considerations

This contract includes checks for valid transfer amounts and sufficient balances.
The contract prevents setting a restricted address as the new admin.
Ensure that only trusted addresses are given admin privileges.
Regularly audit the restricted address list to maintain its integrity.

## Limitations

The contract relies on users and integrating systems to use its functions for transfers.
It does not automatically sync with any external restricted lists.


## Contributing

Contributions to improve the STX-Blacklist-Manager are welcome. Please submit pull requests or open issues to discuss proposed changes.

## AUTHOR
Chukwudi Daniel Nwaneri