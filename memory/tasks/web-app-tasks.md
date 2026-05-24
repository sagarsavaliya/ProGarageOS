# Web App — Production Build (GarageFlow)

**Approved May 24, 2026 — Sagar decisions:**
1. **Order:** Staff web first → impersonation APIs → super-admin web
2. **Impersonation:** Full owner access, **no actions blocked**; audit trail required
3. **Inspection photos on web:** USB/UVC camera via browser capture (mobile remains primary for field inspection)

**Portals:** `app.progarage.cloud` (staff) · `admin.progarage.cloud` (later)

---

## Phase 0 — Staff foundation (IN PROGRESS)
- [x] Fix staff login: phone OR email
- [ ] Refactor `Apps/web` → `src/lib`, `src/components`, `src/features/staff`, `src/features/auth`
- [ ] Design system from `Briefs/Web-app-design/gf-tokens.jsx` (Shell, Sidebar, Header, atoms)
- [ ] Auth: login (design p01), owner signup, forgot PIN (WhatsApp OTP), PIN setup/reset, onboarding redirect
- [ ] Deploy after Phase 0

## Phase 1 — Staff core
- [ ] Dashboard p02 · Jobs list/detail/create p03–05 · Customers p06–07 · Fleet/vehicles

## Phase 2 — Inspections & billing
- [ ] Intake/delivery inspection (checklist, damage map, signature, **USB/webcam capture** → R2)
- [ ] Invoices, record payment, payments hub

## Phase 3 — Staff operations
- [ ] Appointments · Inventory p08 · Team · Reports p10 · Settings p11 · Notifications p12 · Audit

## Phase 5 — Backend: impersonation (after staff web sign-off)
- [ ] `POST /platform/tenants/{uuid}/impersonate` → staff token, `impersonator_id` on audit
- [ ] Platform audit log endpoint if needed

## Phase 6 — Super-admin web (after Phase 5 APIs)
- [ ] Full SA-01–SA-10 design + wire impersonation

**Rule:** Match design files + Flutter API parity. No stub pages marked done.
