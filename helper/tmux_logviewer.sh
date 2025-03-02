#!/bin/bash

# Extract logs in a tmux session

# Check if a tmux session named "logs" already exists
if tmux has-session -t logs 2>/dev/null; then
    # Kill the existing session
    tmux kill-session -t logs
fi

# Create a new tmux session named "logs" with a window named "execution"
tmux new-session -d -s logs -n "execution"

# Split the window horizontally and create a pane for the beacon logs
tmux split-window -h -t logs

# Name the left pane "execution" and the right pane "beacon"
tmux send-keys -t logs:0.0 'echo -e "\033]0;Execution Client Logs\007"' Enter
tmux send-keys -t logs:0.1 'echo -e "\033]0;Beacon Client Logs\007"' Enter

# Start tailing the logs in each pane
tmux send-keys -t logs:0.0 'docker logs -f --tail=30 execution' Enter
tmux send-keys -t logs:0.1 'docker logs -f --tail=30 beacon' Enter

# Attach to the tmux session
tmux attach-session -t logs

# Note: To exit the session, press Ctrl+B followed by :, then type "kill-session" and press Enter
