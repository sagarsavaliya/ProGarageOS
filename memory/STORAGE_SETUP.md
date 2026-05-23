# Pro Garage — Storage setup (production)

## What storage is used for

| Asset | Disk today | Path pattern |
|-------|------------|--------------|
| Invoice PDF/HTML | `public` (local) | `storage/app/public/invoices/{tenant_id}/` |
| Vehicle documents | default / `s3` when configured | `vehicles/{tenant_id}/` |
| Inspection photos | same as default disk | `inspections/{tenant_id}/` |

Until R2 is configured, files stay on the VPS under `storage/app/`.

---

## Step 1 — Local public disk (required now)

On the API server (inside the `progarage_api` container or deploy path):

```bash
php artisan storage:link
chmod -R 775 storage bootstrap/cache
```

Verify: `https://api.progarage.cloud/storage/` should not 404 for linked files.

---

## Step 2 — Cloudflare R2 (recommended before heavy photo testing)

### What you need from Cloudflare

1. R2 bucket (e.g. `progarage-production`)
2. **API token** with Object Read & Write on that bucket
3. **S3-compatible endpoint** (Account ID → R2 → S3 API), e.g.  
   `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
4. Optional: custom domain or public bucket URL for `AWS_URL`

### Server `.env` (Hostinger — not in git)

```env
FILESYSTEM_DISK=s3

AWS_ACCESS_KEY_ID=<R2_ACCESS_KEY_ID>
AWS_SECRET_ACCESS_KEY=<R2_SECRET_ACCESS_KEY>
AWS_DEFAULT_REGION=auto
AWS_BUCKET=progarage-production
AWS_ENDPOINT=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
AWS_URL=https://<your-public-or-r2-dev-url>
AWS_USE_PATH_STYLE_ENDPOINT=true
```

Then:

```bash
php artisan config:clear && php artisan config:cache
```

### Quick test

Upload a vehicle document or inspection photo from the staff app and confirm the file appears in the R2 bucket and opens via the returned URL.

---

## What to send Akshara to configure

- R2 bucket name
- Access key ID + secret (one-time, secure channel)
- Cloudflare account ID (for endpoint)
- Whether invoice PDFs should also move to R2 (currently local `public` is fine for PDFs)

---

## Order for your retest

1. ✅ Run `progarage:reset-tenant-data` (clean slate)
2. ✅ `storage:link` on server
3. ⏳ R2 keys in `.env` (when you have them)
4. Install new staff APK → login as owner → complete onboarding → test flows
