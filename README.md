docker compose --env-file .env run --rm --entrypoint certbot certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email hacknitive@gmail.com --agree-tos --no-eff-email -d logapi.x50.ir


crontab -e

*/5 * * * * /home/$USER/infra-nginx-certbot/renew_and_reload.sh

