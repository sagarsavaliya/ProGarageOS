# Pro Garage OS — Production Secrets Guide

## Where secrets live

| Location | When to use |
|----------|-------------|
| **Hostinger** `/var/www/progarage/.env` | **Now** — live API reads secrets here |
| **GitHub → Settings → Secrets** | Only when you add CI/CD (GitHub Actions deploy). **Not required today.** |

Never commit real secrets to the repo.

---

## Required today (already on server)

These are auto-generated at bootstrap — no GitHub action needed:

- `APP_KEY` — Laravel encryption key
- `DB_PASSWORD` / `DB_ROOT_PASSWORD` — MySQL (in server `.env` only)

---

## WhatsApp (Meta Cloud API)

Add to **server** `/var/www/progarage/.env`, then redeploy:

| Variable | Where to get it |
|----------|-----------------|
| `WHATSAPP_TOKEN` | Meta Business → WhatsApp → API Setup → temporary or permanent access token |
| `WHATSAPP_PHONE_NUMBER_ID` | Same page — Phone number ID |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | Meta Business Settings → WhatsApp Business Account ID |
| `WHATSAPP_API_VERSION` | `v20.0` (default) |
| `WHATSAPP_TEMPLATE_LANGUAGE` | `en` |
| `WHATSAPP_OTP_TEMPLATE` | Approved template name in Meta (default: `pro_garage_otp`) |

Optional template overrides: `WHATSAPP_JOB_STATUS_TEMPLATE`, `WHATSAPP_INVOICE_TEMPLATE`, etc. (see `Apps/api/config/whatsapp.php`)

After adding, run on server:
```bash
bash /var/www/progarage/repo/deploy/hostinger/scripts/redeploy.sh
```

**GitHub secrets (if CI later):** same names prefixed e.g. `PROGARAGE_WHATSAPP_TOKEN` — inject into deploy step.

---

## Optional — enable when feature goes live

| Feature | Variables |
|---------|-----------|
| Push notifications | `FCM_SERVER_KEY`, `FIREBASE_CREDENTIALS` |
| Inspection photo storage | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`, `AWS_ENDPOINT`, `AWS_URL` (Cloudflare R2) |
| Transactional email | `MAIL_MAILER`, `MAIL_HOST`, `MAIL_USERNAME`, `MAIL_PASSWORD` |
| WebSockets (later) | `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET` |

---

## GitHub Actions (future deploy pipeline)

When you add `.github/workflows/deploy.yml`, typical secrets:

| GitHub Secret | Purpose |
|---------------|---------|
| `HOSTINGER_SSH_KEY` | Private key for `hostinger-vps` |
| `HOSTINGER_HOST` | `69.62.78.240` |
| `PROGARAGE_ENV_FILE` | Full production `.env` contents (or individual vars) |

WhatsApp/FCM/R2 can be stored as GitHub secrets and written to server `.env` during deploy — or managed directly on the VPS only (simpler for now).
