### Pension Fund Smart Contract

## Table of Contents

Introduction
Features
Prerequisites
Installation
Usage
Smart Contract Functions
Error Codes
Security Considerations
Testing
Contributing
License

## Introduction
This Enhanced Pension Fund Smart Contract is a decentralized application (DApp) built on the Stacks blockchain using Clarity smart contract language. It provides a robust framework for managing a pension fund system, allowing users to contribute, employers to participate, and administrators to manage the fund efficiently.

## Features

1. User registration with birth year validation
2. Multiple investment options with customizable risk levels
3. User and employer contributions
4. Vesting mechanism for contributions
5. Age-based eligibility for penalty-free withdrawals
6. Early withdrawal with penalty option
7. Employer registration and employee association
8. Administrative functions for managing retirement age and investment options

## Prerequisites

Clarinet: A Clarity runtime packaged as a command line tool
Node.js (for running tests and scripts)
Stacks Wallet (for interacting with the contract on the Stacks blockchain)

## Installation

Clone the repository:
git clone
cd enhanced-pension-fund

Install dependencies:
npm install

Set up Clarinet:
clarinet new

Copy the contract into the contracts folder:
cp Pension-fund.clar contracts/


Usage
To deploy and interact with the contract:

Deploy the contract using Clarinet:
clarinet deploy

Interact with the contract using Clarinet console:
clarinet console

For mainnet deployment, use the Stacks transaction broadcaster or a wallet provider.

### Smart Contract Functions
## User Functions

register-user: Register a new user with their birth year
user-contribute: Allow users to contribute to their pension fund
user-withdraw: Enable users to withdraw funds (with conditions)

## Employer Functions

employer-contribute: Allow employers to contribute on behalf of employees

## Administrative Functions

1. update-retirement-age: Update the retirement age for the fund
2. add-investment-option: Add new investment options
3. register-employer: Register a new employer
4. set-employee-employer: Associate an employee with their employer

## Read-Only Functions

1. get-user-balance: Retrieve a user's balance for a specific investment option
2. get-user-profile: Get a user's profile information
3. is-eligible: Check if a user is eligible for penalty-free withdrawal
4. get-investment-option-details: Get details of an investment option
5. is-employer: Check if an address is a registered employer

## Error Codes

ERR_NOT_AUTHORIZED (u100): User not authorized for the action
ERR_INVALID_AMOUNT (u101): Invalid contribution or withdrawal amount
ERR_INSUFFICIENT_BALANCE (u102): Insufficient balance for withdrawal
ERR_NOT_ELIGIBLE (u103): User not eligible for the action
ERR_INVALID_OPTION (u104): Invalid investment option
ERR_NOT_EMPLOYER (u105): Address is not a registered employer
ERR_INVALID_INPUT (u106): Invalid input provided
ERR_ALREADY_REGISTERED (u107): Employer already registered

## Security Considerations

1. The contract uses various checks and balances to ensure secure operations.
2. Only the contract owner can perform administrative functions.
3. Users can only withdraw their vested amount or face penalties for early withdrawal.
4. Employer registration is controlled to prevent unauthorized contributions.

## Testing
Run the test suite using Clarinet:
Copyclarinet test

## Contributing

Fork the repository
Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request

## AUTHOR
Chukwudi Daniel Nwaneri