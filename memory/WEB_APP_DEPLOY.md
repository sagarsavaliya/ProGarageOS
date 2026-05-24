# Pro Garage Web App — Production Deployment

## Subdomains (required)

| Portal | URL | Who uses it |
|--------|-----|-------------|
| **Staff / garage web** | `https://app.progarage.cloud` | Owners, managers, advisors |
| **Platform super-admin** | `https://admin.progarage.cloud` | Akshara platform ops only |
| **API** (unchanged) | `https://api.progarage.cloud` | All clients |

One codebase (`Apps/web`) serves both portals. The browser hostname selects the portal:
- `admin.*` → super-admin UI (blocks non-platform users)
- everything else → staff/garage UI (blocks platform admins)

## DNS (Cloudflare)

Add **A records** (DNS only / grey cloud for VPS):

| Name | Target |
|------|--------|
| `app` | Hostinger VPS IP |
| `admin` | Hostinger VPS IP |

## Deploy

```bash
cd /var/www/progarage/repo
git pull origin main
bash deploy/hostinger/scripts/redeploy.sh
```

Copy nginx proxy configs (HTTP first, then SSL):

```bash
cp deploy/hostinger/nginx-proxy/app-http.conf /var/www/nginx-proxy/conf.d/progarage-app.conf
cp deploy/hostinger/nginx-proxy/admin-http.conf /var/www/nginx-proxy/conf.d/progarage-admin.conf
docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload
```

## SSL (after DNS propagates)

```bash
certbot certonly --webroot -w /var/www/certbot -d app.progarage.cloud --non-interactive --agree-tos -m admin@progarage.cloud
certbot certonly --webroot -w /var/www/certbot -d admin.progarage.cloud --non-interactive --agree-tos -m admin@progarage.cloud
cp deploy/hostinger/nginx-proxy/app.conf /var/www/nginx-proxy/conf.d/progarage-app.conf
cp deploy/hostinger/nginx-proxy/admin.conf /var/www/nginx-proxy/conf.d/progarage-admin.conf
docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload
```

## Test accounts

| Portal | Login | PIN |
|--------|-------|-----|
| Staff (`app`) | `9876543219` | `123456` |
| Admin (`admin`) | `admin@progarage.cloud` | `999999` |

## Local dev

```bash
cd Apps/web && npm install && npm run dev
# Staff: http://localhost:5173
# Admin: VITE_PORTAL=admin npm run dev
```
