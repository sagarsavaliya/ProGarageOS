# Speed up local Docker API — run after pulling changes or when API feels slow.
# Usage (PowerShell, from Apps/api):
#   .\scripts\optimize-dev.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Recreating app container with fast vendor volume..." -ForegroundColor Cyan
docker compose up -d --force-recreate app nginx

Write-Host "Installing dependencies into Linux vendor volume (one-time, ~1-2 min)..." -ForegroundColor Cyan
docker compose exec app composer install --no-interaction --optimize-autoloader --prefer-dist

Write-Host "Caching Laravel config + routes..." -ForegroundColor Cyan
docker compose exec app php artisan config:cache
docker compose exec app php artisan route:cache

Write-Host "Benchmark /api/health (3 requests)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    curl.exe -s -o NUL -w "  request $_ : %{time_total}s`n" http://127.0.0.1:8000/api/health
}

Write-Host "Done. Target: under 200ms per request after warm-up." -ForegroundColor Green
Write-Host "If still slow, move the repo into WSL2 (~/projects) instead of D:\ drive." -ForegroundColor Yellow
