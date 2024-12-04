// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import 'hardhat/console.sol';
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function decimal() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 

/**
 * @dev Staking Contract 
 *   - Stake xyz Token for X number of days  
 *   - Add penelty function also 
 */
contract scaiMiningStaking is Ownable,  ReentrancyGuard {

 
    //events
    event Withdraw(address validator,uint256 indx, uint256 amount, uint256 timestamp);
    event WithdrawProfit(address validator,uint256 indx, uint256 amount, uint256 timestamp);
    event StakeCreated(address user, uint256 amount, uint256 index);
    event StakeUpdated(address user, uint256 amount, uint256 index);
   
    // Locing periods , 30/90/180/365 days
    enum LockingPeriod {
        Days30,
        Days90,
        Days180,
        Days365
    }

    uint256 public totalStakers;
    uint256 public totalStakeAmount;

    struct UserStake {
        uint256 accountId;
        uint256 amount;
        LockingPeriod duration;
        uint256 interestRate;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
    }

    // Monthly interest:  in %
    uint[] private interestRates = [15,25,35,45]; 
     
    // stakes that the owner have    
    mapping(address => UserStake[]) public stakeInfo;
    mapping(address => bool) public managerList;

    modifier onlyManager() {
        require(managerList[msg.sender], "You are not manager");
        _;
    }

    receive() external payable {}
    fallback() external payable {}
 
   
    //------------------ Constructor ------------------

    constructor() {
         managerList[msg.sender] = true;
    }

    //============= Setter Functions ====================

    function setInterestRates(uint[] memory rates) public  onlyOwner{
        require(rates.length == 3, "Please pass in an array of 3 values.");
        interestRates = rates;
    }

    function setManager(address _user, bool isManager) public  onlyOwner{
        managerList[_user] = isManager;
    }

  
    //============= External Functions ====================

    function Stake(LockingPeriod lockduration) external payable nonReentrant   
    {   
        uint256 amount = msg.value;
        require(amount >0, "Invalid amount");
           
        UserStake memory newUser = UserStake(
            0,
            amount,
            lockduration,
            interestRates[uint(lockduration)],
            block.timestamp,
            0
        );

        stakeInfo[msg.sender].push(newUser);
        totalStakers += 1;
        totalStakeAmount = totalStakeAmount + amount;

        emit StakeCreated(msg.sender, amount, stakeInfo[msg.sender].length - 1);
    }

    function WithdrawStake(uint256  arrayIndex) external nonReentrant returns (bool)
    {
        address staker = msg.sender;

        // Stake should exists and opened
        require( stakeInfo[staker].length >arrayIndex , "Stake does not exist");
        UserStake storage stakedata = stakeInfo[staker][arrayIndex];
        require(stakedata.endTimeStamp < block.timestamp, "This stake is closed");
        uint256 unstakeAmount = stakedata.amount;
        require(unstakeAmount > 0, "You don't have any stake");

        uint256 secondInDays = CalculateSecondsInDays(stakedata.duration) ;
        uint256 endTimeStamp = secondInDays + stakedata.startTimeStamp;
        require(block.timestamp > endTimeStamp, "Stake is still active");
        require(endTimeStamp > 0, "This stake is closed");
        
        uint256 rewardsOfStake = unstakeAmount * stakedata.interestRate / 100;
        // check contract coin balace
        require( address(this).balance >= stakedata.amount , "Insufficient contract balance");
        // transfer the coins from the contract itself
        payable(msg.sender).transfer(unstakeAmount + rewardsOfStake);
        stakedata.endTimeStamp = block.timestamp;
        rewardsOfStake=0;
  
        stakedata.amount = stakedata.amount - (unstakeAmount);
        totalStakeAmount = totalStakeAmount - (unstakeAmount);

        totalStakers -= 1;
        
        emit Withdraw(staker, arrayIndex, unstakeAmount, block.timestamp);
        return true;
    }

    
    function EditStake(uint256 inx, address _user, uint256 amt,LockingPeriod lockduration,  uint256 starttime,uint256 endtime) external onlyOwner
    {   

        UserStake storage stakedata = stakeInfo[_user][inx];

        stakedata.amount = amt;
        stakedata.duration =  lockduration;
        stakedata.interestRate = interestRates[uint(lockduration)];
        stakedata.startTimeStamp =starttime;
        stakedata.endTimeStamp =endtime;

        emit StakeUpdated(msg.sender, amt, stakeInfo[msg.sender].length - 1);
    }
    
    function CalculateSecondsInDays(LockingPeriod duration) public pure returns(uint256){

        uint32 lockdays;
        if(duration == LockingPeriod.Days30)
        {
            lockdays =30;
        }
        else if(duration == LockingPeriod.Days90)
        {
            lockdays =90;
        }
        else if(duration == LockingPeriod.Days180)
        {
            lockdays =180;
        }
        else if(duration == LockingPeriod.Days365)
        {            
            lockdays =365;
        }

        return  60 * 60 * 24* lockdays;
    }

    function rescueCoins() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function LoadStakingData(  uint256[] memory accountIdArray,uint256[] memory stakingAmount, 
    LockingPeriod[] memory lockPeriodArray, uint256[] memory stakeStartTimeArray, 
    uint256[] memory stakeEndTimeArray,address[]  memory userAddressArray) public onlyManager
    {
        for (uint i=0; i<accountIdArray.length; i++) { // unbounded loop DoS warning
             address stakingUser = userAddressArray[i];
            
             UserStake memory newUser = UserStake(
                accountIdArray[i],
                stakingAmount[i],
                lockPeriodArray[i],
                interestRates[uint(lockPeriodArray[i])],
                stakeStartTimeArray[i],
                stakeEndTimeArray[i]
            );

            stakeInfo[stakingUser].push(newUser);
        }
    }

}

