#!/bin/bash

docker run --rm --name certbot \
    -v /home/daspete/develop/certbot-etc:/etc/letsencrypt \
    -v /home/daspete/develop/certbot-var:/var/lib/letsencrypt \
    -v /home/daspete/develop/www:/var/www/html \
    certbot/certbot \
    certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        --break-my-certs \
        --cert-name $1 \
        -d $1

