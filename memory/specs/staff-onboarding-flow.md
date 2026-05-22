# Staff App — Onboarding Flow (Option B spec)
# Updated: 2026-05-21 — hardened for production resume

## Two onboarding moments

### A) First install (all users) — 3 slides, once per device
Shown after splash, **before login**, only if `onboarding_completed` flag not set in secure storage.

| Slide | Headline | Body |
|-------|----------|------|
| 1 | Run your garage from one app | Jobs, customers, parts, and billing in your pocket |
| 2 | Capture every vehicle properly | Intake inspection with photos and damage map |
| 3 | Get paid faster | GST invoices and collect payment on the spot |

Actions: **Skip** · **Next** · **Get started** (→ Login)

---

### B) First owner login — setup wizard (resume-safe)

**Server source of truth:** `tenants.setup_step`, `setup_bay_count`, `setup_completed_at`

**Local draft backup:** encrypted storage `setup_draft_{tenantUuid}` — auto-saves every ~450ms and on step change. Survives crash before API save.

| Step | API key | What happens |
|------|---------|--------------|
| 0 Welcome | `welcome` | Continue → sync step `details` |
| 1 Garage details | `details` | Save & continue → PUT profile + step `bays` |
| 2 Service bays | `bays` | Continue → PATCH step `done` + bay count |
| 3 Done | `done` | Go to dashboard → PATCH `complete=true` |

**Finish later** (was Skip): saves draft + current step to server, goes to dashboard. Setup **not** marked complete. Settings shows **Complete setup**.

**On reopen:** loads server step → opens wizard at that step. Fields pre-fill from API + local draft merge.

**Offline:** shows draft with banner; retries sync when connection returns.

---

## Navigation rules
- First install: Splash → Onboarding A → Login
- Owner incomplete setup: Login → Wizard at **saved step**
- Owner complete: Login → Dashboard
- Technicians: always Dashboard
- Resume: Settings → Complete setup

---

## API
- `GET /tenant/profile` — includes setup fields
- `PUT /tenant/profile` — garage details
- `PATCH /tenant/setup` — `{ setup_step, setup_bay_count?, complete? }`

---

## Out of scope v1
- Video tutorials, Hindi localization
- Customer app onboarding
- Km-threshold GPS push (customer app Phase 2)
