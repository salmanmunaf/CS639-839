const Web3 = require('web3');
const contract = require('./contract.json');

// Connect to the Goerli testnet
const provider = new Web3.providers.HttpProvider(`https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`);
const web3 = new Web3(provider);

// Create an instance of your contract
const myContract = new web3.eth.Contract(contract.abi);

// Deploy the contract
myContract.deploy({
  data: contract.bytecode,
  arguments: [20] // Set the bidding time accordingly
})
.send({
  from: process.env.WALLET_ADDRESS,
  gas: '900000',
  gasPrice: web3.utils.toWei('20', 'gwei') // Set a gas price to ensure timely processing of the transaction
})
.on('receipt', (receipt) => {
  console.log('Contract deployed at:', receipt.contractAddress);
})
.on('error', (error) => {
  console.error('Error deploying contract:', error);
});