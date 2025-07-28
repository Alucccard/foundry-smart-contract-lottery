// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig_InvalidChainId(uint256 chainId)

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
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        // networkConfigs[ANVIL_CHAIN_ID] = localNetworkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        }
        else if{chainId == ANVIL_CHAIN_ID){
            // return networkConfigs[ANVIL_CHAIN_ID];
            return getOrCreatAnvilEthConfig();
        }
        else{
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
    function getOrCreateAnvilEthConfig() public return (Networkfig memory){
        if(localNetworkConfig.vrfCoodinator!= address(0)){
            return localNetworkConfig;
        }
    }
}
