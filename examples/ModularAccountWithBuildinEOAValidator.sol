// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SoulWalletCore} from "../contracts/SoulWalletCore.sol";
import {BuildinEOAValidator} from "../contracts/validators/BuildinEOAValidator.sol";

contract ModularAccountWithBuildinEOAValidator is SoulWalletCore, BuildinEOAValidator {
    uint256 private _initialized;

    modifier initializer() {
        require(_initialized == 0);
        _initialized = 1;
        _;
    }

    constructor(address _entryPoint) SoulWalletCore(_entryPoint) initializer {}

    function initialize(bytes32 owner) external initializer {
        _addOwner(owner);
    }

    /**
     * @dev checks whether a address is a installed validator
     */
    function _isInstalledValidator(address validator) internal view override returns (bool) {
        return validator == address(this) || super._isInstalledValidator(validator);
    }

    /**
     * @dev If you need to redefine the signatures structure, please override this function.
     */
    function _decodeSignature(bytes calldata signature)
        internal
        view
        override
        returns (address validator, bytes calldata validatorSignature, bytes calldata hookSignature)
    {
        (validator, validatorSignature, hookSignature) = super._decodeSignature(signature);
        if (validator == address(0)) {
            validator = address(this);
        }
    }
}