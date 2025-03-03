# Node Management Commands
This document contains useful commands for managing your PulseChain or Ethereum node.

### Pruning DB with Execution Client
###### Note: Adjust the /blockchain part of the command to your setup

#### PulseChain
```bash
# Using go-pulse
sudo docker stop -t 300 execution && sudo docker container prune -f

sudo docker run --rm --name geth_prune -it -v /home/blockchain/execution/geth:/geth \
registry.gitlab.com/pulsechaincom/go-pulse:latest \
snapshot prune-state \
--datadir /geth
```

#### Ethereum
```bash
# Using go-ethereum
sudo docker stop -t 300 execution && sudo docker container prune -f

sudo docker run --rm --name geth_prune -it -v /home/blockchain/execution/geth:/geth \
ethereum/client-go:latest \
snapshot prune-state \
--datadir /geth
```

### Show Version

#### Consensus Client Versions

##### Prysm
###### Beacon
```bash
docker exec -it beacon /app/cmd/beacon-chain/beacon-chain --version
```

###### Validator
```bash
docker exec -it validator /app/cmd/validator/validator --version
```

##### Lighthouse
###### Beacon & Validator
```bash
curl -X GET "http://localhost:5052/eth/v1/node/version" -H 'accept: application/json' | jq
```

#### Execution Client Version

##### PulseChain (go-pulse)
```bash
docker exec -it execution geth version
```

##### Ethereum (go-ethereum)
```bash
docker exec -it execution geth version
```

### List Validator Keys

#### PulseChain
```bash
docker run --rm -it -v "/blockchain/wallet:/wallet" \
registry.gitlab.com/pulsechaincom/prysm-pulse/validator:latest \
accounts list --pulsechain --wallet-dir=/wallet --wallet-password-file=/wallet/pw.txt
```

#### Ethereum
```bash
docker run --rm -it -v "/blockchain/wallet:/wallet" \
prysmaticlabs/prysm-validator:latest \
accounts list --mainnet --wallet-dir=/wallet --wallet-password-file=/wallet/pw.txt
```

### Get Validator Info from Local Beacon
###### Note: Replace YOUR_VALIDATOR_INDEX with the index from beacon explorer (e.g., 7654)

#### Prysm
```bash
curl -X 'GET' \
'http://127.0.0.1:3500/eth/v1/beacon/states/head/validators/YOUR_VALIDATOR_INDEX' \
-H 'accept: application/json'
```

#### Lighthouse
```bash
curl -X 'GET' \
'http://127.0.0.1:5052/eth/v1/beacon/states/head/validators/YOUR_VALIDATOR_INDEX' \
-H 'accept: application/json'
```

### Submit BLS to Execution Change
###### Note: @filename is the JSON generated from the BLS to execution conversion via staking-cli

#### Prysm
```bash
curl -X 'POST' \
'localhost:3500/eth/v1/beacon/pool/bls_to_execution_changes' \
-H 'accept: */*' \
-H 'Content-Type: application/json' \
-d @filename.json
```

#### Lighthouse
```bash
curl -X 'POST' \
'localhost:5052/eth/v1/beacon/pool/bls_to_execution_changes' \
-H 'accept: */*' \
-H 'Content-Type: application/json' \
-d @filename.json
```
