//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Directive {
  DELEGATE,
  UNDELEGATE,
  COLLECT_REWARDS
}

abstract contract StakingPrecompilesSelectors {
  function Delegate(address delegatorAddress,
                    address validatorAddress,
                    uint256 amount) public virtual;
  function Undelegate(address delegatorAddress,
                      address validatorAddress,
                      uint256 amount) public virtual;
  function CollectRewards(address delegatorAddress) public virtual;
  function Migrate(address from, address to) public virtual;
}

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

contract StakingPrecompilesDelegatecall is Context {
  function delegate(address validatorAddress, uint256 amount) internal returns (uint256 result) {
    bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.Delegate.selector,
                                    _msgSender(),
                                    validatorAddress,
                                    amount);
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := delegatecall(25000,
        0xfc,

        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
  }

  function undelegate(address validatorAddress, uint256 amount) internal returns (uint256 result) {
    bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.Undelegate.selector,
                                    _msgSender(),
                                    validatorAddress,
                                    amount);
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := delegatecall(25000,
        0xfc,

        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
  }

  function collectRewards() internal returns (uint256 result) {
    bytes memory encodedInput = abi.encodeWithSelector(StakingPrecompilesSelectors.CollectRewards.selector,
                                    _msgSender());
    assembly {
      // we estimate a gas consumption of 25k per precompile
      result := delegatecall(25000,
        0xfc,

        add(encodedInput, 32),
        mload(encodedInput),
        mload(0x40),
        0x20
      )
    }
  }
}

contract bPStaking is StakingPrecompilesDelegatecall {

    event StakingPrecompileCalled(uint8 directive, bool success);

    struct Delegation {
        address validator;
        uint256 amount;
    }

    struct Undelegation {
        address validator;
        uint256 amount;
    }

    function bPDelegate(address validatorAddress, uint256 amount) public returns (bool success) {
        uint256 result = delegate(validatorAddress, amount);
        success = result != 0;
        emit StakingPrecompileCalled(uint8(Directive.DELEGATE), success);
    }

    function bPUndelegate(address validatorAddress, uint256 amount) public returns (bool success) {
        uint256 result = undelegate(validatorAddress, amount);
        success = result != 0;
        emit StakingPrecompileCalled(uint8(Directive.UNDELEGATE), success);
    }

    function bPCollectRewards() public returns (bool success) {
        uint256 result = collectRewards();
        success = result != 0;
        emit StakingPrecompileCalled(uint8(Directive.COLLECT_REWARDS), success);
    }
    function bPMultiDelegate(Delegation[] memory delegations) public returns (bool success) {
        success = true;
        uint256 length = delegations.length;
        Delegation memory delegation;
        for(uint256 i = 0; i < length; i ++) {
            delegation = delegations[i];
            uint256 result = delegate(delegation.validator, delegation.amount);
            success = result != 0;
        }
        emit StakingPrecompileCalled(uint8(Directive.DELEGATE), success);
    }
    // Undelegate to an array of undelegations
    function bPMultiUndelegate(Undelegation[] memory undelegations) public returns (bool success) {
        success = true;
        uint256 length = undelegations.length;
        Undelegation memory undelegation;
        for(uint256 i = 0; i < length; i ++) {
            undelegation = undelegations[i];
            uint256 result = undelegate(undelegation.validator, undelegation.amount);
            success = result != 0;
        }
        emit StakingPrecompileCalled(uint8(Directive.UNDELEGATE), success);

    }
}
