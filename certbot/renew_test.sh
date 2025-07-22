while true
do echo "Starting certificate renewal process after 10 seconds (for test purpose)..."
sleep 10s
certbot renew --force-renewal --post-hook "sh -c 'echo \"Successful renewal\" && /usr/bin/docker exec ${NGINX_CONTAINER_NAME} nginx -s reload'"
sleep 5d
done