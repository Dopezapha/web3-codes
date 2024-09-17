### STX Blacklist Manager UI

## ABOUT

The STX Blacklist Manager UI is a React-based front-end application designed to interact with the STX Blacklist Manager smart contract on the Stacks blockchain. This application provides an intuitive interface for both administrators and users to manage and interact with the blacklist functionality.

## Features

Admin Panel:

Restrict/Unrestrict addresses
Update admin
Set transfer fees
Set fee recipients


User Panel:

Send STX tokens
Check if an address is restricted


Responsive design for desktop and mobile devices
Integration with Stacks authentication
Error handling and user feedback

Prerequisites
Before you begin, ensure you have met the following requirements:

Node.js (v14.0.0 or later)
npm (v6.0.0 or later)
A modern web browser
Access to the Stacks blockchain (testnet or mainnet)


## Usage
To run the application in development mode:

npm start
This will start the development server, and you can view the application by opening http://localhost:3000 in your web browser.
To build the application for production:

npm run build
This will create a build directory with optimized production-ready files.

## Project Structure
stx-blacklist-manager-ui/
├── public/
│   ├── index.html
│   └── favicon.ico
├── src/
│   ├── components/
│   │   ├── AdminPanel.js
│   │   ├── UserPanel.js
│   │   ├── Header.js
│   │   ├── ErrorBoundary.js
│   │   ├── Button.js
│   │   └── Input.js
│   ├── App.js
│   ├── index.js
│   ├── config.js
│   └── styles.css
├── .env
├── package.json
└── README.md

## Contributing
Contributions to the STX Blacklist Manager UI are welcome. Please follow these steps to contribute:

Fork the repository
Create a new branch
Make your changes
Commit your changes
Push to the branch
Open a Pull Request

## Author
Chukwudi Daniel Nwaneri

## Acknowledgements

React
Stacks.js
React Toastify