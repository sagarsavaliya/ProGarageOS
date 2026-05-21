# GarageFlow — Hostinger KVM2 Live API

## Server
- **VPS:** Hostinger KVM2 — `69.62.78.240` (alias: `hostinger-vps`)
- **API URL:** `https://api.progarageos.com/api` (after DNS + SSL)
- **Health:** `GET /api/health`
- **Repo:** [ProGarageOS on GitHub](https://github.com/sagarsavaliya/ProGarageOS.git)

## DNS (required once)
| Record | Type | Value |
|--------|------|-------|
| `api.progarageos.com` | A | `69.62.78.240` |

## Flutter staff app
Edit `Apps/flutter/.env`:
```
API_BASE_URL=https://api.progarageos.com/api
APP_ENV=production
```
Rebuild: `flutter run` on device.

## Deploy / update on server
```bash
ssh hostinger-vps
bash /var/www/progarage/repo/deploy/hostinger/scripts/redeploy.sh
```

## First-time bootstrap (on VPS)
```bash
git clone https://github.com/sagarsavaliya/ProGarageOS.git /var/www/progarage/repo
bash /var/www/progarage/repo/deploy/hostinger/scripts/server-bootstrap.sh
```

## SSL (after DNS propagates)
```bash
bash /var/www/progarage/repo/deploy/hostinger/scripts/enable-ssl.sh
```

## Local Docker
No longer required for phone testing. Keep `Apps/api/docker-compose.yml` only for optional offline dev.

## Login (seeded)
Use same staff credentials from database seeders after first `db:seed`.
