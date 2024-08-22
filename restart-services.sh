#!/bin/bash

LOG_FILE="restart-services.log"
LOAD_THRESHOLD=2.00
CONFIG_FILE="restart-services.conf"

# Read services from config file
readarray -t services < "$CONFIG_FILE"

# Function to log messages with timestamps
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check and manage a service
manage_service() {
    local service=$1
    local action=$2
    log_message "Attempting to $action $service"
    if systemctl "$action" "$service" >> "$LOG_FILE" 2>&1; then
        log_message "$service has been $action"
        return 0
    else
        log_message "Failed to $action $service"
        return 1
    fi
}

# Check CPU load and prompt user if necessary
cpu_load_average=$(awk '{print $1}' /proc/loadavg)
if (( $(echo "$cpu_load_average > $LOAD_THRESHOLD" | bc -l) )); then
    log_message "CPU load average ($cpu_load_average) exceeds $LOAD_THRESHOLD. Continuing..."
else
    echo "Load average: $cpu_load_average"
    log_message "CPU load average ($cpu_load_average) is within the limit."
    read -p "Do you want to run the script anyway? (y/n): " choice
    [[ $choice != "y" ]] && { log_message "Exiting..."; exit 0; }
fi
# Main execution
for action in status restart status; do
    for service in "${services[@]}"; do
        manage_service "$service" "$action" || true
    done
done

log_message "Script execution completed."
