# This is a smart contract on Liquidity Mining

## Overview

This Clarity smart contract implements a liquidity mining (staking) mechanism where users can stake LP tokens and earn rewards in another token. The contract allows for staking, withdrawing, and claiming rewards.

## Features

- Stake LP tokens
- Withdraw staked LP tokens
- Claim rewards
- Dynamic reward rate adjustable by the contract owner
- Safety checks to prevent common errors and potential exploits

## Contract Functions

### Initialize

```clarity
(define-public (initialize (token <ft-trait>) (lp-token <ft-trait>))

Initializes the contract with the reward token and LP token addresses. Can only be called once.

## Stake

(define-public (stake (amount uint))
Allows users to stake LP tokens. The amount must be greater than zero.

## Withdraw

(define-public (withdraw (amount uint))
Allows users to withdraw their staked LP tokens.

## Claim Reward

(define-public (claim-reward)
Allows users to claim their earned rewards.

## Set Reward Rate

(define-public (set-reward-rate (new-rate uint))
Allows the contract owner to set a new reward rate. The rate must be between MIN_RATE and MAX_RATE.

## Read-Only Functions

1. (get-reward-rate): Returns the current reward rate.
2. (get-total-supply): Returns the total amount of staked LP tokens.
3. (get-staker-info (staker principal)): Returns information about a specific staker.


## Constants

1. PRECISION: Set to u1000000 for calculations involving decimals.
2. MIN_RATE: Minimum allowed reward rate.
3. MAX_RATE: Maximum allowed reward rate.


## Error Codes

1. ERR-NOT-AUTHORIZED (u100): Caller is not authorized to perform the action.
2. ERR-NOT-INITIALIZED (u101): Contract has not been initialized.
3. ERR-ALREADY-INITIALIZED (u102): Contract has already been initialized.
4. ERR-INSUFFICIENT-BALANCE (u103): User has insufficient balance for the action.
5. ERR-INVALID-AMOUNT (u104): Invalid amount specified (e.g., zero or negative).
6. ERR-INVALID-RATE (u105): Invalid reward rate specified.
7. ERR-INVALID-TOKEN-CONTRACT (u106): Invalid token contract address.
8. ERR-INVALID-LP-TOKEN-CONTRACT (u107): Invalid LP token contract address.


## Security Considerations

1. The contrat includes checks to ensure that token addresses are valid contracts.
2. Staking and reward rate changes include bounds checking to prevent potential exploits.
3. The contract uses the SIP-010 fungible token standard for compatibility.


## Usage

1. Deploy the contract to the Stacks blockchain.
2. Initialize the contract with the reward token and LP token addresses.
3. Users can then stake LP tokens, withdraw them, and claim rewards.
4. The contract owner can adjust the reward rate as needed.


## Development and Testing

This contract can be tested and deployed using the Clarinet development environment. Use the following command to check for errors:
Copyclarinet check Mining.clar
Ensure all warnings and errors are addressed before deploying to mainnet.


## Author
Chukwudi Daniel Nwaneri