# Ready-to-Use Nginx-Certbot Docker Infrastructure
This repository provides a containerized solution for automating the issuance and renewal of SSL certificates using [Certbot](https://certbot.eff.org/) together with [Nginx](https://nginx.org/). Leveraging Docker Compose, this project ensures the seamless integration of Nginx (serving web content and handling ACME challenges) and Certbot (acquiring and renewing certificates), while automating the process of certificate renewal.

## Table of Contents

- [Ready-to-Use Nginx-Certbot Docker Infrastructure](#ready-to-use-nginx-certbot-docker-infrastructure)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
  - [Setup \& Configuration](#setup--configuration)
  - [Obtaining an SSL Certificate](#obtaining-an-ssl-certificate)
  - [Viewing Issued Certificates](#viewing-issued-certificates)
  - [Certificate Renewal](#certificate-renewal)
  - [Automating Renewal via Cron](#automating-renewal-via-cron)
  - [Nginx Configurations](#nginx-configurations)
  - [Project Structure](#project-structure)
  - [Conclusion](#conclusion)

## Overview

This solution uses:
- **Nginx** – to serve your website and handle HTTP (port 80) ACME challenges.
- **Certbot** – to request and renew SSL certificates from Let’s Encrypt.
- **Docker Compose** – to manage and orchestrate multi-container deployments easily.

The automated renewal process is handled by the `renew_and_reload.sh` script, which renews certificates when needed and reloads Nginx to apply any new updates.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed on your host machine.
- A registered domain name that points to your server.
- Basic command-line/terminal knowledge.

## Setup & Configuration

1. **Create and Configure the Environment File:**

   - Copy the provided `.env.example` file to create your actual environment file:
     ```bash
     cp .env.example .env
     ```
   - Open the `.env` file and update the variables (paths, ports, container names, etc.) as required for your environment.

2. **Configure Nginx for HTTP (Port 80):**

   - In the `nginx/sites-available` folder, create or modify an Nginx configuration file (for example, `example.com-80.conf`) to listen on port 80. Ensure the configuration includes a block to handle ACME challenges:
     ```nginx
     server {
         listen 80;
         server_name example.com;
         # Serve Certbot ACME challenge files.
         location /.well-known/acme-challenge/ {
             root /usr/share/nginx/html;
             allow all;
         }
         location / {
             proxy_pass http://0.0.0.0:3000;
             include /etc/nginx/sites-available/common_proxy.conf;
         }
     }
     ```
   - Create a symbolic link in the `nginx/sites-enabled` folder:
     ```bash
     ln -s ../sites-available/example.com-80.conf nginx/sites-enabled/
     ```

3. **Start Nginx Container:**

   - With the environment and Nginx HTTP configuration in place, launch the Nginx container:
     ```bash
     docker compose --env-file .env up -d nginx
     ```
   - This command starts Nginx and makes it available to serve static content (including ACME challenge files).

## Obtaining an SSL Certificate

Use the following command to request an SSL certificate via Certbot. This utilizes the HTTP (webroot) method to verify domain ownership:

```bash
docker compose --env-file .env run --rm --entrypoint certbot certbot certonly --webroot --webroot-path=/usr/share/nginx/html --email hacknitive@gmail.com --agree-tos --no-eff-email -d example.com
```

**Explanation:**
- `--webroot` and `--webroot-path=/usr/share/nginx/html`: Direct Certbot to use the provided web root to place ACME challenge files.
- `--email hacknitive@gmail.com`: Sets the contact email for renewal notices and related communication.
- `--agree-tos --no-eff-email`: Automatically accepts the Let’s Encrypt terms and opts out of the Electronic Frontier Foundation email list.
- `-d logapi.x50.ir`: Specifies the domain name for which the certificate is issued.
- Replace the second `certbot` with the value of `CERTBOT_CONTAINER_NAME` environment variable in your `.env` file.

## Viewing Issued Certificates

To review all the certificates managed by Certbot and check their details:

```bash
docker compose --env-file .env run --rm --entrypoint certbot certbot certificates
```
- Replace the second `certbot` with the value of `CERTBOT_CONTAINER_NAME` environment variable in your `.env` file.

This command informs you of the certificates’ issuance dates, expiration dates, and related paths.

## Certificate Renewal

The `renew_and_reload.sh` script can be run manually to renew your SSL certificates when needed. It does the following:
- Validates the environment configuration.
- Runs the Certbot renewal command.
- Checks for certificate renewal flag creation.
- Reloads the Nginx container if a certificate has been renewed.

Run the script with:

```bash
./renew_and_reload.sh "/path/to/your/.env"
```

To force a renewal even if the certificates are not near expiry (suitable for test), use:

```bash
./renew_and_reload.sh "/path/to/your/.env" --force
```

## Automating Renewal via Cron

To ensure your certificates remain up-to-date, you can set up a cron job that periodically runs the renewal script.

1. **Open your crontab file for editing:**
   ```bash
   crontab -e
   ```

2. **Add the following cron job entry:**
   ```bash
   0 5 * * * /path/to/infra-nginx-certbot/renew_and_reload.sh "/path/to/infra-nginx-certbot/.env" >> /path/to/infra-nginx-certbot/logs/cronjob.log 2>&1
   ```
   
   **Explanation:**
   - `0 5 * * *` – Runs the script at 5:00 AM every day.
   - The command calls the `renew_and_reload.sh` script with your custom `.env` file.
   - All output (both stdout and errors) is appended to `cronjob.log` for troubleshooting and monitoring.

## Nginx Configurations

The project includes sample Nginx configuration files located in the `nginx/sites-available` directory:

1. **example.com-80.conf (HTTP):**
   - Listens on port 80.
   - Contains a location block to serve the ACME challenge files from `/usr/share/nginx/html`.
   - Proxies other requests to your backend service (for example, running on port 3000).

2. **example.com-443.conf (HTTPS):**
   - Configured to listen on port 443 with SSL enabled.
   - Specifies the paths for the SSL certificate and private key (e.g., `/etc/letsencrypt/live/example.com/fullchain.pem` and `/etc/letsencrypt/live/example.com/privkey.pem`).
   - Proxies HTTPS requests to your backend service similarly.

3. **common_proxy.conf:**
   - Contains shared proxy settings used by both HTTP and HTTPS configurations.

## Project Structure

An overview of the repository structure:

```
├── LICENSE                       # Project license file
├── .gitignore                    # Git ignore rules for the repository
├── README.md                     # This README file
├── .env.example                  # Template for the environment configuration file
├── docker-compose.yml            # Docker Compose configuration for Nginx and Certbot
├── renew_and_reload.sh           # Script to renew certificates and reload Nginx
├── nginx/
│   ├── nginx.conf                # Main Nginx configuration file
│   ├── mime.types                # MIME types list for Nginx
│   ├── sites-available/          # Nginx site configuration templates
│   │   ├── example.com-80.conf   # HTTP configuration for example.com
│   │   ├── example.com-443.conf  # HTTPS configuration for example.com
│   │   └── common_proxy.conf     # Common proxy settings for Nginx configurations
│   └── sites-enabled/            # Active Nginx configurations (usually symlinked from sites-available)
├── certbot/                      
│   └── letsencrypt/              # Lets encrypt directories
│   
└── logs/                         # Directory for log files (renewal logs, cron output, etc.)
```

## Conclusion

This project is designed to simplify the process of securing your website with HTTPS by automating the acquisition and renewal of SSL certificates with Certbot and Nginx. By following this guide, you can quickly set up, maintain, and monitor your secure web server environment. For any questions, customization requests, or feature suggestions, feel free to open an issue or contact the maintainer.

Happy Securing!
