docker compose --env-file .env run --rm --entrypoint certbot certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email hacknitive@gmail.com --agree-tos --no-eff-email -d logapi.x50.ir


crontab -e

*/5 * * * * /absolute/path/to/your/project/certbot/check_nginx_reload.sh



# For the first time when nginx is not up yet
docker run --rm -p 80:80 certbot/certbot:v4.1.1 certonly --standalone --preferred-challenges http --email hacknitive@gmail.com --agree-tos --no-eff-email -d logapi.x50.ir