#!/bin/bash

# Indexing Support Script for PulseChain Archive Node
# This script helps configure and optimize the node for external indexing

VERSION="1.0"
CUSTOM_PATH=${CUSTOM_PATH:-"/blockchain"}

# Function to optimize Erigon for indexing
optimize_for_indexing() {
    clear
    echo "Optimize Erigon for Indexing"
    echo "==========================="
    echo ""
    
    echo "This will modify your start_execution.sh script to optimize Erigon for indexing."
    echo "Current configuration:"
    grep -E 'torrent.download.rate|cache|maxpeers|db.size.limit' "${CUSTOM_PATH}/start_execution.sh"
    echo ""
    
    read -p "Do you want to continue? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Backup the original file
    cp "${CUSTOM_PATH}/start_execution.sh" "${CUSTOM_PATH}/start_execution.sh.bak"
    
    # Get system memory information
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    
    # Calculate recommended cache size (50% of total memory)
    recommended_cache=$((total_mem * 1024 / 2))
    
    echo ""
    echo "System memory: ${total_mem}GB"
    echo "Recommended cache size: ${recommended_cache}MB"
    echo ""
    
    read -p "Enter cache size in MB (default: ${recommended_cache}): " cache_size
    cache_size=${cache_size:-$recommended_cache}
    
    # Update cache size
    sed -i "s/--cache [0-9]*/--cache ${cache_size}/g" "${CUSTOM_PATH}/start_execution.sh"
    
    # Update download rate for faster sync
    read -p "Enter torrent download rate in KB/s (default: 1024000): " download_rate
    download_rate=${download_rate:-1024000}
    sed -i "s/--torrent.download.rate [0-9]*/--torrent.download.rate ${download_rate}/g" "${CUSTOM_PATH}/start_execution.sh"
    
    # Update max peers for better connectivity
    read -p "Enter maximum number of peers (default: 100): " max_peers
    max_peers=${max_peers:-100}
    sed -i "s/--maxpeers [0-9]*/--maxpeers ${max_peers}/g" "${CUSTOM_PATH}/start_execution.sh"
    
    # Ensure trace API is enabled for indexing
    if ! grep -q "trace" <(grep -E 'http.api' "${CUSTOM_PATH}/start_execution.sh"); then
        current_http_api=$(grep -E 'http.api' "${CUSTOM_PATH}/start_execution.sh" | grep -oP '(?<=http.api=")[^"]*')
        new_http_api="${current_http_api},trace"
        sed -i "s/--http.api=\"[^\"]*\"/--http.api=\"${new_http_api}\"/g" "${CUSTOM_PATH}/start_execution.sh"
    fi
    
    if ! grep -q "trace" <(grep -E 'ws.api' "${CUSTOM_PATH}/start_execution.sh"); then
        current_ws_api=$(grep -E 'ws.api' "${CUSTOM_PATH}/start_execution.sh" | grep -oP '(?<=ws.api=")[^"]*')
        new_ws_api="${current_ws_api},trace"
        sed -i "s/--ws.api=\"[^\"]*\"/--ws.api=\"${new_ws_api}\"/g" "${CUSTOM_PATH}/start_execution.sh"
    fi
    
    echo ""
    echo "Erigon has been optimized for indexing!"
    echo "You'll need to restart the execution client for changes to take effect."
    echo ""
    read -p "Do you want to restart the execution client now? (y/n): " restart_now
    if [[ "$restart_now" == "y" ]]; then
        echo "Restarting execution client..."
        sudo docker stop -t 300 execution
        sleep 1
        sudo docker container prune -f
        ${CUSTOM_PATH}/start_execution.sh
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to configure indexer connection
configure_indexer_connection() {
    clear
    echo "Configure Indexer Connection"
    echo "==========================="
    echo ""
    
    echo "This will help you set up the connection between your node and the indexing machine."
    echo ""
    
    # Get indexer machine IP
    read -p "Enter the IP address of the indexing machine: " indexer_ip
    
    if [[ -z "$indexer_ip" ]]; then
        echo "No IP address entered. Returning to menu."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Validate IP address format
    if ! [[ $indexer_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format. Please use format: xxx.xxx.xxx.xxx"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if firewall rule already exists
    if sudo ufw status | grep -q "$indexer_ip"; then
        echo "Firewall rule for $indexer_ip already exists."
    else
        # Add firewall rules for indexer
        echo "Adding firewall rules for $indexer_ip..."
        sudo ufw allow from $indexer_ip to any port 8545 proto tcp comment "RPC access for indexer"
        sudo ufw allow from $indexer_ip to any port 8546 proto tcp comment "WebSocket access for indexer"
        echo "Firewall rules added successfully!"
    fi
    
    # Create indexer configuration file
    echo "Creating indexer configuration file..."
    
    # Get the server's IP address
    server_ip=$(hostname -I | awk '{print $1}')
    
    # Create directory if it doesn't exist
    sudo mkdir -p "${CUSTOM_PATH}/ai_indexing"
    
    # Create the configuration file
    cat > indexer_config.json << EOL
{
  "node": {
    "url": "http://${server_ip}:8545",
    "ws_url": "ws://${server_ip}:8546"
  },
  "indexing": {
    "start_block": 0,
    "batch_size": 1000,
    "concurrency": 5
  },
  "database": {
    "type": "postgresql",
    "connection_string": "postgresql://username:password@localhost:5432/blockchain_index"
  },
  "api": {
    "port": 3001,
    "host": "0.0.0.0",
    "rate_limit": 100
  }
}
EOL
    
    sudo mv indexer_config.json "${CUSTOM_PATH}/ai_indexing/"
    sudo chown $(whoami):docker "${CUSTOM_PATH}/ai_indexing/indexer_config.json"
    
    echo ""
    echo "Indexer configuration file created at ${CUSTOM_PATH}/ai_indexing/indexer_config.json"
    echo "Please copy this file to your indexing machine."
    echo ""
    echo "Instructions for the indexing machine:"
    echo "1. Install an indexing software that supports Ethereum JSON-RPC"
    echo "2. Configure it to connect to this node at http://${server_ip}:8545"
    echo "3. Use the WebSocket endpoint at ws://${server_ip}:8546 for real-time updates"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to monitor indexing performance
monitor_indexing_performance() {
    clear
    echo "Monitor Indexing Performance"
    echo "==========================="
    echo ""
    
    echo "This will help you monitor the performance of your node for indexing."
    echo ""
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y curl
    fi
    
    # Get current block number
    echo "Getting current block number..."
    current_block=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 | grep -oP '(?<="result":")[^"]*' | sed 's/0x//')
    
    if [[ -z "$current_block" ]]; then
        echo "Failed to get current block number. Make sure the execution client is running."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Convert hex to decimal
    current_block=$((16#$current_block))
    
    echo "Current block number: $current_block"
    echo ""
    
    # Get system resource usage
    echo "System resource usage:"
    echo "======================"
    echo ""
    
    # CPU usage
    echo "CPU usage:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
    
    # Memory usage
    echo ""
    echo "Memory usage:"
    free -h
    
    # Disk usage
    echo ""
    echo "Disk usage:"
    df -h | grep -E "$(df . | tail -1 | awk '{print $1}')|Filesystem"
    
    # Docker stats
    echo ""
    echo "Docker container stats:"
    sudo docker stats --no-stream execution
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to create sample indexer code
create_sample_indexer() {
    clear
    echo "Create Sample Indexer Code"
    echo "========================="
    echo ""
    
    echo "This will create a sample Node.js indexer script that you can use on your indexing machine."
    echo ""
    
    # Create directory if it doesn't exist
    sudo mkdir -p "${CUSTOM_PATH}/ai_indexing/sample_code"
    
    # Get the server's IP address
    server_ip=$(hostname -I | awk '{print $1}')
    
    # Create the sample indexer script
    cat > sample_indexer.js << EOL
/**
 * Sample PulseChain Indexer
 * 
 * This is a basic example of how to index blocks and transactions from a PulseChain node.
 * To use this script:
 * 1. Install Node.js on your indexing machine
 * 2. Install required packages: npm install web3 pg
 * 3. Configure the PostgreSQL database
 * 4. Run the script: node sample_indexer.js
 */

const Web3 = require('web3');
const { Pool } = require('pg');

// Configuration
const config = {
  node: {
    url: 'http://${server_ip}:8545',
    wsUrl: 'ws://${server_ip}:8546'
  },
  database: {
    host: 'localhost',
    port: 5432,
    database: 'blockchain_index',
    user: 'username',
    password: 'password'
  },
  indexing: {
    startBlock: 0,
    batchSize: 100,
    concurrency: 2
  }
};

// Initialize Web3
const web3 = new Web3(config.node.url);
const web3Ws = new Web3(config.node.wsUrl);

// Initialize PostgreSQL
const pool = new Pool(config.database);

// Create tables if they don't exist
async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query(\`
      CREATE TABLE IF NOT EXISTS blocks (
        number BIGINT PRIMARY KEY,
        hash VARCHAR(66) NOT NULL,
        parent_hash VARCHAR(66) NOT NULL,
        timestamp BIGINT NOT NULL,
        miner VARCHAR(42) NOT NULL,
        difficulty NUMERIC,
        total_difficulty NUMERIC,
        size BIGINT,
        gas_used BIGINT,
        gas_limit BIGINT,
        transaction_count INT
      )
    \`);
    
    await client.query(\`
      CREATE TABLE IF NOT EXISTS transactions (
        hash VARCHAR(66) PRIMARY KEY,
        block_number BIGINT REFERENCES blocks(number),
        from_address VARCHAR(42) NOT NULL,
        to_address VARCHAR(42),
        value NUMERIC,
        gas BIGINT,
        gas_price NUMERIC,
        nonce BIGINT,
        input TEXT,
        transaction_index INT,
        status BOOLEAN
      )
    \`);
    
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
  } finally {
    client.release();
  }
}

// Get the latest indexed block
async function getLatestIndexedBlock() {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT MAX(number) as max_block FROM blocks');
    return result.rows[0].max_block || config.indexing.startBlock - 1;
  } catch (error) {
    console.error('Error getting latest indexed block:', error);
    return config.indexing.startBlock - 1;
  } finally {
    client.release();
  }
}

// Index a single block
async function indexBlock(blockNumber) {
  const client = await pool.connect();
  try {
    // Get block data
    const block = await web3.eth.getBlock(blockNumber, true);
    if (!block) {
      console.error(\`Block \${blockNumber} not found\`);
      return;
    }
    
    // Start transaction
    await client.query('BEGIN');
    
    // Insert block data
    await client.query(\`
      INSERT INTO blocks (
        number, hash, parent_hash, timestamp, miner, 
        difficulty, total_difficulty, size, gas_used, gas_limit, transaction_count
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (number) DO NOTHING
    \`, [
      block.number,
      block.hash,
      block.parentHash,
      block.timestamp,
      block.miner,
      block.difficulty.toString(),
      block.totalDifficulty.toString(),
      block.size,
      block.gasUsed,
      block.gasLimit,
      block.transactions.length
    ]);
    
    // Insert transaction data
    for (const tx of block.transactions) {
      const receipt = await web3.eth.getTransactionReceipt(tx.hash);
      
      await client.query(\`
        INSERT INTO transactions (
          hash, block_number, from_address, to_address, value, 
          gas, gas_price, nonce, input, transaction_index, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (hash) DO NOTHING
      \`, [
        tx.hash,
        tx.blockNumber,
        tx.from,
        tx.to,
        tx.value.toString(),
        tx.gas,
        tx.gasPrice.toString(),
        tx.nonce,
        tx.input,
        tx.transactionIndex,
        receipt ? receipt.status : null
      ]);
    }
    
    // Commit transaction
    await client.query('COMMIT');
    
    console.log(\`Indexed block \${blockNumber} with \${block.transactions.length} transactions\`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error(\`Error indexing block \${blockNumber}:\`, error);
  } finally {
    client.release();
  }
}

// Index blocks in batches
async function indexBlocks() {
  try {
    const latestIndexedBlock = await getLatestIndexedBlock();
    const currentBlock = await web3.eth.getBlockNumber();
    
    console.log(\`Starting indexing from block \${latestIndexedBlock + 1} to \${currentBlock}\`);
    
    for (let i = latestIndexedBlock + 1; i <= currentBlock; i += config.indexing.batchSize) {
      const endBlock = Math.min(i + config.indexing.batchSize - 1, currentBlock);
      
      // Create an array of promises for concurrent indexing
      const promises = [];
      for (let j = i; j <= endBlock; j++) {
        if (promises.length >= config.indexing.concurrency) {
          await Promise.all(promises);
          promises.length = 0;
        }
        promises.push(indexBlock(j));
      }
      
      // Wait for remaining promises
      if (promises.length > 0) {
        await Promise.all(promises);
      }
      
      console.log(\`Indexed blocks \${i} to \${endBlock}\`);
    }
    
    console.log('Indexing completed');
  } catch (error) {
    console.error('Error during indexing:', error);
  }
}

// Subscribe to new blocks for real-time indexing
function subscribeToNewBlocks() {
  const subscription = web3Ws.eth.subscribe('newBlockHeaders', (error, blockHeader) => {
    if (error) {
      console.error('Error in block subscription:', error);
      return;
    }
  });
  
  subscription.on('data', async (blockHeader) => {
    console.log(\`New block received: \${blockHeader.number}\`);
    await indexBlock(blockHeader.number);
  });
  
  subscription.on('error', (error) => {
    console.error('Subscription error:', error);
  });
  
  console.log('Subscribed to new blocks');
}

// Main function
async function main() {
  try {
    await initDatabase();
    await indexBlocks();
    subscribeToNewBlocks();
  } catch (error) {
    console.error('Error in main function:', error);
  }
}

// Run the indexer
main();
EOL
    
    sudo mv sample_indexer.js "${CUSTOM_PATH}/ai_indexing/sample_code/"
    sudo chown $(whoami):docker "${CUSTOM_PATH}/ai_indexing/sample_code/sample_indexer.js"
    
    # Create a README file
    cat > indexer_readme.md << EOL
# PulseChain Indexer Sample

This directory contains sample code for indexing data from your PulseChain node.

## Sample Indexer

The \`sample_indexer.js\` file is a basic Node.js script that demonstrates how to:

1. Connect to your PulseChain node
2. Index blocks and transactions into a PostgreSQL database
3. Subscribe to new blocks for real-time indexing

## Setup Instructions for the Indexing Machine

### Prerequisites

- Node.js 14+ installed
- PostgreSQL database installed and configured
- Network access to your PulseChain node (IP: ${server_ip})

### Installation

1. Create a new directory for your indexer
2. Copy the \`sample_indexer.js\` file to that directory
3. Install required dependencies:

\`\`\`
npm init -y
npm install web3 pg
\`\`\`

4. Create a PostgreSQL database:

\`\`\`
createdb blockchain_index
\`\`\`

5. Update the database configuration in the script with your PostgreSQL credentials

### Running the Indexer

\`\`\`
node sample_indexer.js
\`\`\`

## Customization

You can customize the indexer by:

- Modifying the database schema to store additional data
- Adjusting the batch size and concurrency for performance
- Adding custom logic to extract and index specific contract events
- Creating an API to query the indexed data

## Production Considerations

For a production environment, consider:

- Using a process manager like PM2 to keep the indexer running
- Implementing error handling and automatic recovery
- Setting up monitoring and alerts
- Optimizing database indexes for query performance
- Implementing a more sophisticated retry mechanism for failed operations
EOL
    
    sudo mv indexer_readme.md "${CUSTOM_PATH}/ai_indexing/sample_code/"
    sudo chown $(whoami):docker "${CUSTOM_PATH}/ai_indexing/sample_code/indexer_readme.md"
    
    echo ""
    echo "Sample indexer code has been created at ${CUSTOM_PATH}/ai_indexing/sample_code/"
    echo "You can copy these files to your indexing machine and follow the instructions in the README."
    echo ""
    read -p "Press Enter to continue..."
}

# Function to check archive node status
check_archive_status() {
    clear
    echo "Check Archive Node Status"
    echo "========================"
    echo ""
    
    echo "This will check the status of your archive node and verify it's suitable for indexing."
    echo ""
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y curl
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    # Check if node is running
    if ! sudo docker ps | grep -q execution; then
        echo "Execution client is not running. Please start it first."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if node is synced
    echo "Checking if node is synced..."
    sync_status=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545)
    
    if [[ "$sync_status" == *"\"result\":false"* ]]; then
        echo "✅ Node is fully synced"
    else
        echo "❌ Node is still syncing. It's recommended to wait until sync is complete before indexing."
    fi
    
    # Check if trace API is enabled
    echo ""
    echo "Checking if trace API is enabled..."
    trace_test=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"trace_replayBlockTransactions","params":["latest",["trace"]],"id":1}' http://localhost:8545)
    
    if [[ "$trace_test" != *"\"error\""* ]]; then
        echo "✅ Trace API is enabled"
    else
        echo "❌ Trace API is not enabled. This is required for full indexing capabilities."
        echo "   You can enable it by adding 'trace' to the http.api and ws.api parameters in start_execution.sh"
    fi
    
    # Check disk space
    echo ""
    echo "Checking disk space..."
    disk_space=$(df -h | grep -E "$(df . | tail -1 | awk '{print $1}')")
    echo "$disk_space"
    
    # Get database size
    echo ""
    echo "Checking database size..."
    db_size=$(sudo du -sh ${CUSTOM_PATH}/execution)
    echo "Execution client database size: $db_size"
    
    # Check available API methods
    echo ""
    echo "Checking available API methods..."
    methods=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"rpc_modules","params":[],"id":1}' http://localhost:8545)
    
    if command -v jq &> /dev/null; then
        echo "Available API methods:"
        echo "$methods" | jq '.result'
    else
        echo "Available API methods (raw):"
        echo "$methods"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    clear
    echo "Indexing Support - v${VERSION}"
    echo "============================"
    echo ""
    echo "1) Optimize Erigon for Indexing"
    echo "2) Configure Indexer Connection"
    echo "3) Monitor Indexing Performance"
    echo "4) Create Sample Indexer Code"
    echo "5) Check Archive Node Status"
    echo ""
    echo "0) Back to Main Menu"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) optimize_for_indexing ;;
        2) configure_indexer_connection ;;
        3) monitor_indexing_performance ;;
        4) create_sample_indexer ;;
        5) check_archive_status ;;
        0) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done 