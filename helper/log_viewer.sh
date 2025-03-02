#!/bin/bash

# Close any existing log viewer terminals
wmctrl -l | grep -w "Execution Logs\|Beacon Logs\|HTOP\|DiskUsage" | awk '{print $1}' | xargs -r wmctrl -ic >/dev/null 2>&1

# Open new terminals with appropriate log views
# Opening multiple tabs in gnome-terminal
gnome-terminal --tab --title="Execution Logs" -- bash -c "docker logs -f --tail=20 execution; exec bash" \
               --tab --title="Beacon Logs" -- bash -c "docker logs -f --tail=20 beacon; exec bash" \
               --tab --title="HTOP" -- bash -c "htop; exec bash" \
               --tab --title="DiskUsage" -- bash -c "watch df -H; exec bash"

# For platforms without gnome-terminal, fall back to other terminal emulators
if [ $? -ne 0 ]; then
    # Try xterm
    if command -v xterm >/dev/null 2>&1; then
        xterm -T "Execution Logs" -e "docker logs -f --tail=20 execution; bash" &
        xterm -T "Beacon Logs" -e "docker logs -f --tail=20 beacon; bash" &
        xterm -T "HTOP" -e "htop; bash" &
        xterm -T "DiskUsage" -e "watch df -H; bash" &
    else
        echo "Error: No suitable terminal emulator found."
        echo "Please install gnome-terminal or xterm."
        exit 1
    fi
fi
