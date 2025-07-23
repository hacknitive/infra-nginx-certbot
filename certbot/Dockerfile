# Use the official Certbot image as the base image
FROM certbot/certbot:v4.1.1

# Switch to root so we can install packages
# USER root

# Update apt and install the Docker CLI
RUN apk add --no-cache docker-cli

# (Optional) Switch back to the default non-root user if needed.  
# Uncomment the following line if Certbot is set to run under a non-root user.
# USER certbot

# The default CMD or ENTRYPOINT of the certbot image will be preserved