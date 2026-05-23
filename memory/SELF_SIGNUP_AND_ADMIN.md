# Self-signup & platform admin

## Owner self-signup (staff app)

1. Login screen → **New garage? Create your account**
2. Fill garage name, owner name, phone, pick plan
3. **Create garage account** → WhatsApp PIN setup (`/auth/staff-pin` purpose `setup`)
4. Set 6-digit PIN → login → setup wizard

**API**

- `GET /api/subscription-plans` — public
- `POST /api/auth/owner/signup` — creates tenant + trial subscription + owner (`requires_pin_setup`)

## Demo vs your numbers

| Use | Phone | PIN |
|-----|-------|-----|
| Demo garage (Patel Auto Works) | `9876543219` | `123456` |
| Your real number | `8141302341` | — use **customer OTP login** in app |
| Platform super-admin (web) | `admin@progarage.cloud` or `9988877766` | `999999` |

## Platform admin web UI

`Apps/web-admin` — React + Vite

```bash
cd Apps/web-admin && npm install && npm run dev
```

Routes under `/api/platform/*` (requires `is_platform_admin` token).

## Deploy checklist

1. Deploy API (includes new routes)
2. Seed plans: `php artisan db:seed --class=SubscriptionPlanSeeder`
3. Seed platform admin: `php artisan db:seed --class=PlatformAdminSeeder`
4. Update demo owner phone on production if needed
5. New staff APK with signup screen
6. Run web-admin locally or host on subdomain
