// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "../../examples/BasicModularAccount.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EffiProxyFactory
 * @author soulwallet team
 * @notice A factory contract to create soul wallets
 * @dev This contract is called by the entrypoint which uses the "initCode" to create and return the sender's wallet address
 */
contract EffiProxyFactory is Ownable {
    address private immutable _WALLETIMPL;
    IEntryPoint public immutable entryPoint;
    string public constant VERSION = "0.0.1";

    /**
     * @dev Initializes the factory with the wallet implementation and entry point addresses
     * @param _walletImpl Address of the SoulWallet implementation
     * @param _entryPoint Address of the EntryPoint contract
     * @param _owner Address of the contract owner
     */
    constructor(address _walletImpl, address _entryPoint, address _owner) Ownable(_owner) {
        require(_walletImpl != address(0), "Invalid wallet implementation address");
        _WALLETIMPL = _walletImpl;
        require(_entryPoint != address(0), "Invalid entry point address");
        entryPoint = IEntryPoint(_entryPoint);
    }

    /**
     * @notice Returns the wallet implementation address
     * @return Address of the wallet implementation
     */
    function walletImpl() external view returns (address) {
        return _WALLETIMPL;
    }

    function _calcSalt(bytes memory _initializer, bytes32 _salt) private pure returns (bytes32 salt) {
        return keccak256(abi.encodePacked(keccak256(_initializer), _salt));
    }

    function getDeploymentData() private view returns (bytes memory) {
        // refer: https://github.com/jayden-sudo/EffiProxy

        return abi.encodePacked(
            hex"60518060225f395f73",
            _WALLETIMPL,
            hex"60165155f373ffffffffffffffffffffffffffffffffffffffff7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5416365f5f375f5f365f845af43d5f5f3e604d573d5ffd5b3d5ff3"
        );
    }

    /**
     * @dev Deploys the SoulWallet using a proxy and returns the proxy's address
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Address of the deployed proxy
     */
    function createWallet(bytes memory _initializer, bytes32 _salt) external returns (address proxy) {
        bytes memory deploymentData = getDeploymentData();
        bytes32 salt = _calcSalt(_initializer, _salt);
        assembly ("memory-safe") {
            proxy := create2(0x0, add(deploymentData, 0x20), mload(deploymentData), salt)
            if iszero(proxy) { revert(0, 0) }

            let succ := call(gas(), proxy, 0, add(_initializer, 0x20), mload(_initializer), 0, 0)
            if iszero(succ) { revert(0, 0) }
        }
    }

    /**
     * @notice Calculates the counterfactual address of the SoulWallet as it would be returned by `createWallet`
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Counterfactual address of the SoulWallet
     */
    function getWalletAddress(bytes memory _initializer, bytes32 _salt) external view returns (address proxy) {
        bytes memory deploymentData = getDeploymentData();
        bytes32 salt = _calcSalt(_initializer, _salt);
        proxy = Create2.computeAddress(salt, keccak256(deploymentData));
    }

    /**
     * @notice Deposits ETH to the entry point on behalf of the contract
     */
    function deposit() public payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /**
     * @notice Allows the owner to withdraw ETH from entrypoint contract
     * @param withdrawAddress Address to receive the withdrawn ETH
     * @param amount Amount of ETH to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /**
     * @notice Allows the owner to add stake to the entry point
     * @param unstakeDelaySec Duration (in seconds) after which the stake can be unlocked
     */
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }

    /**
     * @notice Allows the owner to unlock their stake from the entry point
     */
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /**
     * @notice Allows the owner to withdraw their stake from the entry point
     * @param withdrawAddress Address to receive the withdrawn stake
     */
    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }
}
