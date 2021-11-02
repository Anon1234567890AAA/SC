// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable RBK;
    address immutable _admin;
    bool public locked;

    constructor(IERC20 _RBK) {
        RBK = _RBK;
        _admin = msg.sender;
        locked = true;
    }

    // admin open a credit amount of this BEP20 to distribute
    mapping(address => uint256) _amountDeposit; // Amount admin have deposit
    mapping(address => uint256) _amountAllocated; // Amount he had allocated for users

    struct Vesting {
        uint256 firstClaimableAmount; // amount available at starting
        uint256 numberOfClaimLeft; // number of claim still left in vesting
        uint256 nextClaimTimestamp; // when user can claim
        uint256 monthlyClaimableAmount; // Amount per month claimable
    }

    mapping(address => Vesting) _myVesting;
    mapping(address => bool) _gotVesting;

    event NewVestingCreated(
        address indexed user,
        uint256 amount,
        uint256 amountAlreadyUnlocked,
        uint256 unlockBeginAt,
        uint256 endAtTimestamp
    );

    event NewClaim(address indexed user, uint256 amountClaimed);

    function unlock() external {
        require(msg.sender == _admin, "Only admin can unlock");
        locked = false;
    }

    // admin use this function to deposit RBK
    // can't be called by a contract
    function globalDepositForVesting(uint256 _amount) external {
        require(msg.sender == _admin, "Only admin");
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(RBK.transferFrom(msg.sender, address(this), _amount));
        _amountDeposit[msg.sender] = _amountDeposit[msg.sender].add(_amount);
    }

    // create a vesting for an user
    function createVesting(
        address _user, // address of user depositor want to create vesting
        uint256 _totalAmount, // amount for this address
        uint256 _startUnlockPercentage, // percentage unlocked at starting
        uint256 _unlockDuration // unlocking duration in month
    ) external {
        require(msg.sender == _admin, "Only admin");
        // check if depositor have enough credit
        require(
            _amountDeposit[msg.sender].sub(_amountAllocated[msg.sender]) >=
                _totalAmount,
            "You need to deposit amount before"
        );

        require(!_gotVesting[_user], "Only 1 vesting by address");
        // percentage can't be more than 100%
        require(_startUnlockPercentage <= 10000); // 10000 == 100,00 %

        //update credit of depositor
        _amountAllocated[msg.sender] = _amountAllocated[msg.sender].add(
            _totalAmount
        );

        _gotVesting[_user] = true;

        Vesting storage v = _myVesting[_user];
        uint256 _lockedAmount = _totalAmount;

        // managing unlock at starting
        if (_startUnlockPercentage != 0) {
            uint256 _available = (_totalAmount.mul(_startUnlockPercentage)).div(
                10000
            );
            v.firstClaimableAmount = _available;
            _lockedAmount = _lockedAmount.sub(_available);

            // init number of claim avalaible 1 per month plus starting claim
            v.numberOfClaimLeft = _unlockDuration.add(1);
        } else {
            // init number of claim avalaible 1 per month without starting claim
            v.numberOfClaimLeft = _unlockDuration;
        }

        //set Timestamp where unlock began
        if (_startUnlockPercentage != 0) {
            v.nextClaimTimestamp = block.timestamp;
        } else {
            v.nextClaimTimestamp = block.timestamp.add(30 days);
        }

        //set amount unlocked per Timestamp
        v.monthlyClaimableAmount = _lockedAmount.div(_unlockDuration);

        emit NewVestingCreated(
            _user,
            _totalAmount,
            v.firstClaimableAmount,
            v.nextClaimTimestamp,
            v.nextClaimTimestamp.add(v.numberOfClaimLeft.mul(30 days))
        );
    }

    // return vesting data
    function getMyVesting(address _user)
        external
        view
        returns (
            uint256 amountAtStart,
            uint256 claimLeft,
            uint256 nextClaimAtTimestamp,
            uint256 nextClaimAmount
        )
    {
        Vesting memory v = _myVesting[_user];
        return (
            v.firstClaimableAmount,
            v.numberOfClaimLeft,
            v.nextClaimTimestamp,
            v.monthlyClaimableAmount
        );
    }

    // return amount user can claim from locked token at the moment
    function claimable(address _user) external view returns (uint256 amount) {
        Vesting memory v = _myVesting[_user];

        uint256 _amount;

        // add starting amount available if necessary
        if (v.firstClaimableAmount > 0) {
            _amount = v.firstClaimableAmount;
        } else if (
            block.timestamp >= v.nextClaimTimestamp && v.numberOfClaimLeft > 0
        ) {
            _amount = v.monthlyClaimableAmount;
        }
        return _amount;
    }

    // claim tokens in vesting
    function claim() external returns (bool) {
        require(tx.origin == msg.sender, "Contracts not allowed.");
        require(_gotVesting[msg.sender], "You don't have vesting");
        require(!locked, "Vesting is not unlocked");
        Vesting storage v = _myVesting[msg.sender];

        // require used for reentrancy secure
        require(
            (block.timestamp >= v.nextClaimTimestamp &&
                v.numberOfClaimLeft > 0),
            "Nothing to claim"
        );
        uint256 _amount;
        // re entrancy secure for "v.numberOfClaimLeft > 0" condition
        _amount = v.firstClaimableAmount;
        v.firstClaimableAmount = 0;

        // re entrancy secure for "block.timestamp >= v.nextClaimTimestamp" condition
        // force next claim avalaible 1 month later
        v.nextClaimTimestamp = v.nextClaimTimestamp.add(30 days);

        // reduce number of claim avalaible
        v.numberOfClaimLeft = v.numberOfClaimLeft.sub(1);

        // If first claim has been done or there is no unlocked token at beginning
        if (_amount == 0) {
            // _amount is the monthly claimable
            _amount = v.monthlyClaimableAmount;
            if (v.numberOfClaimLeft == 0) {
                delete _myVesting[msg.sender];
                _gotVesting[msg.sender] = false;
            }
        }

        emit NewClaim(msg.sender, _amount);
        return RBK.transfer(msg.sender, _amount);
    }
}
