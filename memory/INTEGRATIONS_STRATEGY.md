# Pro Garage OS — Integrations & Secrets Strategy (Production)

## Current state (May 2026)

| Integration | Where configured | UI today | App rebuild? |
|-------------|------------------|----------|--------------|
| **WhatsApp (Meta)** | Server `/var/www/progarage/.env` | ❌ No | ❌ No (API only) |
| **API URL (Flutter)** | `Apps/flutter/.env` | ❌ No | ✅ Yes (compile-time) |
| **FCM push** | Server `.env` | ❌ No | ❌ No |
| **R2 storage** | Server `.env` | ❌ No | ❌ No |

WhatsApp is **live on production** after server `.env` sync + `config:cache`.

---

## Recommended production model (3 layers)

### Layer 1 — Platform secrets (Akshara / you)
**Examples:** Meta system user token, FCM server key, R2 keys, mail SMTP  
**Store:** Hostinger `.env` OR encrypted `platform_settings` DB table  
**Who edits:** You only (SSH, Portainer env, or future **Platform Admin** web UI)  
**Never:** Flutter app, GitHub repo, or staff settings screen

### Layer 2 — Tenant integrations (each garage — Phase 2)
**Examples:** Own WhatsApp Business number, payment gateway, GST API  
**Store:** `tenant_integrations` table — Laravel `encrypted` cast  
**Who edits:** **Owner role** in app → Settings → Integrations  
**Changes:** Instant via API — **no redeploy, no app rebuild**  
**UI shows:** Masked token (`•••••••2688`), template names, toggles, **Test connection**

### Layer 3 — Operational settings (non-secret)
**Examples:** Template language, reminder channel, business hours  
**Store:** `tenants.settings` JSON  
**Who edits:** Owner in Settings — safe for staff app UI

---

## What NOT to do (production)

- ❌ Put Meta tokens in Flutter `.env` or Settings screen as plain text visible to technicians  
- ❌ Commit tokens to GitHub (even private repo)  
- ❌ Require app rebuild when WhatsApp token rotates — API must read runtime config  

---

## Build order (suggested)

1. **Now:** Platform WhatsApp via server `.env` (done) — one number for all demo/live garages  
2. **Wave 3:** Owner → Settings → Integrations API + Flutter screen (owner-only)  
3. **Later:** Web owner portal for full integration management + audit log  
4. **Optional:** Meta webhook endpoint for delivery receipts  

---

## Token rotation (no app rebuild)

1. Update token in server `.env` (or Integrations UI when built)  
2. Run: `docker exec progarage_api php artisan config:clear && php artisan config:cache`  
3. Or redeploy script — **Flutter unchanged**
