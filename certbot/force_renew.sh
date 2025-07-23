#!/bin/sh
# Use this for test purposes only.
while true
do
  echo "Starting certificate renewal process..."
  certbot renew  --force-renewal --deploy-hook "/bin/sh -c 'echo \"$(date) - Certificate renewed\" >> /certbot/notify.txt'"
  sleep 5d
done