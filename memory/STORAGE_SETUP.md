# Pro Garage — Production R2 setup (Option B — custom domain)

**Target:** `https://files.progarage.cloud` for all tenant file URLs  
**API stays on Hostinger:** `https://api.progarage.cloud` (unchanged)

---

## Architecture (production)

```
Garage owner phone  →  api.progarage.cloud (Hostinger VPS, Laravel)
                              ↓ uploads via S3 API (private)
                         Cloudflare R2 bucket: progarageos
                              ↓ public read
Garage owner phone  →  files.progarage.cloud/{path}  (Cloudflare SSL)
```

- **No r2.dev** — custom domain only  
- **DNS for `files`** lives in **Cloudflare** (required for R2 custom domains)  
- **`api.progarage.cloud`** can stay pointing to Hostinger (grey-cloud / DNS-only in Cloudflare)

---

## PART 1 — Your steps (Cloudflare + DNS)

### Step 1 — Add domain to Cloudflare

1. Log in [Cloudflare Dashboard](https://dash.cloudflare.com)  
2. **Add a site** → enter `progarage.cloud`  
3. Choose **Free** plan (sufficient for R2 custom domain + DNS)  
4. Cloudflare scans existing DNS — **review records** (copy anything missing from Hostinger)

### Step 2 — Move DNS authority to Cloudflare (one-time)

At **Hostinger** (domain registrar / DNS):

1. Open domain **progarage.cloud** → Nameservers  
2. Replace Hostinger NS with the **two Cloudflare nameservers** Cloudflare shows you  
3. Wait 15 min – 24 hrs for propagation (usually under 1 hour)

> Your website, email, and API records must exist in **Cloudflare DNS** before/after the switch. Export Hostinger DNS first so nothing breaks.

### Step 3 — DNS records in Cloudflare (minimum)

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| A | `api` | Hostinger VPS IP (same as today) | **DNS only** (grey cloud) |
| A or CNAME | `@` / `www` | Your site (Hostinger or other) | As you prefer |
| *(auto)* | `files` | Created by R2 in Step 4 | Proxied (orange) |

**Important:** Set `api` to **DNS only** (grey cloud) so Laravel/API traffic goes direct to VPS without Cloudflare HTTP proxy issues.

### Step 4 — R2 bucket + custom domain

1. R2 → bucket **`progarageos`** (confirm name)  
2. **Settings → Custom Domains → Connect Domain**  
3. Enter: `files.progarage.cloud`  
4. Cloudflare creates DNS + SSL automatically  
5. Wait until status shows **Active**

Do **not** enable r2.dev public URL for production.

### Step 5 — New API token (rotate the leaked key)

1. R2 → **Manage R2 API Tokens** → **Create API token**  
2. Permissions: **Object Read & Write** on bucket `progarageos` only  
3. Save **Access Key ID** + **Secret Access Key** (shown once)  
4. **Delete/revoke** the old token you pasted in chat  

Send new keys via **secure channel only** (not GitHub/chat).

### Step 6 — CORS on bucket (production)

R2 → `progarageos` → **Settings → CORS** → add rule:

- Allowed origins: `https://api.progarage.cloud`, `https://progarage.cloud`  
- Methods: `GET`, `HEAD`  
- Max age: `3600`

(Mobile app loads URLs returned by API; this covers web admin / future web app.)

### Step 7 — Confirm and send us

| Item | Example |
|------|---------|
| Bucket name | `progarageos` |
| Account ID | (you have this) |
| New Access Key + Secret | (secure handoff) |
| Public base URL | `https://files.progarage.cloud` |
| Custom domain status | Active in R2 dashboard |

Reply: **“R2 production ready — wire server”**

---

## PART 2 — Our steps (after you confirm)

1. Update Hostinger `/var/www/progarage/.env`:
   ```env
   FILESYSTEM_DISK=s3
   AWS_ACCESS_KEY_ID=...
   AWS_SECRET_ACCESS_KEY=...
   AWS_DEFAULT_REGION=auto
   AWS_BUCKET=progarageos
   AWS_ENDPOINT=https://42151e0b20602de36153052f0790edbc.r2.cloudflarestorage.com
   AWS_URL=https://files.progarage.cloud
   AWS_USE_PATH_STYLE_ENDPOINT=true
   ```
2. `php artisan config:clear && php artisan config:cache`  
3. Deploy code update: storage paths → `tenants/{id}/…` layout (inspection, docs, signatures, invoices)  
4. Upload test from staff app → verify file in R2 + opens at `https://files.progarage.cloud/...`  
5. Update `memory/STATUS.md`

**No Flutter rebuild** for storage wiring.

---

## Bucket path layout (final — code will use this)

```
progarageos/
  tenants/{tenant_id}/
    avatars/
    docs/{vehicle_uuid}/
    inspection/intake/{job_uuid}/
    inspection/delivery/{job_uuid}/
    signatures/{job_uuid}/
    invoices/
```

Empty folders in R2 UI are optional.

---

## Checklist (printable)

**You (Cloudflare + Hostinger)**  
- [ ] `progarage.cloud` added to Cloudflare  
- [ ] Nameservers switched Hostinger → Cloudflare  
- [ ] `api.progarage.cloud` → VPS IP (grey cloud)  
- [ ] R2 custom domain `files.progarage.cloud` → **Active**  
- [ ] New R2 API token; old token revoked  
- [ ] CORS configured  
- [ ] Secure handoff of new keys + “wire server” go-ahead  

**Us (Akshara)**  
- [x] Production `.env` on Hostinger  
- [x] Code: tenant-scoped paths + invoices/signatures on R2  
- [ ] End-to-end upload test (staff app → `files.progarage.cloud`)  
- [x] Document in STATUS  

---

## FAQ

**Do we move the whole website off Hostinger?**  
No. Only **DNS control** moves to Cloudflare. VPS, API, and hosting can stay on Hostinger. Cloudflare only routes traffic.

**Will API break when we change nameservers?**  
Not if you recreate the `api` A record in Cloudflare **before** switching NS (grey cloud).

**Custom domain without Cloudflare NS?**  
R2 custom domains require the zone in Cloudflare. r2.dev avoids that but is not production-grade — you chose Option B correctly.

**Rotate keys again?**  
Yes — any key ever pasted in chat should be treated as compromised.
