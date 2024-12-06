const { ethers, parseEther, parseUnits } = require("ethers");
const { accIDs, amounts, lockdays, staketimes, unstaketimes } = require("./stakingArray.js");

console.log("_________________________________________________");
console.log("... accID.length ...", accIDs.length);
console.log("... amounts.length ...", amounts.length);
console.log("... time.length ...", lockdays.length);
console.log("... stake.length ...", staketimes.length);
console.log("... unstake.length ...", unstaketimes.length);
//console.log("... addresses.length ...", addresses.length);
console.log("_________________________________________________");


/// DATA to SET --
const RPC_URL = "https://mainnet-rpc.scai.network"    // SCAI mainnet
const WALLET_PK = '640278d2453a61ff9369d25483b55562992155f137069be720e53c124aec8789';  /// 0x3F87A32Bfd9cf18B63290B752EAb5A54653B45C5

/// scaiMiningStaking contract
const contractAddress = "0x70143cf9433D3C4e01e2EC78AaC816744e0c5822";

// upto here ---

// Contract ABI and address  -- if contract abi changes , dont forget to change this abi
//const MY_ABI = [{"inputs":[{"internalType":"uint256[]","name":"accountIdArray","type":"uint256[]"},{"internalType":"uint256[]","name":"stakingAmount","type":"uint256[]"},{"internalType":"enum scaiMiningStaking.LockingPeriod[]","name":"lockPeriodArray","type":"uint8[]"},{"internalType":"uint256[]","name":"stakeStartTimeArray","type":"uint256[]"},{"internalType":"uint256[]","name":"stakeEndTimeArray","type":"uint256[]"},{"internalType":"address[]","name":"userAddressArray","type":"address[]"}],"name":"LoadStakingData","outputs":[],"stateMutability":"nonpayable","type":"function"}];

	const MY_ABI =  [{"inputs":[{"internalType":"uint256[]","name":"accountIdArray","type":"uint256[]"},{"internalType":"uint256[]","name":"stakingAmount","type":"uint256[]"},{"internalType":"enum scaiMiningStaking.LockingPeriod[]","name":"lockPeriodArray","type":"uint8[]"},{"internalType":"uint256[]","name":"stakeStartTimeArray","type":"uint256[]"},{"internalType":"uint256[]","name":"stakeEndTimeArray","type":"uint256[]"}],"name":"LoadStakingData","outputs":[],"stateMutability":"nonpayable","type":"function"}]
async function callContractFunction(accountIdArray, stakingAmount, lockPeriodArray, stakeStartTimeArray, stakeEndTimeArray) {
    const provider = new ethers.JsonRpcProvider(RPC_URL, 34);
    const wallet = new ethers.Wallet(WALLET_PK, provider);

    const contract = new ethers.Contract(contractAddress, MY_ABI, wallet);

    // Call the contract function with the arrays
    try {
		const functionName = "LoadStakingData";
		const functionArgs = [accountIdArray, stakingAmount, lockPeriodArray, stakeStartTimeArray, stakeEndTimeArray]; // Arguments for the function
		const txData = contract.interface.encodeFunctionData(functionName, functionArgs);

		const nonce = await provider.getTransactionCount(wallet.address);

		const gasFeeData = await provider.getFeeData();
	    const gasPrice = gasFeeData.gasPrice;

		console.log("... gasPrice ...", gasPrice);
		//const network = await provider.getNetwork();
		//console.log(".. network ..", network);

		const tx = {
			to: contractAddress,
			data: txData,
			gasLimit: 75000000,
			gasPrice: gasPrice,
			nonce: nonce,
			value: 0
        };

		//console.log(".. tx ...", tx);
		const signedTx = await wallet.signTransaction(tx);
		console.log(".. signedTx ..", signedTx);

		const txResponse = await wallet.sendTransaction(tx);

		console.log("Transaction sent! Tx hash:", txResponse.hash);

		const receipt = await txResponse.wait();
        console.log("Transaction confirmed! Receipt:", receipt);
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}


/// accID, amounts, time, stake, unstake, addresses
let startIndex = 0;  // Start from the first element
let numberOfElementsToRemove = 10;
let counter =0;
// Function to splice 10 elements at a time every 50 seconds
const spliceInterval = setInterval(() => {
	  if (accIDs.length > startIndex && counter <=2 ) {
		  	(async()=>{
					const removedaccID = accIDs.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					let removedAmounts1 = amounts.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					let removedAmounts2 = removedAmounts1.map(element => parseEther(element.toString()) );
					let removedAmounts = removedAmounts2.map(element => `${element.toString()}`);
					const removedTime = lockdays.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					const removedStake = staketimes.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					const removedUnstake = unstaketimes.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					//const removedAddresses = addresses.splice(startIndex, numberOfElementsToRemove); // Remove 10 elements starting from current index
					console.log("________________________");
					console.log('removedaccID -Removed elements:', removedaccID);
					//console.log('removedAmounts -Removed elements:', removedAmounts);
					//console.log('removedTime -Removed elements:', removedTime);
					//console.log('removedStake -Removed elements:', removedStake);
					//console.log('removedUnstake -Removed elements:', removedUnstake);
					//console.log('removedAddresses -Removed elements:', removedAddresses);
					console.log("________________________>>>");
					console.log('accID - Remaining array length:', accIDs.length);
					//console.log('amounts - Remaining array length:', amounts.length);
					//console.log('time - Remaining array length:', time.length);
					//console.log('stake - Remaining array length:', stake.length);
					//console.log('unstake - Remaining array length:', unstake.length);
					//console.log('addresses - Remaining array length:', addresses.length);
					console.log("________________________");
									    /// (accountIdArray, stakingAmount, lockPeriodArray, stakeStartTimeArray, stakeEndTimeArray, userAddressArray)
					await callContractFunction(removedaccID, removedAmounts, removedTime, removedStake, removedUnstake);
					//startIndex += 10; // Move the index forward by 10 to process the next set
					counter ++;
					startIndex += numberOfElementsToRemove;
					 
			})();
	  } else {
			// Stop the interval when there are no more elements left to splice
			clearInterval(spliceInterval);
			console.log('Finished processing all elements.');
	  }
}, 50000);  // 50,000 milliseconds = 50 seconds
