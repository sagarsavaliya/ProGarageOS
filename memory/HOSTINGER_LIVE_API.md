# Pro Garage OS — Hostinger KVM2 Live API

## Server
- **VPS:** Hostinger KVM2 — `69.62.78.240` (alias: `hostinger-vps`)
- **API URL:** `https://api.progarageos.com/api` (after DNS + SSL)
- **Health:** `GET /api/health` → `"api": "progarageos"`
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
Optional offline dev only (`Apps/api/docker-compose.yml`). Phone testing uses live API.

## Login (seeded)
Use same staff credentials from database seeders after first `db:seed`.

---

## Safe deploy on shared VPS (VastraOS, LactoSync, n8n, Portainer)

**Nothing below touches existing production apps.** Each change is isolated.

| Step | What it does | Risk to existing apps |
|------|----------------|----------------------|
| New Docker network `progarage_network` | Private network for MySQL, Redis, API, nginx | **None** — separate bridge |
| Join existing `proxy-net` | Only `progarage_nginx` container added | **None** — same pattern as VastraOS/LactoSync |
| New containers `progarage_*` | 4 new containers on dedicated ports internally | **None** — no host port binding except via proxy |
| New file `nginx-proxy/conf.d/progarage-http.conf` | Routes `api.progarageos.com` → `progarage_nginx` | **None** — unique `server_name`; existing domains unchanged |
| `/var/www/progarage/` directory | New app folder only | **None** |

**Not changed without your approval:**
- Existing `vastraos.conf`, `lactosync.conf`, `n8n.conf`
- Portainer, n8n, LactoSync, VastraOS containers or volumes
- Default nginx-proxy SSL certificates for other domains

**One decision needed:** HTTP config includes bare IP `69.62.78.240` for pre-DNS testing. If another app also claims the IP on port 80, we can remove the IP from `server_name` and use domain-only routing.

**Partial bootstrap status:** Repo cloned to `/var/www/progarage/repo`; Docker API image build was in progress when last interrupted. Safe to resume — no production configs were modified yet.
