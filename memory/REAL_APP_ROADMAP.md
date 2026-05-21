# GarageFlow — Production App Roadmap (Staff Mobile)
# Mode: REAL APP — not MVP placeholders. Updated: 2026-05-19
# Source of truth for sprint order. PRD/API in briefs/ — do not re-read full PRD each session.

## Quality bar (every screen before “done”)
- Wired to **real API** (Laravel); demo fallback only when network fails, never as primary path
- **Validation + error states** (field-level, retry, empty states)
- **Business rules** from PROJECT_CONTEXT.md (tenant scope, job status machine, GST, audit)
- **Device test** on Sagar’s Android (CPH2525) before sprint closes
- `flutter analyze` clean; no new “Coming Soon” routes

## Current inventory (honest)

| Screen / flow | Design | Built | Gap |
|---------------|--------|-------|-----|
| Splash, Login | 01–02 | ✅ | Polish only |
| Dashboard | 03 | ✅ | Live API + notifications (S8 partial) |
| Jobs list + detail | 04, 06 | ✅ | Status actions, tasks, estimate flow thin |
| Create Job + Intake | 05, 07 | ✅ | Needs API hardening, photo upload, real inspection save |
| Customers list + detail | 08, 09 | ✅ | **Add Customer missing** |
| Invoice detail | 10 | ✅ | **Create Invoice missing** |
| Parts list + detail | — | ✅ | **Add Part missing** |
| FAB “+” routes | — | ⚠️ | Jobs ✅; Customer/Invoice/Part = Coming Soon |

## Build order (workflow-first — how garages actually work)

### Phase 0 — Device & API baseline (0.5 day)
- Fresh APK on phone after every phase
- Docker API up; firewall rule for port 8000 on hotspot
- FCM_SERVER_KEY when ready for real push

### Phase 1 — Master data (3–4 days)
1. **Add Customer** — POST /customers, phone uniqueness, garage profile
2. **Add Vehicle** — from customer detail, POST /vehicles
3. Remove demo-only create paths; E2E: create customer → vehicle → job

### Phase 2 — Job lifecycle complete (4–5 days)
4. Harden **Create Job** (categories attach API, real bays/tech from API)
5. Harden **Intake Inspection** (persist records, photos → R2 stub/local queue)
6. **Job detail actions** — status transitions per state machine, task list, estimate send
7. Job → ready for delivery flow

### Phase 3 — Inventory (2–3 days)
8. **Add Part** — POST /inventory, categories, SKU rules
9. Stock adjustment sheet — real PATCH, low-stock push triggers

### Phase 4 — Billing (3–4 days)
10. **Create Invoice** from job — line items, GST breakdown, POST /invoices
11. **Record payment** — partial/full, balance due, receipt state
12. Invoice PDF generation (queue) — view/share

### Phase 5 — Realtime & ops (2–3 days)
13. Finish push (FCM + inbox sync, job/reminder events)
14. Appointment / service reminders (queue jobs)
15. Dashboard KPIs from live API only

### Phase 6 — Growth features (post staff-app core)
16. Loyalty ledger + CSAT
17. Razorpay + GPS (consent-first)
18. React owner dashboard (deferred until staff app shippable)

## Per-sprint ritual
1. API contract check (briefs/API_Specification.md)
2. Implement screen + repository + provider
3. Seed/test with Patel Auto Works tenant data
4. `flutter run` on device — Sagar sign-off
5. Update PROGRESS.md + STATUS.md

## Anti-patterns to avoid (learned from current build)
- “Coming Soon” stubs on primary FAB actions
- Static demo lists (bays, technicians) when API exists
- Status API values mismatch (e.g. `inspecting` vs `intake_inspection`) — align Flutter ↔ Laravel
- Skipping offline: use **queued writes** (Drift) later; Phase 1–4 require online correctness first

## Next action (immediate)
**Phase 1, Screen 1: Add Customer** → then device test → then Add Vehicle.
