#!/bin/bash

# PulseChain Node Restart Script (Non-Validator Version)
# This script gracefully stops all node containers and prunes stopped containers

# Gracefully stop containers with appropriate timeouts
sudo docker stop -t 300 execution
sudo docker stop -t 180 beacon

# Prune stopped containers to free up resources
sudo docker container prune -f
