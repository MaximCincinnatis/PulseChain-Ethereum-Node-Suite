# PulseChain Node Setup (Non-Validator Version)

This is a modified version of the PulseChain Node Setup scripts with all validator functionality removed. This version allows you to run a PulseChain node for syncing with the network, providing RPC endpoints, and monitoring the blockchain, but does not include any validator staking capabilities.

## What Has Been Removed

The following validator-related components have been removed from the original setup:

1. `setup_validator.sh` - The main validator setup script
2. `setup_offline_keygen.sh` - Script for offline key generation
3. Validator-related helper scripts:
   - `key_mgmt.sh` - Validator key management
   - `exit_validator.sh` - Validator exit functionality
   - `emergency_exit.sh` - Emergency validator exit
   - `lh_batch_exit.sh` - Batch validator exit for Lighthouse
   - `prysm_delete_validator.sh` - Delete validator for Prysm
   - `prysm_fix.sh` - Prysm validator fixes
   - `prysm_read_accounts.sh` - Read Prysm validator accounts

4. Validator-related functions in `functions.sh`
5. Validator-related menu entries in helper scripts

## What Remains Functional

This version maintains all the functionality needed to run a non-validating PulseChain node:

1. Execution client setup (Geth or Erigon)
2. Consensus client setup (Lighthouse or Prysm)
3. Monitoring setup (Prometheus and Grafana)
4. Node management tools and scripts
5. System configuration and firewall setup
6. Logging and status monitoring

## Usage

The usage of this non-validator version is similar to the original, but without the validator setup options:

1. Run `./setup_pulse_node.sh` to set up your PulseChain node
2. Follow the prompts to configure your execution and consensus clients
3. Use the helper scripts in the `helper` directory for node management
4. Run `./setup_monitoring.sh` to set up monitoring with Prometheus and Grafana

## Why Use This Version?

This version is ideal for users who want to:

1. Run a PulseChain node without staking
2. Provide RPC endpoints for applications
3. Monitor the PulseChain network
4. Support the network by running a node without the complexity of validator management

## Note

If you need validator functionality in the future, please use the original version of these scripts.

## Credits

This is a modified version of the original PulseChain node setup scripts. All credit for the original code goes to the original authors.

## Disclaimer

This software is provided as-is without any warranty. Use at your own risk. This is NOT the official PulseChain repository - it's a modified version with specific functionality removed. 