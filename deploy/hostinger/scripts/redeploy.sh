#!/usr/bin/env bash
# Redeploy after git pull
set -euo pipefail

APP_DIR="/var/www/progarage"
cd "$APP_DIR/repo"
git pull origin main

cd deploy/hostinger
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" build api
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" up -d
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" exec -T api php artisan migrate --force
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" exec -T api php artisan config:cache
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" exec -T api php artisan route:cache

echo "✅ Redeploy complete"
