# STX Dividend Distribution Frontend

## ABOUT

This React-based frontend application interfaces with a Stacks blockchain smart contract for dividend distribution. It allows users to connect their Stacks wallet, view contract information, update their holdings, claim payouts, and perform admin actions if authorized.

## Features

- Wallet connection using Stacks Connect
- View contract information (payouts per token, contract holdings)
- User actions: update holdings, claim payouts
- Admin actions: add payouts, update token supply, withdraw unclaimed payouts
- Responsive design for desktop and mobile devices
- Real-time data updates
- Error handling and loading states

## Prerequisites

Before you begin, ensure you have met the following requirements:

- Node.js (v14.0.0 or later)
- npm (v6.0.0 or later)
- A modern web browser
- A Stacks wallet (e.g., Hiro Wallet)

## Installation

1. Clone the repository
2. Navigate to the project directory
3. Install the dependencies:
4. Create a `.env` file in the root directory and add your contract details:

## Usage

1. Start the development server:
2. Open your web browser and visit `http://localhost:3000`
3. Connect your Stacks wallet to interact with the application

## Project Structure
src/
│
├── components/
│   ├── Connect.js
│   ├── ContractInfo.js
│   ├── UserActions.js
│   ├── AdminActions.js
│
├── contexts/
│   └── UserContext.js
│
├── utils/
│   └── constants.js
│
├── api/
│   └── contractInteractions.js
│
├── App.js
├── index.js
└── styles.css

## Contributing
Contributions to the STX Dividend Distribution Frontend are welcome. Please follow these steps:

Fork the repository
Create a new branch
Make your changes
Commit your changes
Push to the branch
Open a Pull Request

## Contact
Chukwudi Nwaneri Daniel or 
officialnwaneridaniel@gmail.com

## Acknowledgements

React
Stacks.js
Stacks Connect