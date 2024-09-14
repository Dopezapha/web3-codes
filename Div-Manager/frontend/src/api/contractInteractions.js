import { openContractCall } from '@stacks/connect';
import { StacksMainnet } from '@stacks/network';
import { callReadOnlyFunction, cvToValue } from '@stacks/transactions';
import { CONTRACT_ADDRESS, CONTRACT_NAME } from '../utils/constants';

const network = new StacksMainnet();

export const getPayoutsPerToken = async () => {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'get-payouts-per-token',
    functionArgs: [],
    network,
  });
  return cvToValue(result).value;
};

export const getContractHoldings = async () => {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'get-contract-holdings',
    functionArgs: [],
    network,
  });
  return cvToValue(result).value;
};

export const getClaimableSum = async (address) => {
  const result = await callReadOnlyFunction({
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'get-claimable-sum',
    functionArgs: [address],
    network,
  });
  return cvToValue(result).value;
};

export const updateHoldings = async () => {
  const options = {
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'update-holdings',
    functionArgs: [],
    network,
    onFinish: data => {
      console.log('Transaction:', data);
    },
  };
  await openContractCall(options);
};

export const claimPayouts = async () => {
  const options = {
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'claim-payouts',
    functionArgs: [],
    network,
    onFinish: data => {
      console.log('Transaction:', data);
    },
  };
  await openContractCall(options);
};

export const addPayouts = async (amount) => {
  const options = {
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'add-payouts',
    functionArgs: [amount],
    network,
    onFinish: data => {
      console.log('Transaction:', data);
    },
  };
  await openContractCall(options);
};

export const updateTokenSupply = async () => {
  const options = {
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'update-token-supply',
    functionArgs: [],
    network,
    onFinish: data => {
      console.log('Transaction:', data);
    },
  };
  await openContractCall(options);
};

export const withdrawUnclaimedPayouts = async () => {
  const options = {
    contractAddress: CONTRACT_ADDRESS,
    contractName: CONTRACT_NAME,
    functionName: 'withdraw-unclaimed-payouts',
    functionArgs: [],
    network,
    onFinish: data => {
      console.log('Transaction:', data);
    },
  };
  await openContractCall(options);
};
