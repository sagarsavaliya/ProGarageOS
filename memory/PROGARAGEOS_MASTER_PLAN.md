# Pro Garage OS — Master Sprint Plan (Production Complete)
# Owner: Sagar | Akshara Technologies | Updated: 2026-05-19
# Strategy: **Staff / garage operations first (100% complete)** → **Customer app second (100% complete)** → Web owner portal third.

---

## Product split

| Product | Users | Goal |
|---------|--------|------|
| **Pro Garage OS Staff** (Flutter) | Owner, service advisor, technician, reception | Run the garage floor: jobs, intake, estimates, parts, billing, appointments |
| **Pro Garage OS Customer** (Flutter) | Vehicle owners | Track service, approve estimates, pay, book, loyalty |
| **Pro Garage OS Web** (React/Inertia) | Owner/manager (desk) | Reports, master data, staff admin, subscription — *after staff mobile v1* |

---

## Definition of “done” (every sprint)

- Wired to **real API**; demo data only when network fails, with **error + retry** (never silent fake lists)
- Validation, empty states, loading states on every screen
- Business rules from PRD (`tenant_id`, job status machine, GST, audit, consent)
- `flutter analyze` / PHP tests clean for touched code
- **Device sign-off** on Android (CPH2525) before sprint closes
- `PROGRESS.md` + `STATUS.md` updated

---

# PART A — PRO GARAGE OS (Staff Mobile + API)

**Current baseline (already built):** Login, dashboard, jobs list/detail/create, intake inspection + photos, status sheet, customers + add customer/vehicle, parts list/detail + add part + stock adjust, invoices list/detail + create + record payment, push inbox partial, API perf (Docker vendor volume).

**Remaining work:** Everything in the table below — no “partial” carry-forward.

---

## Sprint G0 — Production foundation (5 days)

**Goal:** Trustworthy platform; no MVP shortcuts.

| # | Feature | Deliverables |
|---|---------|----------------|
| G0-1 | Error handling standard | Shared API error widget; repositories throw/show retry; remove silent demo-as-primary on list screens |
| G0-2 | Environment & media | `APP_URL` / R2 docs; production `.env.example`; photo URLs work on physical device |
| G0-3 | API hardening | Route cache; indexes review; `GET /inventory/{uuid}`; `GET /payment-methods`; health + version endpoint |
| G0-4 | Auth polish | Logout everywhere; token refresh policy; lockout UX verified |
| G0-5 | Navigation completeness | “More” tab: Settings stub route, Notifications route (no Coming Soon on primary FABs) |

**Exit:** Owner can use app on phone against live API without seeing fake customers/jobs when API is up.

---

## Sprint G1 — Master data: customers & vehicles (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G1-1 | Edit customer | `PATCH /customers/{uuid}` + edit screen from profile |
| G1-2 | Edit vehicle | `PATCH /vehicles/{uuid}` + edit screen |
| G1-3 | Vehicle documents | Upload RC/insurance/PUC; expiry list; warnings on job create if expired |
| G1-4 | Service history | Customer/vehicle timeline (jobs + invoices) — premium timeline UI |
| G1-5 | Search & filters | Customer search debounce; vehicle from customer profile |

**Exit:** Full CRM loop for a walk-in customer without gaps.

---

## Sprint G2 — Jobs: create & assign (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G2-1 | Service categories API | `GET /service-categories`; create job uses tenant catalog (not static list) |
| G2-2 | Attach categories to job | `POST/PATCH` job ↔ `job_service_categories` |
| G2-3 | Edit job | Edit screen: complaint, priority, schedule, bay, technician |
| G2-4 | Job number & audit | Auto job number; audit log on create/update |
| G2-5 | List filters | Align status filters with API (`inspecting`, `quality_check`, etc.) |

**Exit:** Job creation matches how garages actually price work (by service type).

---

## Sprint G3 — Job tasks & workshop execution (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G3-1 | Tasks API | CRUD `job_tasks` (planned, discovered, approval required) |
| G3-2 | Tasks UI | Add/edit/complete tasks on job detail; assign technician |
| G3-3 | Parts on job | Link inventory item to task; auto stock decrement + ledger entry |
| G3-4 | Labor lines | Manual labor line → feeds estimate/invoice |
| G3-5 | Status machine | Full PRD transitions including `estimate_rejected`, `on_hold`, QC gate |
| G3-6 | Bay board | Optional: bay status update from job detail |

**Exit:** Workshop can run the job on the floor, not just change status once.

---

## Sprint G4 — Inspections: intake + delivery (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G4-1 | Intake hardening | ✅ Done — regression tests; signature image optional upload |
| G4-2 | Inspection templates | Tenant templates from DB (not single default) |
| G4-3 | Delivery inspection | Second phase checklist; compare intake vs delivery; flag new damage |
| G4-4 | Inspection PDF | Summary PDF for customer sign-off (queue job) |
| G4-5 | Block delivery | Cannot mark `ready_for_delivery` without delivery inspection if policy on |

