#!/bin/sh
set -e

cd /var/www/html

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

if [ -n "$APP_KEY" ] && [ "$APP_KEY" != "" ]; then
    :
elif [ -f ".env" ]; then
    php artisan key:generate --force 2>/dev/null || true
fi

php artisan storage:link 2>/dev/null || true

if [ "${MIGRATE_ON_START:-0}" = "1" ]; then
    php artisan migrate --force 2>&1 || true
fi

if [ "${OPTIMIZE_ON_START:-0}" = "1" ]; then
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true
fi

exec "$@"
