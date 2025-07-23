#!/bin/bash

# Check if the .env file path is provided as an argument.
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 /path/to/.env [--force]"
  exit 1
fi

ENV_FILE_PATH="$1"
if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "Error: Environment file not found at $ENV_FILE_PATH"
  exit 1
fi

# Check if the optional --force flag is provided.
FORCE_OPTION=""
if [ "$#" -ge 2 ] && [ "$2" == "--force" ]; then
  FORCE_OPTION="--force-renewal"
fi

# Load environment variables from the specified .env file.
set -a
source "$ENV_FILE_PATH"
set +a

# Use the certbot compose file -- default to "docker-compose.yml" if not set.
if [ -z "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" ]; then
  DOCKER_COMPOSE_FILE_ABSOLUTE_PATH="docker-compose.yml"
fi

# Determine the script's directory for log file location.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="${SCRIPT_DIR}/renew_and_reload.log"
NGINX_CONTAINER="${NGINX_CONTAINER_NAME:-nginx}"

{
  echo "============================"
  echo "Certbot renewal process started at $(date)"
} >> "$LOG_FILE"

# Run certbot renew using Docker Compose, passing the --force-renewal flag if set.
OUTPUT=$(docker compose -f "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" run --rm certbot renew $FORCE_OPTION 2>&1)
echo "$OUTPUT" >> "$LOG_FILE"

# Check the output for a successful renewal (by detecting "Congratulations").
if echo "$OUTPUT" | grep -qi "Congratulations"; then
  echo "Certificate renewal detected. Reloading nginx..." >> "$LOG_FILE"
  if docker exec "$NGINX_CONTAINER" nginx -s reload >> "$LOG_FILE" 2>&1; then
    echo "Nginx reloaded successfully." >> "$LOG_FILE"
  else
    echo "Error: Failed to reload nginx." >> "$LOG_FILE"
  fi
else
  echo "No certificate renewal was needed." >> "$LOG_FILE"
fi

{
  echo "Certbot renewal process finished at $(date)"
  echo "============================"
} >> "$LOG_FILE"