**Exit:** Dispute-proof vehicle condition record (PRD core).

---

## Sprint G5 — Estimates & customer approval (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G5-1 | Build estimate | Roll up tasks + parts + labor; editable lines |
| G5-2 | Send estimate | Status → `estimate_pending`; WhatsApp/SMS template hook (API) |
| G5-3 | Staff record approval | Mark approved/rejected with notes; timestamp |
| G5-4 | Customer approval hook | API ready for customer app (Sprint C3); staff sees result live |
| G5-5 | Re-estimate | Versioning or replace lines after rejection |

**Exit:** No work starts without approved estimate when category requires it.

---

## Sprint G6 — Technicians & team (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G6-1 | Technicians API | List/create/update staff technicians & advisors |
| G6-2 | Technician screens | List, detail, workload (open jobs count) |
| G6-3 | Skills (lite) | Assign primary technician by job type (optional v1: manual only) |
| G6-4 | Role-based UI | Technician vs owner: hide billing/settings per role |
| G6-5 | Performance snapshot | Jobs completed, avg rating placeholder for CSAT later |

**Exit:** Owner can manage who works on what.

---

## Sprint G7 — Inventory & parts (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G7-1 | Parts categories API | `GET /parts-categories`; category on add/edit part |
| G7-2 | Inventory detail API | Full `GET /inventory/{uuid}` with movement history table |
| G7-3 | Stock ledger | Append-only adjustments log (DB + API) |
| G7-4 | Low-stock alerts | Push + dashboard badge when below threshold |
| G7-5 | Vendors (lite) | Vendor master + link preferred vendor on part |
| G7-6 | Purchase order (lite) | Create PO, receive stock — or defer PO to Web if timeboxed |

**Exit:** Parts room matches job usage; no silent stock drift.

---

## Sprint G8 — Billing, GST & payments (10 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G8-1 | Tax rates API | Tenant GST rates; CGST/SGST split on lines |
| G8-2 | Invoice from job | Pull approved tasks/parts; HSN optional field |
| G8-3 | Invoice PDF | Laravel queue → PDF; staff view/share (WhatsApp intent) |
| G8-4 | Payments hub | Payments list screen; outstanding dues screen |
| G8-5 | Partial payments | Multiple payments; balance due; receipt state |
| G8-6 | Advance/proforma | Invoice types in UI |
| G8-7 | Credit note (lite) | Cancel/void line with audit — or Sprint G12 if needed |

**Exit:** Indian GST invoice ready to hand to customer.

---

## Sprint G9 — Appointments & scheduling (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G9-1 | Appointments API | CRUD appointments; conflict check |
| G9-2 | Calendar/list UI | Book slot; assign bay/tech |
| G9-3 | Check-in | Convert appointment → service job |
| G9-4 | Reminders | Queue: SMS/WhatsApp/push 24h before |
| G9-5 | Dashboard widget | Today’s appointments on home |

**Exit:** Front desk can book before vehicle arrives.

---

## Sprint G10 — Notifications & realtime (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G10-1 | FCM production | `FCM_SERVER_KEY`; push on job status, estimate, payment |
| G10-2 | Inbox sync | Mark read; deep link to job/invoice |
| G10-3 | Device token lifecycle | Refresh token on login; prune stale |
| G10-4 | Reverb (optional v1) | Live job board refresh — or 30s poll fallback documented |
| G10-5 | Notification preferences | Per-user toggles in settings |

**Exit:** Owner/tech get pinged when something needs action.

---

## Sprint G11 — Settings, compliance & offline (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G11-1 | Settings | Garage profile, GSTIN, address on invoice |
| G11-2 | Change PIN | Security flow |
| G11-3 | Staff management (lite) | Invite/disable user — or Web-only with API ready |
| G11-4 | Offline queue v1 | Drift: queue creates (customer, job) when offline; sync indicator |
| G11-5 | Audit trail (read) | Owner views recent actions on job |

**Exit:** Garage can operate on patchy 4G.

---

## Sprint G12 — Hardening & launch (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| G12-1 | E2E test checklist | Full day-in-the-life script on device |
| G12-2 | Performance | API p95 < 800ms; dashboard < 3s on 4G |
| G12-3 | Security review | OWASP pass; tenant isolation audit |
| G12-4 | Play Store internal | Release build; signing; internal testing track |
| G12-5 | Runbook | Deploy API, R2, backups, support playbook |

**Exit:** **Staff app v1.0 — production complete.** No open P0/P1 for garage operations.

---

### Staff app timeline (estimate)

