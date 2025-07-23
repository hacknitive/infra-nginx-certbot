#!/bin/bash
# Absolute paths to the required files (adjust as needed)
NOTIFY_FILE="/absolute/path/to/your/project/certbot/notify.txt"
LOG_FILE="/absolute/path/to/your/project/certbot/check_nginx_reload.log"

# Function to append timestamped messages to the log file
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Script execution started."

# Check if the notify file exists
if [ ! -f "$NOTIFY_FILE" ]; then
  log_message "Error: Notify file does not exist at $NOTIFY_FILE."
  exit 1
fi

# Check if the notify file is not empty (i.e. contains a renewal notification)
if [ -s "$NOTIFY_FILE" ]; then
  log_message "Certificate renewal notification detected. Attempting to reload Nginx..."

  # Attempt to reload nginx (assuming Nginx is running in a container named "nginx")
  if docker exec nginx nginx -s reload >> "$LOG_FILE" 2>&1; then
    log_message "Nginx reloaded successfully."
  else
    log_message "Error: Failed to reload Nginx."
  fi

  # Clear the contents of notify.txt to prevent multiple reloads on the same notification
  > "$NOTIFY_FILE"
  log_message "Cleared notification file."
else
  log_message "No certificate renewal notification detected."
fi

log_message "Script execution finished."