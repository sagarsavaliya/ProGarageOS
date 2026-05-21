#!/usr/bin/env bash
# Pro Garage OS — first-time Hostinger KVM2 deploy
# Run on VPS as root: bash deploy/hostinger/scripts/server-bootstrap.sh

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/sagarsavaliya/ProGarageOS.git}"
APP_DIR="/var/www/progarage"
BRANCH="${BRANCH:-main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../domain.env"

echo "==> Creating app directory"
mkdir -p "$APP_DIR"

if [ ! -d "$APP_DIR/repo/.git" ]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$APP_DIR/repo"
else
  cd "$APP_DIR/repo" && git pull origin "$BRANCH"
fi

echo "==> Environment file"
if [ ! -f "$APP_DIR/.env" ]; then
  cp "$APP_DIR/repo/deploy/hostinger/.env.production.example" "$APP_DIR/.env"
  DB_PASS="$(openssl rand -hex 16)"
  ROOT_PASS="$(openssl rand -hex 20)"
  sed -i "s/CHANGE_ME_STRONG_PASSWORD/$DB_PASS/" "$APP_DIR/.env"
  sed -i "s/CHANGE_ME_ROOT_PASSWORD/$ROOT_PASS/" "$APP_DIR/.env"
fi
ln -sf "$APP_DIR/.env" "$APP_DIR/repo/deploy/hostinger/.env"

echo "==> Building and starting stack"
cd "$APP_DIR/repo/deploy/hostinger"
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" build api
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" up -d

echo "==> Generating APP_KEY if missing"
if ! grep -q '^APP_KEY=base64:' "$APP_DIR/.env"; then
  KEY=$(docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" exec -T api php artisan key:generate --show)
  sed -i "s|^APP_KEY=.*|APP_KEY=$KEY|" "$APP_DIR/.env"
  docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" up -d --force-recreate api nginx
fi

echo "==> Seeding database (first run only)"
docker compose -f docker-compose.prod.yml --env-file "$APP_DIR/.env" exec -T api php artisan db:seed --force || true

echo "==> Installing nginx-proxy route (HTTP, domain-only)"
cp "$APP_DIR/repo/deploy/hostinger/nginx-proxy/progarage-http.conf" /var/www/nginx-proxy/conf.d/progarage-http.conf
docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload

echo "✅ Pro Garage OS API ready at http://${API_DOMAIN}/api/health (after DNS propagates)"
echo "   DNS: A record ${API_DOMAIN} → 69.62.78.240"
echo "   Then run: bash $APP_DIR/repo/deploy/hostinger/scripts/enable-ssl.sh"
