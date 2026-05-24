# PROJECT STATUS

---

## Overall Status
- **Project:** Pro Garage OS (ProGarageOS)
- **Infrastructure:** ✅ Live — `https://api.progarage.cloud/api` (commit `f67bc50`)
- **File storage:** ✅ R2 wired — uploads go to bucket `progarageos`; URLs use `https://files.progarage.cloud`
- **Self-signup API:** ✅ Deployed — plans + owner signup live on production
- **Staff app:** ✅ APK built — `Apps/flutter/build/app/outputs/flutter-apk/app-release.apk` (63.4MB, `6b10d65`)
- **Platform admin:** `Apps/web-admin` (legacy) — superseded by `Apps/web`
- **Web app:** `Apps/web` — staff + super-admin portals (GarageFlow design)
- **Last Updated:** 2026-05-24 IST
- **Next APK version:** bump `pubspec.yaml` before build (currently `1.1.0+2` for next release)

---

## ✅ Fixed today (verified against production API)
| Issue | Root cause | Fix |
|-------|------------|-----|
| Invoice detail “failed to load” | API returns vehicle `year` as `"2021"` (string); app cast as number → crash | Safe parsing + API casts year to int |
| Fleet tap → vehicle blank/error | Screen required customer vehicle list; Fleet didn’t load vehicle directly | Always `GET /vehicles/{uuid}` for detail |

---

## ⚠️ Install instructions (important)
1. **Uninstall** the old Pro Garage app from your phone
2. Install **APK** at `Apps/flutter/build/app/outputs/flutter-apk/app-release.apk` (commit `6b10d65`)
3. **Self-signup:** Login → *New garage? Create your account* → use `8141302341` or any new number
4. **Demo garage:** `9876543219` / `123456`

---

## ✅ Self-signup live on production (`6b10d65`)
- `GET /api/subscription-plans` — Starter / Pro / Enterprise
- `POST /api/auth/owner/signup` — new garage registration
- Platform admin seeded: `admin@progarage.cloud` / `999999`
- Demo garage: `9876543219` / `123456`
- Docs: `memory/SELF_SIGNUP_AND_ADMIN.md`

## 🔲 UI polish batch (in same APK build)
- Jobs: tighter Call / Inspect chips
- Edit vehicle: orange fuel pills, GPS consent loads from API
- Fleet (Settings): back → Settings when opened via `go`
- Job detail: insurance status grid (3 cols, compact)
- Intake inspection: scroll locked while signing
- Server: `php artisan progarage:reset-tenant-data --phone=8141302341 --reset-onboarding --force` (after deploy)
- Storage checklist: `memory/STORAGE_SETUP.md`

## ⚠️ Web app — production rebuild in progress
- **Live URLs:** https://app.progarage.cloud · https://admin.progarage.cloud
- **Current state:** Skeleton only — NOT production-ready (Sagar review May 24)
- **Task plan:** `memory/tasks/web-app-tasks.md` (phased, Flutter parity + design files)
- **Immediate fix:** Staff login phone field (deploy pending)

## 🔲 Tomorrow / next session
- Device retest: self-signup (`8141302341`) + demo garage (`9876543219`)
- **Verify R2 public URLs:** upload vehicle doc or inspection photo from staff app → confirm opens at `files.progarage.cloud`
- Rebuild APK after retest fixes — **bump `pubspec.yaml` version first**
- Staff v1 sign-off → customer app C0
