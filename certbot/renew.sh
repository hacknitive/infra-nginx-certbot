#!/bin/sh
while true; do
  certbot renew
  sleep 5d
done