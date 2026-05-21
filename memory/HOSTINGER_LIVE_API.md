# Pro Garage OS — Hostinger KVM2 Live API

## Server
- **VPS:** Hostinger KVM2 — `69.62.78.240` (alias: `hostinger-vps`)
- **API URL (temp):** `https://api.progarage.cloud/api`
- **Future domain:** `api.progarageos.com` (swap via `deploy/hostinger/domain.env`)
- **Health:** `GET /api/health` → `"api": "progarageos"`
- **Repo:** [ProGarageOS on GitHub](https://github.com/sagarsavaliya/ProGarageOS.git)

## DNS (temporary — progarage.cloud)
| Record | Type | Name/Host | Value |
|--------|------|-----------|-------|
| API | **A** | `api` | `69.62.78.240` |

**Do not change** existing `@` → `2.57.91.91` or `www` CNAME unless you want the landing page on Hostinger too.

## Flutter staff app
`Apps/flutter/.env`:
```
API_BASE_URL=https://api.progarage.cloud/api
APP_ENV=production
```

## Deploy / update on server
```bash
ssh hostinger-vps
bash /var/www/progarage/repo/deploy/hostinger/scripts/redeploy.sh
```

## SSL (after DNS propagates)
```bash
bash /var/www/progarage/repo/deploy/hostinger/scripts/enable-ssl.sh
```

## Switch to progarageos.com later
1. Update `deploy/hostinger/domain.env` → `API_DOMAIN=api.progarageos.com`
2. Update nginx-proxy configs + `.env.production.example` URLs
3. New DNS A record → `69.62.78.240`
4. Run `enable-ssl.sh` for new cert
5. Update Flutter `API_BASE_URL`

Single source of truth for temp domain: **`deploy/hostinger/domain.env`**

## Login (seeded)
Staff credentials from database seeders after first `db:seed`.
