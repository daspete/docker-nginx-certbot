# Docker, nginx, Let's encrypt SSL flow

## base docker-compose.yml

```yml
services:
  webserver: 
    container_name: webserver
    image: nginx:latest
    networks:
      - webnet
    ports:
      - 80:80
      - 443:443
    depends_on:
      - dockertest1
    volumes:
      - ./www:/var/www/html
      - ./nginx:/etc/nginx/templates
      - ./certbot-etc:/etc/letsencrypt
      - ./certbot-var:/var/lib/letsencrypt
      - ./dhparam:/etc/ssl/certs

  dockertest1:
    container_name: dockertest1
    image: ghost
    networks:
      - webnet

networks:
  webnet:
    driver: bridge
```


## create dhparam cert

sudo openssl dhparam -out ~/develop/dhparam/dhparam-2048.pem 2048


## create nginx vhost

first add just the port 80 part with the acme challenge link:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name dockertest1.daspete.at;

    location / {
        proxy_pass http://dockertest1:2368;
        proxy_buffering off;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location ~ /.well-known/acme-challenge {
        allow all;
        root /var/www/html;
    }
}
```


## create an SSL certificate

```bash
./certbot.sh dockertest1.daspete.at
```


## Update the nginx host with your SSL certificate

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name dockertest1.daspete.at;

    server_tokens off;

    ssl_certificate /etc/letsencrypt/live/dockertest1.daspete.at/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dockertest1.daspete.at/privkey.pem;

    ssl_buffer_size 8k;

    ssl_dhparam /etc/ssl/certs/dhparam-2048.pem;

    ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
    ssl_prefer_server_ciphers on;

    ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5;

    ssl_ecdh_curve secp384r1;
    ssl_session_tickets off;

    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8;

    location / {
        proxy_pass http://dockertest1:2368;
        proxy_buffering off;
        proxy_set_header X-Real-IP $remote_addr;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
    }

}
```

## restart your nginx container

after you restarted your nginx container, you should be able to surf via https