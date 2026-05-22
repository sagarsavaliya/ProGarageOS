# Pro Garage OS — Production Runbook

**API:** `https://api.progarage.cloud/api`  
**Health:** `GET /api/health`

---

## Deploy API (Hostinger)

```bash
cd /path/to/ProGarage
./deploy/hostinger/scripts/redeploy.sh
```

Script runs: pull, composer install, `php artisan migrate --force`, config/route cache, container restart.

### Post-deploy verify

```bash
curl -s https://api.progarage.cloud/api/health
```

Expected: `{"status":"ok","api":"progarageos",...}`

---

## Pending migrations (as of Pack 4)

Run once on production:

- `2026_05_21_000001_add_staff_pin_otp_and_setup_to_users.php`
- `2026_05_21_000002_create_tenant_integrations_table.php`
- `2026_05_21_100000_add_insurance_fields_to_service_jobs.php`
- `2026_05_21_100001_seed_accident_repair_service_categories.php`
- `2026_05_21_110000_add_setup_fields_to_tenants.php`

---

## Invoice PDFs

- Generated on demand: `GET /api/invoices/{uuid}/pdf`
- Stored on `public` disk: `storage/app/public/invoices/{tenant_id}/{uuid}.html`
- Requires: `php artisan storage:link` on server

---

## Staff app device test (E2E)

Login: `8141302341` / `123456` (Patel Auto Works)

| # | Flow | Pass |
|---|------|------|
| 1 | Login → dashboard loads KPIs | ☐ |
| 2 | Book appointment → check-in → job created | ☐ |
| 3 | Job detail → activity log visible (owner) | ☐ |
| 4 | Create invoice → View PDF → Share | ☐ |
| 5 | Record payment → appears in Payments hub | ☐ |
| 6 | Settings → Fleet → search vehicle → detail | ☐ |
| 7 | Notification tap opens job or invoice | ☐ |

---

## Rollback

1. Revert git tag on server to last known good
2. Re-run redeploy script
3. Do **not** rollback migrations unless DBA review — forward-fix preferred

---

## Support contacts

- **CEO:** Sagar — Akshara Technologies
- **API logs:** Docker logs on Hostinger VPS (`docker compose logs -f api`)
