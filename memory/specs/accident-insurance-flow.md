# Accident Repair & Insurance Claim Flow — Staff Mobile
# Approved: 2026-05-21 (Option B) | Owner: Sagar

## Purpose
Garages handling collision/body work must track insurer details, survey → approval → split billing without a separate spreadsheet.

## User journey (staff app)

1. **Create job** — Select **Accident Repair** or **Body Work** service type → enter insurer name + claim number (optional survey date).
2. **Intake inspection** — Mandatory damage map + photos (existing intake flow).
3. **Insurance tracker (job detail)** — Status steps:
   - `survey_pending` — Awaiting insurer survey
   - `estimate_submitted` — Estimate sent to insurer
   - `approved` / `rejected` — Insurer decision recorded
   - `settled` — Claim closed; ready for final billing split
4. **Estimate & invoice** — Grand total split into **customer liability** + **insurance claim** amounts on invoice.
5. **Collect payment** — Record customer payment and insurance claim payment separately (`payment_type`: `customer_pay` | `insurance_claim`).

## Vehicle management (same sprint)

- **Upload documents** — RC, insurance, PUC, fitness, permit (photo/PDF) with expiry on vehicle profile.
- **Deactivate vehicle** — Soft deactivate (`is_active=false`); hidden from active lists; history preserved.

## Business rules

- Accident/body categories auto-flag job as insurance job.
- Split amounts on invoice must sum to `grand_total` (± ₹1 rounding).
- Deactivated vehicles cannot be attached to new jobs.
- One active document per type per vehicle (new upload supersedes previous — API rule from PRD).

## Out of scope (v1)

- Direct insurer API integration
- Customer-app insurer upload (Sprint C4)
- Automated claim status from insurer portal
