while true
do echo "Starting certificate renewal process..."
certbot renew --post-hook "docker exec ${NGINX_CONTAINER_NAME} nginx -s reload"
sleep 5d
done