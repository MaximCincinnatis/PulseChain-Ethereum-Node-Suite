#!/bin/bash

# ===============================================================================
# PulseChain Node Health Check Setup Script
# ===============================================================================
# This script sets up a cron job to run the health check regularly
# ===============================================================================

# Source global configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_ROOT="$(dirname "$SCRIPT_DIR")"
source "$NODE_ROOT/config.sh"

# Colors for better formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Ensure the health check script is executable
sudo chmod +x "$SCRIPT_DIR/health_check.sh"

echo -e "${GREEN}PulseChain Node Health Check Setup${NC}"
echo "======================================"
echo ""
echo "This script will set up a cron job to run health checks"
echo "on your PulseChain node at regular intervals."
echo ""
echo "Current configuration:"
echo "- Health check interval: Every ${HEALTH_CHECK_INTERVAL} seconds"
echo "- Health check script: $SCRIPT_DIR/health_check.sh"
echo "- Log file: $HEALTH_LOG"
echo ""

read -p "Do you want to set up automatic health checks? (y/N): " setup_auto

if [[ "$setup_auto" =~ ^[Yy]$ ]]; then
    # Calculate cron schedule (default: every 5 minutes)
    interval_minutes=$(( HEALTH_CHECK_INTERVAL / 60 ))
    
    # Ensure interval is at least 1 minute
    if [[ $interval_minutes -lt 1 ]]; then
        interval_minutes=1
    fi
    
    # Ask for custom interval
    read -p "How often should health checks run (in minutes, default: $interval_minutes): " custom_interval
    
    if [[ -n "$custom_interval" ]]; then
        if [[ "$custom_interval" =~ ^[0-9]+$ ]]; then
            interval_minutes=$custom_interval
        else
            echo -e "${YELLOW}Invalid input. Using default: $interval_minutes minutes.${NC}"
        fi
    fi
    
    # Create cron schedule
    if [[ $interval_minutes -lt 60 ]]; then
        # Run every X minutes
        cron_schedule="*/$interval_minutes * * * *"
    else
        # Run every X hours
        interval_hours=$(( interval_minutes / 60 ))
        cron_schedule="0 */$interval_hours * * *"
    fi
    
    # Create temporary cron file
    cron_file=$(mktemp)
    
    # Export current cron jobs
    crontab -l > "$cron_file" 2>/dev/null || echo "# PulseChain Node Cron Jobs" > "$cron_file"
    
    # Check if health check is already in cron
    if grep -q "health_check.sh" "$cron_file"; then
        echo -e "${YELLOW}Health check is already scheduled in cron. Updating...${NC}"
        sed -i "/health_check.sh/d" "$cron_file"
    fi
    
    # Add health check to cron
    echo "# PulseChain Node Health Check - Added $(date)" >> "$cron_file"
    echo "$cron_schedule $SCRIPT_DIR/health_check.sh --cron > /dev/null 2>&1" >> "$cron_file"
    
    # Install new cron
    crontab "$cron_file"
    rm "$cron_file"
    
    echo -e "${GREEN}Health check scheduled to run $cron_schedule (every $interval_minutes minutes)${NC}"
    echo "You can check the health check logs at: $HEALTH_LOG"
    
    # Run a health check right now to verify it works
    echo ""
    echo "Running an initial health check to verify everything works..."
    "$SCRIPT_DIR/health_check.sh"
    
    echo ""
    echo -e "${GREEN}Health check setup complete!${NC}"
    echo "To view health check logs at any time, run:"
    echo "cat $HEALTH_LOG"
else
    echo ""
    echo -e "${YELLOW}Automatic health checks not set up.${NC}"
    echo "You can still run health checks manually by executing:"
    echo "$SCRIPT_DIR/health_check.sh"
fi

# Offer to add health check to menu
echo ""
read -p "Would you like to add a health check option to the node menu? (y/N): " add_to_menu

if [[ "$add_to_menu" =~ ^[Yy]$ ]]; then
    # We will make this more sophisticated in future updates
    # For now, just let the user know they can run it manually
    echo -e "${GREEN}You can run the health check manually from the command line.${NC}"
    echo "Future updates will integrate this directly into the menu system."
fi

echo ""
echo "Done!" 