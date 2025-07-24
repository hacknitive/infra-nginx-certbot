docker compose --env-file .env run --rm --entrypoint certbot certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email hacknitive@gmail.com --agree-tos --no-eff-email -d logapi.x50.ir


crontab -e:

0 5 * * * /home/dev/infra-nginx-certbot/renew_and_reload.sh "/home/dev/infra-nginx-certbot/.env" >> /home/dev/infra-nginx-certbot/logs/cronjob.log 2>&1

