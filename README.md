docker compose run --rm --entrypoint certbot certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email hacknitive@gmail.com --agree-tos --no-eff-email -d api.x50.ir


crontab -e

*/5 * * * * /absolute/path/to/your/project/certbot/check_nginx_reload.sh