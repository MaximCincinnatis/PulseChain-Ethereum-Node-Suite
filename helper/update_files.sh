#!/bin/bash

# Function to check if a URL is reachable
check_url_accessibility() {
  local url=$1
  local return_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
  if [[ $return_code -eq 200 || $return_code -eq 301 || $return_code -eq 302 ]]; then
    return 0
  else
    return 1
  fi
}

# Display pre-release warning
echo "=========================================================="
echo "⚠️  PRE-PRE-RELEASE WARNING ⚠️"
echo "This is a pre-alpha release of PulseChain Full Node Suite"
echo "It may contain bugs and incomplete features"
echo "Use at your own risk in non-production environments only"
echo "=========================================================="
echo ""
echo "Press Enter to continue or Ctrl+C to cancel"
read -p ""

# Define the primary and fallback URLs for the repository
PRIMARY_URL="https://raw.githubusercontent.com/tdslaine/install_pulse_node/main"
FALLBACK_URL="https://raw.githubusercontent.com/MaximCincinnatus/install_pulse_node/main"

# Determine install path - default to /blockchain if not set
if [ -z "$INSTALL_PATH" ]; then
  # Try to detect it
  if [ -d "/blockchain" ]; then
    INSTALL_PATH="/blockchain"
  else
    echo "Error: Installation path could not be determined. Please set the INSTALL_PATH variable."
    exit 1
  fi
fi

# Get temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Create the helper directory if it doesn't exist
mkdir -p $INSTALL_PATH/helper

# Check if the primary URL is reachable, if not, use the fallback URL
if check_url_accessibility "$PRIMARY_URL/setup_pulse_node.sh"; then
  REPO_URL=$PRIMARY_URL
else
  echo "Primary URL not accessible, using fallback URL."
  REPO_URL=$FALLBACK_URL
fi

echo "Getting updated files from $REPO_URL"

# Download the main script files
wget -q $REPO_URL/setup_pulse_node.sh -O $TMP_DIR/setup_pulse_node.sh
wget -q $REPO_URL/setup_monitoring.sh -O $TMP_DIR/setup_monitoring.sh
wget -q $REPO_URL/functions.sh -O $TMP_DIR/functions.sh

# Verify the directory exists or create it
[ -d "$INSTALL_PATH/helper" ] || mkdir -p "$INSTALL_PATH/helper"

# Copy updated script files
cp $TMP_DIR/setup_pulse_node.sh $INSTALL_PATH/
cp $TMP_DIR/setup_monitoring.sh $INSTALL_PATH/
cp $TMP_DIR/functions.sh $INSTALL_PATH/

# Download helper scripts
wget -q $REPO_URL/helper/menu.sh -O $TMP_DIR/menu.sh
wget -q $REPO_URL/helper/update_files.sh -O $TMP_DIR/update_files.sh
wget -q $REPO_URL/helper/verify_node.sh -O $TMP_DIR/verify_node.sh
wget -q $REPO_URL/helper/check_sync.sh -O $TMP_DIR/check_sync.sh
wget -q $REPO_URL/helper/check_rpc_connection.sh -O $TMP_DIR/check_rpc_connection.sh
wget -q $REPO_URL/helper/backup_restore.sh -O $TMP_DIR/backup_restore.sh
wget -q $REPO_URL/helper/stop_docker.sh -O $TMP_DIR/stop_docker.sh
wget -q $REPO_URL/helper/grace.sh -O $TMP_DIR/grace.sh

# Copy helper scripts (excluding validator-related scripts)
cp $TMP_DIR/menu.sh $INSTALL_PATH/helper/
cp $TMP_DIR/update_files.sh $INSTALL_PATH/helper/
cp $TMP_DIR/verify_node.sh $INSTALL_PATH/helper/
cp $TMP_DIR/check_sync.sh $INSTALL_PATH/helper/
cp $TMP_DIR/check_rpc_connection.sh $INSTALL_PATH/helper/
cp $TMP_DIR/backup_restore.sh $INSTALL_PATH/helper/
cp $TMP_DIR/stop_docker.sh $INSTALL_PATH/helper/
cp $TMP_DIR/grace.sh $INSTALL_PATH/helper/

# Set executable permissions
chmod +x $INSTALL_PATH/*.sh
chmod +x $INSTALL_PATH/helper/*.sh

# Update start scripts if they exist
# Non-validator edition only needs execution and consensus client scripts
SCRIPTS=("$INSTALL_PATH/start_consensus.sh" "$INSTALL_PATH/start_execution.sh")
for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    # Get the existing script to analyze what client it's using
    if grep -q "lighthouse" "$script"; then
      CLIENT="lighthouse"
    elif grep -q "prysm" "$script"; then
      CLIENT="prysm"
    elif grep -q "geth" "$script"; then
      CLIENT="geth"
    elif grep -q "erigon" "$script"; then
      CLIENT="erigon"
    fi
    
    if [ ! -z "$CLIENT" ]; then
      echo "Detected $CLIENT in $script, updating..."
      # Here you would download and apply the appropriate start script
    fi
  fi
done

# Check if script update is already in cron
if ! crontab -l | grep -q "update_files.sh"; then
  # Add daily check for updates to crontab
  (crontab -l 2>/dev/null; echo "0 3 * * * $INSTALL_PATH/helper/update_files.sh > /dev/null 2>&1") | crontab -
  echo "Added daily update check to crontab"
fi

echo "Update completed!"