| Phase | Sprints | Calendar |
|-------|---------|----------|
| Foundation + data + jobs core | G0–G3 | ~4 weeks |
| Inspection + estimate + team | G4–G6 | ~3 weeks |
| Inventory + billing | G7–G8 | ~3 weeks |
| Appointments + push + polish | G9–G12 | ~4 weeks |
| **Total** | **G0–G12** | **~14 weeks** (1 dev) / **~8 weeks** (2 devs parallel API+Flutter) |

---

# PART B — CUSTOMER APP (Flutter + API)

**Prerequisite:** Staff app G5 (estimate API) and G8 (invoice/payment API) at minimum.

---

## Sprint C0 — Customer foundation (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C0-1 | Customer app shell | Separate flavor or repo module; branding |
| C0-2 | OTP login production | WhatsApp OTP; rate limits; dev bypass documented |
| C0-3 | Profile | Name, phones, marketing opt-in |
| C0-4 | Garage discovery | Link customer to garage via phone / QR |
| C0-5 | My vehicles | List vehicles across garages (scoped) |

---

## Sprint C1 — Service tracking (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C1-1 | Active job card | Status timeline (PRD states) |
| C1-2 | Push notifications | Job status updates |
| C1-3 | Photos | View intake photos (read-only) |
| C1-4 | History | Past jobs + invoices list |
| C1-5 | Contact garage | Call / WhatsApp garage |

---

## Sprint C2 — Estimates & approval (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C2-1 | Pending estimates | Push when estimate ready |
| C2-2 | Line-item review | Approve / reject with comment |
| C2-3 | Digital consent | Signature or OTP confirm |
| C2-4 | Staff sync | Real-time status on staff job detail |

---

## Sprint C3 — Payments (7 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C3-1 | Invoice view | GST breakdown display |
| C3-2 | Razorpay | UPI/card pay balance due |
| C3-3 | Payment history | Receipts download |
| C3-4 | Partial pay | Pay advance before pickup |

---

## Sprint C4 — Booking & documents (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C4-1 | Book appointment | Choose service + slot |
| C4-2 | Reminders | Push before appointment |
| C4-3 | Upload documents | Insurance RC for garage |
| C4-4 | Mileage consent | Opt-in for GPS/odometer (PRD consent-first) |

---

## Sprint C5 — Loyalty & feedback (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C5-1 | Loyalty balance | Points earn on paid invoice |
| C5-2 | Redeem | At next invoice (staff applies) |
| C5-3 | CSAT | Post-delivery rating + comment |
| C5-4 | Referral (lite) | Share garage link |

---

## Sprint C6 — Customer launch (5 days)

| # | Feature | Deliverables |
|---|---------|----------------|
| C6-1 | Hardening | Error states, analytics |
| C6-2 | Store listing | Play Store customer app |
| C6-3 | Privacy policy | Consent flows legal copy |

**Exit:** **Customer app v1.0 — production complete.**

### Customer app timeline (estimate)

| Sprints | Calendar |
|---------|----------|
| C0–C6 | **~6–7 weeks** after staff G8 |

---

# PART C — OWNER WEB PORTAL (after Staff v1)

Deferred until Sagar approves — not blocking garage floor operations.

| Sprint | Focus |
|--------|--------|
| W1 | Inertia shell + auth |
| W2 | Dashboard reports |
| W3 | Master data admin |
| W4 | Staff & roles (`tenant_memberships`) |
| W5 | Subscription & billing (SaaS) |
| W6 | Inventory PO + vendors full |

---

## Priority map (if time is short)

| Must have before “staff v1” | Nice in v1.1 |
|-----------------------------|--------------|
| G0, G1, G2, G3, G5, G8, G10, G12 | G9 appointments |
| G4 delivery inspection | G7 full PO |
| G6 technicians + roles | Reverb realtime |
| G7 inventory ledger | Web portal |

---

## Delivery mode (CEO approved: Wave C)

| Wave | Sprints | Sagar reviews |
|------|---------|---------------|
| **Wave 1** | G0–G3 | Once after Wave 1 build |
| Wave 2 | G4–G6 | Once |
| Wave 3 | G7–G9 | Once |
| Wave 4 | G10–G12 | Final staff v1 |

Internal QA runs during build; no per-sprint device sign-off unless blocker.

---

## Tracking

| Sprint | Status | Target done |
|--------|--------|-------------|
| G0 | ✅ | Wave 1 |
| G1 | 🏗️ | Wave 1 |
| G2 | 🏗️ | Wave 1 |
| G3 | 🏗️ | Wave 1 |
| … | | |
| G12 Staff v1 | 🔲 | |
| C0–C6 Customer v1 | 🔲 | |

*Sagar: Reply **“approve G0”** to start Sprint G0 (production foundation).*
