# PROJECT CONTEXT
# Filled by CEO Agent on project kickoff. Updated as project evolves.
# READ by: CEO Agent, all Department Heads
# DO NOT read full requirement doc after this file is populated.

---

## Project Identity
- **Project Name:** GarageFlow SaaS (repo: progarage)
- **Client / Product:** Akshara Internal — Own SaaS Product
- **Type:** [x] SaaS Product
- **Start Date:** 2026-05-14
- **Target Delivery:** TBD (10-sprint roadmap)
- **Priority:** [x] Critical

---

## Project Summary
GarageFlow is a multi-tenant SaaS platform for garage businesses in India.
It enables garage owners to manage end-to-end operations:
Customer Intake → Estimate → Inspection → Job Assignment → Parts/Labor Tracking → Billing → Delivery → Post-Service Loyalty.
Stack: Laravel 11 (API) + React 18/Inertia (Web Dashboard) + Flutter 3.x (Customer + Staff Mobile App) + MySQL 8 + Redis + Laravel Reverb (WebSockets).
Multi-tenant from day 1 with tenant_id isolation via Laravel Global Scopes.

---

## Active Departments
- [x] Technical (CTO Agent)
- [ ] Product & Design (CPO Agent) — on hold until S5
- [ ] Sales (Sales Director) — activate at beta launch
- [ ] Marketing (Marketing Director) — activate at beta launch
- [ ] Legal (Legal Agent) — activate before commercial launch
- [ ] Data & Analytics (Data Analyst) — activate post-launch

---

## Tech Stack for This Project
- **Frontend (Web):** React 18 + Inertia.js + Vite + TanStack Query + Zustand
- **Frontend (Mobile):** Flutter 3.x (Dart) + Riverpod + GoRouter + Dio
- **Backend:** Laravel 11 (PHP 8.2+), Eloquent ORM, Laravel Sanctum, Laravel Reverb (WebSocket)
- **Database:** MySQL 8 (40 tables, multi-tenant, soft deletes, UUID on all public IDs)
- **Cloud:** Cloudflare R2 (S3-compatible file storage)
- **Queue/Cache:** Redis + Laravel Horizon
- **Auth:** Sanctum Bearer Tokens — Staff: email+PIN, Customer: phone+OTP
- **API Standard:** OpenAPI 3.0 contract-first; JSON envelopes {success, data, meta, error}

---

## End Users Profile
- **Staff App users:** Garage owners, service advisors, technicians — age 25-55, mobile-first, semi-technical, Indian market
- **Customer App users:** Vehicle owners, age 22-60, mobile, low-to-mid tech savvy, Indian market
- **Primary devices:** [x] Mobile  [ ] Tablet  [ ] Desktop (web dashboard for owners only)
- **Technical level:** [x] Non-technical (technicians/customers) + Semi-technical (owners)
- **Industry:** Automotive Services / Garage Management
- **Special needs:** Works on low bandwidth, INR currency, GST-compliant invoicing, Hindi/regional market context

---

## Key Modules / Features (Sprint Map)
1. **S0 — Flutter Foundation** — Core arch: Riverpod, GoRouter, Dio, SecureStorage, Drift, dark theme ✅
2. **S1 — Auth + Dashboard** — Staff PIN login, Customer OTP, Dashboard KPIs, AppShell nav ✅
3. **S2 — Laravel Backend** — 40 MySQL tables, 31 Eloquent models, 8 API controllers, seeders ✅
4. **S3 — Flutter Jobs Module** — Job list (filters/search/infinite scroll), Job detail screen ⏳ ACTIVE
5. **S4 — Flutter Customers + Vehicles** — Customer list, detail, vehicle list, document tracker
6. **S5 — Flutter Invoicing + Payments** — Invoice view, payment recording, PDF preview
7. **S6 — Flutter Inventory** — Parts list, stock adjustment, low-stock alerts
8. **S7 — React Web Dashboard** — Owner dashboard, job management, reports (Inertia.js)
9. **S8 — Push Notifications** — Firebase FCM, job status push, reminder system
10. **S9 — Loyalty + Feedback** — Points ledger, CSAT collection, referral module
11. **S10 — Landing Page + Onboarding** — Marketing site, tenant signup flow, subscription billing

---

## Performance Requirements
- Expected concurrent users: 500 garages × 5 staff = 2,500 concurrent (Year 1)
- Expected data volume: 500K job records Year 1, 3M by Year 3
- Dashboard must load < 3s on 4G mobile
- API list endpoints: < 800ms at 95th percentile
- WebSocket latency: < 200ms for job status updates

---

## Integration Points
- Cloudflare R2: Inspection photos, invoice PDFs, vehicle documents, chat media
- Firebase FCM / APNS: Push notifications (Sprint 8)
- Payment gateways: Razorpay / Stripe (Sprint 10 billing module)
- Laravel Reverb: WebSocket real-time job status, tech chat

---

## Critical Business Rules
1. All API routes use UUID, never internal integer ID
2. Every tenant-scoped query enforced via Laravel Global Scope (never bypass)
3. Soft deletes everywhere — financial records, jobs, invoices are never hard-deleted
4. Audit logs are immutable — never UPDATE or DELETE audit_log rows
5. Customer GPS/odometer tracking requires explicit consent opt-in
6. OTP rate limited: 5 requests per 10 minutes per phone number
7. Invoice recalculation is automatic via Invoice::recalculate() on any line item change
8. Job status follows strict workflow: draft → intake_inspection → estimate_pending → estimate_approved → in_progress → qc_pending → ready_for_delivery → delivered
9. Discovered (unapproved) tasks must not be added to invoice until customer approves
10. Multi-tenancy: tenant_id resolved from auth token context — never passed as client query param

---

## Requirement Document Location
- **PRD:** Briefs/PRD.md — ✅ Parsed by CEO Agent
- **API Spec:** Briefs/API_Specification.md — ✅ Available for reference
- **Design System:** Briefs/Design_system.md — ✅ Available
- **Status:** [x] Task files generated  [x] Ready for development

---

## Key Decisions Log
- Stack locked (Laravel 11 + MySQL 8 + React/Inertia + Flutter + Riverpod)
- Dark-first industrial theme with primaryOrange (#FF6B2B)
- Typography: Sora (display), DM Sans (body), DM Mono (numbers)
- Shared schema multi-tenancy (tenant_id scoping, not separate DBs)
- Demo fallback data in Flutter when API is unreachable

---
*Last updated by: CEO Agent | 2026-05-15*
