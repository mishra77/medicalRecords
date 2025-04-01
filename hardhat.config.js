require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config(); // Load environment variables

const { API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

// Ensure all required values are set
if (!API_URL || !PRIVATE_KEY || !ETHERSCAN_API_KEY) {
  throw new Error("❌ Missing environment variables. Check your .env file.");
}

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    sepolia: {
      url: API_URL,
      accounts: [PRIVATE_KEY],
    },
  },

  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
