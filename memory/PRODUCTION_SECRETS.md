# Pro Garage OS — Production Secrets Guide

## Where secrets live

| Location | When to use |
|----------|-------------|
| **Hostinger** `/var/www/progarage/.env` | **Production API** — WhatsApp, FCM, R2, DB |
| **Local** `Apps/api/.env` | Dev only — never deploy this file |
| **GitHub Secrets** | CI/CD deploy pipeline only (not built yet) |
| **Future:** Owner Integrations UI | Encrypted DB — no redeploy (see `INTEGRATIONS_STRATEGY.md`) |

Never commit real secrets to the repo.

---

## WhatsApp (Meta Cloud API) — ✅ on production server

Configured in `/var/www/progarage/.env`:

| Variable | Purpose |
|----------|---------|
| `WHATSAPP_TOKEN` | Meta permanent/system user access token |
| `WHATSAPP_PHONE_NUMBER_ID` | Sending phone number ID |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | WABA ID |
| `WHATSAPP_OTP_TEMPLATE` | Approved auth template name |
| `WHATSAPP_TEMPLATE_LANGUAGE` | e.g. `en` |
| `WHATSAPP_API_VERSION` | e.g. `v20.0` |

**After changing any value on server:**
```bash
docker exec progarage_api php artisan config:clear
docker exec progarage_api php artisan config:cache
```
No Flutter rebuild required.

**Rotate token:** Meta Business Manager → generate new token → update `.env` → config cache (above).

---

## Optional — enable when feature goes live

| Feature | Variables |
|---------|-----------|
| Push notifications | `FCM_SERVER_KEY` |
| Inspection photos (R2) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`, `AWS_ENDPOINT`, `AWS_URL` |
| Email | `MAIL_MAILER`, `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD` |

---

## GitHub Actions (future)

When CI is added: `HOSTINGER_SSH_KEY`, `HOSTINGER_HOST`, optional `PROGARAGE_ENV_FILE`.  
WhatsApp vars can stay server-only — simpler and more secure for now.
