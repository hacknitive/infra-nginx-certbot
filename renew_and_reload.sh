#!/bin/bash

# Ensure that a .env file path is passed as the first argument.
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 /path/to/.env [--force]"
  exit 1
fi

ENV_FILE_PATH="$1"
if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "Error: Environment file not found at $ENV_FILE_PATH"
  exit 1
fi

FORCE_OPTION=""
if [ "$#" -ge 2 ] && [ "$2" == "--force" ]; then
  FORCE_OPTION="--force-renewal"
fi

# Export all variables from the .env file so they can be checked.
set -a
source "$ENV_FILE_PATH"
set +a

# Required environment variables list.
REQUIRED_ENV_VARS=(
  "DOCKER_COMPOSE_FILE_ABSOLUTE_PATH"
  "CERTBOT_CONTAINER_NAME"
  "NGINX_CONTAINER_NAME"
  "LOG_ABSOLUTE_PATH"
)

LOG_FILE_PATH="${LOG_ABSOLUTE_PATH}/renew_and_reload.log"

for VAR in "${REQUIRED_ENV_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "Error: Required environment variable '$VAR' is not set in $ENV_FILE_PATH."
    exit 1
  fi
done

# Start logging using the LOG_FILE_PATH specified in the environment.
{
  echo "============================"
  echo "Certbot renewal process started at $(date)"
} >> "$LOG_FILE_PATH"

# Run the certbot renewal.
OUTPUT=$(docker compose --env-file "$ENV_FILE_PATH" -f "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" run --rm "$CERTBOT_CONTAINER_NAME" renew $FORCE_OPTION 2>&1)
echo "$OUTPUT" >> "$LOG_FILE_PATH"

# Check if the renewal was successful (searching for the word "Congratulations").
if echo "$OUTPUT" | grep -qi "Congratulations"; then
  echo "Certificate renewal detected. Reloading nginx..." >> "$LOG_FILE_PATH"
  if docker compose --env-file "$ENV_FILE_PATH" -f "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" exec "$NGINX_CONTAINER_NAME" nginx -s reload >> "$LOG_FILE_PATH" 2>&1; then
    echo "Nginx reloaded successfully." >> "$LOG_FILE_PATH"
  else
    echo "Error: Failed to reload nginx." >> "$LOG_FILE_PATH"
  fi
else
  echo "No certificate renewal was needed." >> "$LOG_FILE_PATH"
fi

{
  echo "Certbot renewal process finished at $(date)"
  echo "============================"
} >> "$LOG_FILE_PATH"