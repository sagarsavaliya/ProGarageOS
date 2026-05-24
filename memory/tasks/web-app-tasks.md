# Web App — Production Build (GarageFlow)

**Approved May 24, 2026 — Sagar decisions:**
1. **Order:** Staff web first → impersonation APIs → super-admin web
2. **Impersonation:** Full owner access, **no actions blocked**; audit trail required
3. **Inspection photos on web:** USB/UVC camera via browser capture (mobile remains primary for field inspection)

**Portals:** `app.progarage.cloud` (staff) · `admin.progarage.cloud` (later)

---

## Phase 0 — Staff foundation ✅
- [x] Fix staff login: phone OR email
- [x] Refactor `Apps/web` → modular structure
- [x] Design system + auth flows
- [x] Deploy

## Phase 1–3 — Staff portal ✅
- [x] Dashboard · Jobs list/detail/create · Customers · Vehicles/Fleet
- [x] Appointments · Inventory · Billing (invoices + payments)
- [x] Intake inspection (checklist, USB/webcam capture → R2)
- [x] Reports · Settings (profile, team, WhatsApp) · Notifications · Audit
- [x] Owner onboarding wizard

## Phase 5 — Backend: impersonation (after staff sign-off)
- [ ] `POST /platform/tenants/{uuid}/impersonate` → staff token, `impersonator_id` on audit
- [ ] Platform audit log endpoint if needed

## Phase 6 — Super-admin web (after Phase 5 APIs)
- [ ] Full SA-01–SA-10 design + wire impersonation

**Rule:** Match design files + Flutter API parity. No stub pages marked done.
