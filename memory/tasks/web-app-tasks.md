# Web App — Production Build (GarageFlow)

**Goal:** Full parity with Flutter staff app + design files (`Briefs/Web-app-design/`).  
**Codebase:** `Apps/web` (refactor from single-file → proper modules).  
**Portals:** `app.progarage.cloud` (staff) · `admin.progarage.cloud` (super-admin)

---

## Phase 0 — Foundation (current sprint)
- [x] Fix staff login: phone OR email (no browser email validation)
- [ ] Refactor: `src/features/`, design system from `gf-tokens.jsx`, shared Shell/Sidebar
- [ ] Auth flows: login, owner signup, forgot PIN (WhatsApp OTP), reset PIN, post-login onboarding redirect
- [ ] Deploy each phase to production

## Phase 1 — Staff core operations
- [ ] Dashboard (KPIs, bays, active jobs, appointments today) — match design p02
- [ ] Jobs: list filters/pagination, create job wizard, detail (tabs: overview/tasks/inspection/parts/billing/timeline) — p03–05
- [ ] Job status updates, estimate send/approve, tasks CRUD
- [ ] Customers: list, detail (vehicles, history, loyalty), add/edit — p06–07
- [ ] Vehicles: list (fleet), detail, add/edit, documents upload — Flutter `/vehicles`

## Phase 2 — Inspections & billing
- [ ] Intake + delivery inspection (checklist, damage map, signature pad, **webcam photo capture**) — p07 design + Flutter parity
- [ ] Invoices: list, create from job, detail, PDF download, split billing — p09
- [ ] Record payment / collect payment — Flutter payments hub + invoice sheet
- [ ] Payments outstanding hub

## Phase 3 — Operations & settings
- [ ] Appointments (list, check-in)
- [ ] Inventory (list, add part, stock adjust, low-stock alerts) — p08
- [ ] Team/staff (list, add technician, roles)
- [ ] Reports — p10
- [ ] Settings: garage profile, user profile, integrations (WhatsApp), fleet — p11
- [ ] Notifications panel — p12
- [ ] Audit log (owner/advisor)

## Phase 4 — Super-admin (full design SA-01–SA-10)
- [ ] Platform dashboard (KPIs, MRR chart, tenant events, system health)
- [ ] Tenants: list/search/filters, create wizard, detail (profile, subscription, users, billing, feature flags, audit, support notes)
- [ ] Plans CRUD, active subscriptions management
- [ ] Global settings, admin users, audit log, support tools (storage browser, reset tenant)
- [ ] **Tenant impersonation** — requires new API (see below)

## Backend gaps (before Phase 4 impersonation)
- [ ] `POST /platform/tenants/{uuid}/impersonate` → staff token + audit `impersonator_id`
- [ ] Platform-wide audit log endpoint (optional: extend `/audit-logs` for platform admin)

---

## Acceptance rule
Each screen must match design layout + wire to production API. No placeholder tables or stub pages marked done.
