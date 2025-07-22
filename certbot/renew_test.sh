while true
do echo "Starting certificate renewal process (for test purpose)..."
certbot renew --force-renewal --post-hook "docker exec ${NGINX_CONTAINER_NAME} nginx -s reload"
sleep 5d
done