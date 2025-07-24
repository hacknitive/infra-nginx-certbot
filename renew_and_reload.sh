#!/bin/bash
# -------------------------------------------------------------------------
# renew_and_reload.sh
#
# This script automates the process of renewing SSL certificates using Certbot,
# and if a renewal occurs, it reloads Nginx to apply the new certificate.
#
# How It Works:
#   1. Checks for the required environment file argument and verifies its existence.
#   2. Parses an optional '--force' argument to force certificate renewal.
#   3. Exports the environment variables defined in the provided .env file.
#   4. Validates that the necessary environment variables are set.
#   5. Removes any existing renewal flag file to ensure a fresh start.
#   6. Logs the start of the certificate renewal process.
#   7. Runs the Certbot renewal command via Docker Compose with a deploy-hook that
#      creates a flag file if a certificate renewal takes place.
#   8. Checks for the renewal flag; if detected, reloads Nginx to use the updated certificate.
#   9. Logs the completion of the renewal process.
#
# Usage:
#   ./renew_and_reload.sh /path/to/.env [--force]
#       /path/to/.env : The path to the environment file containing required variables.
#       --force      : (Optional) Flag to force certificate renewal.
# -------------------------------------------------------------------------

# ----------------------------
# Step 1: Verify Input Arguments
# ----------------------------
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 /path/to/.env [--force]"
  exit 1
fi

# Store the provided environment file path.
ENV_FILE_PATH="$1"

# Check whether the specified environment file exists.
if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "Error: Environment file not found at $ENV_FILE_PATH"
  exit 1
fi

# ----------------------------
# Step 2: Parse Optional '--force' Argument
# ----------------------------
# If the '--force' option is provided, set the FORCE_OPTION variable accordingly.
FORCE_OPTION=""
if [ "$#" -ge 2 ] && [ "$2" == "--force" ]; then
  FORCE_OPTION="--force-renewal"
fi

# ----------------------------
# Step 3: Export Environment Variables
# ----------------------------
# Export all variables from the provided environment file so they become available to the script.
set -a  # Automatically export all variables.
source "$ENV_FILE_PATH"
set +a  # Stop automatically exporting.

# ----------------------------
# Step 4: Validate Required Environment Variables
# ----------------------------
# Define a list of critical environment variables needed for the renewal process.
REQUIRED_ENV_VARS=(
  "DOCKER_COMPOSE_FILE_ABSOLUTE_PATH"
  "CERTBOT_CONTAINER_NAME"
  "NGINX_CONTAINER_NAME"
  "LOG_ABSOLUTE_PATH"
)

# Define the log file path where renewal process logs will be stored.
LOG_FILE_PATH="${LOG_ABSOLUTE_PATH}/renew_and_reload.log"

# Loop over each required environment variable to ensure they are set.
for VAR in "${REQUIRED_ENV_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "Error: Required environment variable '$VAR' is not set in $ENV_FILE_PATH."
    exit 1
  fi
done

# ----------------------------
# Step 5: Set Up Renewal Success Flag Paths
# ----------------------------
# Define the flag file path for Certbot inside the container. This flag is set by the deploy-hook.
RENEW_SUCCESS_FLAG_PATH_IN_CERTBOT_CONTAINER="/var/log/letsencrypt/renew_success.flag"
# Define the flag file path on the host (shared with the Certbot container via volume).
RENEW_SUCCESS_FLAG_PATH_IN_HOST="${LOG_ABSOLUTE_PATH}/renew_success.flag"

# Remove any existing renewal success flag file to avoid false positives.
if [ -f "$RENEW_SUCCESS_FLAG_PATH_IN_HOST" ]; then
  rm "$RENEW_SUCCESS_FLAG_PATH_IN_HOST"
fi

# ----------------------------
# Step 6: Log the Start of the Renewal Process
# ----------------------------
{
  echo "============================"
  echo "Certbot renewal process started at $(date)"
} >> "$LOG_FILE_PATH"

# ----------------------------
# Step 7: Execute Certbot Renewal via Docker Compose
# ----------------------------
# Run the certificate renewal process inside a temporary Certbot container.
# The deploy-hook "touch" command creates a flag file in the container if a certificate is renewed.
OUTPUT=$(docker compose --env-file "$ENV_FILE_PATH" \
  -f "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" run --rm "$CERTBOT_CONTAINER_NAME" \
  renew $FORCE_OPTION --deploy-hook "touch $RENEW_SUCCESS_FLAG_PATH_IN_CERTBOT_CONTAINER" 2>&1)

# Append the output from the Certbot command to the log file.
echo "$OUTPUT" >> "$LOG_FILE_PATH"

# ----------------------------
# Step 8: Check for Renewal Success and Reload Nginx if Needed
# ----------------------------
# If the renewal flag file exists on the host, it indicates that a certificate renewal occurred.
if [ -f "$RENEW_SUCCESS_FLAG_PATH_IN_HOST" ]; then
  echo "Certificate renewal detected. Reloading nginx..." >> "$LOG_FILE_PATH"
  # Reload Nginx inside its container to apply the new certificate.
  if docker compose --env-file "$ENV_FILE_PATH" \
         -f "$DOCKER_COMPOSE_FILE_ABSOLUTE_PATH" \
         exec "$NGINX_CONTAINER_NAME" nginx -s reload >> "$LOG_FILE_PATH" 2>&1; then
    echo "Nginx reloaded successfully." >> "$LOG_FILE_PATH"
  else
    echo "Error: Failed to reload nginx." >> "$LOG_FILE_PATH"
  fi
else
  echo "No certificate renewal was needed." >> "$LOG_FILE_PATH"
fi

# ----------------------------
# Step 9: Log the End of the Renewal Process
# ----------------------------
{
  echo "Certbot renewal process finished at $(date)"
  echo "============================"
} >> "$LOG_FILE_PATH"