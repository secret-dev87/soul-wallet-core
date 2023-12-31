// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SoulWalletCore} from "../contracts/SoulWalletCore.sol";

contract BasicModularAccount is SoulWalletCore {
    uint256 private _initialized;

    modifier initializer() {
        require(_initialized == 0);
        _initialized = 1;
        _;
    }

    constructor(address _entryPoint) SoulWalletCore(_entryPoint) initializer {}

    function initialize(bytes32 owner, address validator, address defaultFallback, address[] calldata modules)
        external
        initializer
    {
        _addOwner(owner);
        _installValidator(validator);
        _setFallbackHandler(defaultFallback);
        for (uint256 i = 0; i < modules.length; i++) {
            _installModule(modules[i]);
        }
    }

    /**
     * Only authorized modules can manage hooks and modules.
     */
    function pluginManagementAccess() internal view override {
        _onlyModule();
    }
}
