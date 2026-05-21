#!/usr/bin/env bash
# Enable HTTPS after DNS points api.progarageos.com → server IP
set -euo pipefail

DOMAIN="${DOMAIN:-api.progarageos.com}"

certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" --non-interactive --agree-tos -m admin@aksharatech.com || {
  echo "Certbot failed — ensure DNS A record exists for $DOMAIN"
  exit 1
}

cp /var/www/progarage/repo/deploy/hostinger/nginx-proxy/progarage.conf /var/www/nginx-proxy/conf.d/progarage.conf
rm -f /var/www/nginx-proxy/conf.d/progarage-http.conf
docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload

echo "✅ HTTPS enabled for https://$DOMAIN"
