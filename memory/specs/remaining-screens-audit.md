# Staff App — Remaining Screens Audit
# Updated: 2026-05-21 | Owner: Sagar

## Design files (Briefs/Design files/) vs built

| # | Design HTML | Screen | Built | Gap |
|---|-------------|--------|-------|-----|
| 01 | Splash | Splash | ✅ | No first-launch onboarding after splash |
| 02 | Staff Login | Login + PIN OTP | ✅ | — |
| 03 | Dashboard | Dashboard | ✅ | Appointments widget missing (G9) |
| 04 | Jobs List | Jobs | ✅ | — |
| 05 | Create Job | Create Job wizard | ✅ | — |
| 06 | Job Detail | Job Detail | ✅ | Delivery compare banner partial |
| 07 | Intake Inspection | Inspection | ✅ | PDF export missing |
| 08 | Customers List | Customers | ✅ | — |
| 09 | Customer Detail | Customer Detail | ✅ | — |
| 10 | Invoice Detail | Invoice Detail | ✅ | PDF share missing |

**No design HTML yet:** Onboarding, Settings hub, Team, Appointments, Payments hub, Audit log, Change PIN, Garage profile setup, Fleet/Vehicles tab, Offline sync status.

---

## Routes that exist but are thin / stub

| Screen | Route | Status |
|--------|-------|--------|
| Vehicles tab | `/vehicles` | Placeholder text only |
| Settings | `/settings` | Basic — no garage profile edit, no change PIN |
| Notifications | `/notifications` | Inbox partial |
| Team | `/team` | Built but not in bottom nav |
| Estimate | `/jobs/:id/estimate` | Built — needs UX polish |
| OTP (customer) | `/auth/otp` | Built — **customer app**, not staff primary |

---

## Missing screens (master plan G9–G12)

| Priority | Screen | Why |
|----------|--------|-----|
| P0 | **First-launch onboarding** (3 slides) | New install → value prop before login |
| P0 | **Owner setup wizard** | Garage name, GSTIN, address, bays — first owner login |
| P1 | **Change PIN** | G11-2 security |
| P1 | **Garage profile edit** | G11-1 invoice header data |
| P1 | **Appointments** list + book + check-in | G9 front desk |
| P2 | **Payments hub** | Outstanding dues across invoices |
| P2 | **Invoice PDF** view/share | G8-3 |
| P2 | **Audit trail** (read-only) | G11-5 owner transparency |
| P3 | **Fleet / Vehicles** tab | All vehicles across customers |
| P3 | **Offline sync indicator** | G11-4 |

---

## Customer app (separate product — Part B)

Not in staff app scope: job tracking, estimate approval, Razorpay pay, loyalty, booking — 6 sprints (C0–C6).

---

## SaaS onboarding (S10 — web, not mobile)

Tenant signup, subscription, marketing landing — deferred until staff v1 ships.
