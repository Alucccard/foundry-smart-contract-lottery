// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    // mock chain constants

    uint256 public constant ANVIL_CHAIN_ID = 31337;
    uint96 public constant BASE_FEE = 0.1 ether; // base fee for the VRF mock
    uint96 public constant GAS_PRICE = 0.0001 ether; // gas price for
    int256 public constant WEI_PER_UNIT_LINK = 1e18; // 1 LINK = 1e18 wei

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig_InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator; //can aquire from link back-end
        bytes32 gaslane;
        uint256 subscriptionId; //can aquire from link back-end
        uint32 callbackGasLimit;
    }

    //this is for local network
    NetworkConfig public localNetworkConfig;

    //store chainID-configuration
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        // Initialize non-local network configurations, local network has its own function because it needs to create a mock
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        // networkConfigs[ANVIL_CHAIN_ID] = localNetworkConfig;
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID) {
            // return networkConfigs[ANVIL_CHAIN_ID];
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId(chainId);
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gaslane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 92492078371727254944539543705658626988845514966616106216020226643395527133283,
            callbackGasLimit: 50000
        });
    }

    //why would we need this?
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // create a mock VRFCoordinatorV2_5Mock
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.1 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            //this doesn't matter for local network
            gaslane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0, // subscription ID is not used in local network
            callbackGasLimit: 50000
        });

        return localNetworkConfig;
    }
}
