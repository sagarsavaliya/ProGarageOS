#!/bin/sh
set -e

READY_MARKER=".garageflow_ready"

if [ ! -f "$READY_MARKER" ]; then
    echo "================================================================"
    echo " GarageFlow: First run — installing Laravel 11 (~2 mins)..."
    echo "================================================================"

    # Clean any leftover temp dir from a previous crashed install
    rm -rf /tmp/laravel

    # Install Laravel into a temp dir (avoids non-empty dir restriction)
    composer create-project laravel/laravel:^11.0 /tmp/laravel --prefer-dist --no-interaction

    echo ">>> Merging Laravel files into /var/www/html ..."

    # Copy each top-level item from the Laravel install only if it does NOT already
    # exist in our workspace. This preserves all our custom files while pulling in
    # everything Laravel needs (artisan, vendor, config, public, etc.).
    for src in /tmp/laravel/*; do
        dest="/var/www/html/$(basename "$src")"
        if [ ! -e "$dest" ]; then
            cp -r "$src" "$dest"
            echo "    copied: $(basename "$src")"
        else
            echo "    kept existing: $(basename "$src")"
        fi
    done

    # Copy hidden files (e.g. .gitignore, .gitattributes) — but never overwrite .env
    for src in /tmp/laravel/.[!.]*; do
        name="$(basename "$src")"
        dest="/var/www/html/$name"
        if [ "$name" = ".env" ] || [ "$name" = ".env.example" ]; then
            echo "    skipped (using our copy): $name"
            continue
        fi
        if [ ! -e "$dest" ]; then
            cp -r "$src" "$dest"
        fi
    done

    # Merge sub-directories that may have BOTH Laravel defaults AND our custom files
    # (app/, bootstrap/) — copy only what we haven't provided
    for subdir in app bootstrap; do
        if [ -d "/tmp/laravel/$subdir" ]; then
            find "/tmp/laravel/$subdir" -type f | while read src_file; do
                rel="${src_file#/tmp/laravel/}"
                dest_file="/var/www/html/$rel"
                if [ ! -f "$dest_file" ]; then
                    mkdir -p "$(dirname "$dest_file")"
                    cp "$src_file" "$dest_file"
                fi
            done
        fi
    done

    rm -rf /tmp/laravel

    echo ">>> Verifying artisan exists ..."
    if [ ! -f "artisan" ]; then
        echo "ERROR: artisan was not copied. Aborting." >&2
        exit 1
    fi

    # Generate app key if not already set in our custom .env
    php artisan key:generate --force 2>/dev/null || true

    # Install Sanctum
    composer require laravel/sanctum --no-interaction --no-progress --quiet
    php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider" --force 2>/dev/null || true

    # Drop all tables and re-run every migration from scratch (clean first install)
    php artisan migrate:fresh --force

    # Seed demo data
    php artisan db:seed --force

    touch "$READY_MARKER"
    echo "================================================================"
    echo " GarageFlow: API ready at http://localhost:8000"
    echo "================================================================"
else
    # Subsequent starts: vendor lives on a Linux volume (fast). Host vendor/ is ignored.
    if [ ! -f "vendor/autoload.php" ]; then
        echo ">>> Installing Composer dependencies into garageflow_vendor volume ..."
        composer install --no-interaction --optimize-autoloader --prefer-dist
    fi

    # Migrations only when explicitly requested (avoids slow startup every restart)
    if [ "${MIGRATE_ON_START:-0}" = "1" ]; then
        php artisan migrate --force 2>&1 || true
    fi

    if [ "${OPTIMIZE_ON_START:-0}" = "1" ] && [ -f "artisan" ]; then
        php artisan config:cache 2>/dev/null || true
        php artisan route:cache 2>/dev/null || true
    fi

    php artisan storage:link 2>/dev/null || true
fi

exec "$@"
