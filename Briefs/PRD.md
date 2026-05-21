# 📄 PRD.md — GarageFlow SaaS
> **Version**: 1.0.0 | **Status**: Schema Design Complete | **Last Updated**: 2026-05-02  
> **Owner**: Sagar (Solo Dev → Team Handoff Ready)  
> **Stack**: Laravel 11 + MySQL 8 + React 18 (Garage Dashboard) + Flutter (Customer App) + Reverb/Soketi + S3-Compatible Storage

---
## 🎯 Product Vision & Scope
Enable garage owners to manage end-to-end operations with zero clutter:  
`Customer Intake` → `Estimate` → `Inspection` → `Job Assignment` → `Parts/Labor Tracking` → `Billing` → `Delivery` → `Post-Service Loyalty`  
**Core Principles**: Multi-tenant from day one, zero hard-coded business logic, dispute-proof workflows, elite customer app experience, team-ready support architecture.

---

## ⚙️ Tech Stack & Architecture Decisions (Locked)
| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Backend** | Laravel 11 (PHP 8.2+) | Eloquent ORM, queued jobs, mature ecosystem, easy team scaling |
| **Database** | MySQL 8 | JSON support, window functions, cost-effective, familiar talent pool |
| **Garage Web Dashboard** | React 18 + Inertia.js + Vite | SPA UX without separate API layer; Laravel controllers render React components. Eliminates client-side routing duplication. |
| **Customer Mobile App** | Flutter 3.x (iOS/Android) | Cross-platform, native performance, mature background location plugins, strict typing for reliable state management |
| **State Management (Web)** | `@tanstack/react-query` (Server) + `zustand` (UI) | Caching, background sync, selective re-renders. Zero boilerplate. Replaces Redux/Context for global state. |
| **State Management (Mobile)** | Riverpod/Bloc + `dio` | Type-safe, testable, auto-generated models from OpenAPI spec. Keeps mobile & web state isolated but contract-aligned. |
| **Realtime** | Laravel Reverb | WebSockets for live job status, chat, notifications. Replaces HTTP polling. |
| **Storage** | S3-Compatible (Cloudflare R2) | Inspection photos, chat media, invoice PDFs, vehicle documents |
| **Queue & Cache** | Redis + Horizon | Background jobs: reminders, expiry sweeps, PDF generation, ledger sync |
| **Auth** | Laravel Sanctum + PIN/OTP Flow | Email/Phone + 6-digit PIN for staff; OTP for customers. Secure, frictionless login. |
| **Multi-Tenancy** | Shared Schema + `tenant_id` Scoping | Cost-effective; enforced via Laravel Global Scopes + middleware |
| **API Contracts** | OpenAPI 3.0 + Codegen | Single source of truth. Auto-generates TypeScript/Zod types for web & Dart models for mobile on CI. |

---

## 🏗️ Core Architecture Principles
1. **Zero Hardcoding**: All business rules (pricing, limits, workflows, templates, intervals) are UI-configurable via master/tenant tables.
2. **Multi-Tenant Isolation**: Every tenant-scoped table includes `tenant_id` FK. Enforced via Laravel Global Scopes. Never query without tenant context.
3. **Soft Deletes Everywhere**: `deleted_at` preserves historical integrity for invoices, jobs, compliance records, and audit trails.
4. **Immutable Audit Logs**: Financial changes, workflow transitions, and support impersonation are logged with JSON diffs. Never `UPDATE`/`DELETE` audit rows.
5. **Consent-First Tracking**: GPS/odometer tracking requires explicit opt-in. No background polling. Customer controls data visibility & usage. iOS/Android compliance baked into Flutter architecture.
6. **Event-Driven Architecture**: Laravel Observers + Queues handle stock deduction, loyalty ledger updates, invoice recalculation, and notification dispatch.
7. **Server-State > Client-State**: Web dashboard uses `react-query` for all API data. `zustand` only for UI state (filters, modals, theme, form steps). Never fetch data in `useEffect`.
8. **Inertia-Driven Routing**: No `react-router`. Laravel defines routes → Inertia handles page transitions, history, scroll restoration, and hydration.
9. **Contract-First Development**: API payloads, validation rules, and error shapes defined in OpenAPI spec. Auto-generated for both React (Zod) and Flutter (Dart models) to guarantee parity.
10. **Performance by Default**: Virtualized tables for 10k+ rows, debounced inputs, memoized components, WebSocket streaming, and lazy-loaded heavy routes. Zero unnecessary re-renders or polling.

---

## 🗃️ Database Schema (40 Tables)

### 1️⃣ Multi-Tenancy & Subscription

#### 🔹 `tenants`
**Purpose:** Root multi-tenant container. Represents a garage business account.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `uuid` | CHAR(36) | UNIQUE, INDEX | Public/API-safe ID |
| `business_name` | VARCHAR(255) | NOT NULL | Garage display name |
| `business_type` | ENUM('single','multi_location') | DEFAULT 'single' | Multi-garage readiness |
| `status` | ENUM('trial','active','suspended','churned') | DEFAULT 'trial' | Access control |
| `currency` | CHAR(3) | DEFAULT 'INR' | Financial calculations |
| `timezone` | VARCHAR(50) | DEFAULT 'Asia/Kolkata' | Scheduling & reports |
| `country_code` | CHAR(2) | DEFAULT 'IN' | GST/VAT compliance |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → users, locations, customers, service_jobs

#### 🔹 `subscription_plans`
**Purpose:** Master catalog of SaaS pricing tiers (UI-configurable).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `uuid`, `name`, `slug` | CHAR/VARCHAR | UNIQUE | Catalog identity & routing |
| `price` | DECIMAL(10,2) | NOT NULL | Base amount |
| `billing_cycle` | ENUM('monthly','yearly','quarterly') | DEFAULT 'monthly' | Recurrence |
| `trial_days`, `max_locations`, `max_users` | INT UNSIGNED | DEFAULTS | Feature limits |
| `status` | ENUM('draft','active','archived') | DEFAULT 'active' | Visibility |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `tenant_subscriptions`

#### 🔹 `tenant_subscriptions`
**Purpose:** Active subscription instance linking a garage to a plan. Tracks billing lifecycle.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `plan_id` | BIGINT UNSIGNED | FK, INDEX | Garage & catalog links |
| `status` | ENUM('trialing','active','past_due','canceled','expired','paused') | DEFAULT 'trialing' | Billing state |
| `current_period_start`, `current_period_end` | DATETIME | NOT NULL | Cycle boundaries |
| `cancel_at_period_end`, `canceled_at` | TINYINT/DATETIME | | Scheduled cancellation |
| `gateway`, `gateway_subscription_id`, `gateway_customer_id` | VARCHAR | NULLABLE | Payment processor refs |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Max 1 active/trialing per tenant. Price/currency snapshotted at signup.

---

### 2️⃣ Identity & Access

#### 🔹 `users`
**Purpose:** Platform staff accounts (owners, technicians, admins, support).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `email`, `phone` | VARCHAR | UNIQUE, NULLABLE | Login (at least one required) |
| `pin_hash` | VARCHAR(255) | NOT NULL | 6-digit PIN hash (bcrypt) |
| `first_name`, `last_name` | VARCHAR | NOT NULL/NULL | Display name |
| `is_platform_admin`, `is_support_agent` | TINYINT(1) | DEFAULT 0 | Global access flags |
| `last_login_at`, `pin_last_changed_at` | DATETIME | NULLABLE | Security tracking |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Auth scoped to staff. Roles/permissions via future `tenant_memberships`.

#### 🔹 `tenant_memberships` *(Phase 2 — deferred, schema reserved)*
**Purpose:** Junction table enabling a single `users` record to belong to multiple tenants with tenant-scoped roles and permissions. Required for agency accounts, support impersonation, and multi-location ownership structures.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id` | BIGINT UNSIGNED | FK → `tenants.id`, INDEX | Tenant scope |
| `user_id` | BIGINT UNSIGNED | FK → `users.id`, INDEX | Staff member |
| `role` | ENUM('owner','manager','service_advisor','technician','receptionist') | NOT NULL | Tenant-scoped role |
| `permissions_override` | JSON | NULLABLE | Per-user permission delta from role defaults |
| `is_primary_tenant` | TINYINT(1) | DEFAULT 0 | Login default tenant for multi-tenant staff |
| `invited_by` | BIGINT UNSIGNED | FK → `users.id`, NULL | Audit: who granted access |
| `invited_at`, `accepted_at` | DATETIME | NULLABLE | Invitation lifecycle |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Constraints:** UNIQUE `(tenant_id, user_id)`. Soft-delete revokes access without losing history.  
**Rules:** Phase 1 uses a simplified `role` column directly on the user scoped per tenant via middleware. `tenant_memberships` replaces this when multi-tenant staff management is activated. ERD reference node `[TENANT_MEMBERSHIPS]` is already present in the relationship map.  
**⚠️ Phase 2 — Migration stub should be created now; table populated in Phase 2 sprint.**

#### 🔹 `customers`
**Purpose:** Global end-customer identity. Spans all garages on the platform.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `phone_primary` | VARCHAR(20) | UNIQUE, INDEX, NOT NULL | Primary login/contact |
| `phone_secondary` | VARCHAR(20) | INDEX, NULL | Backup contact |
| `is_p_wa_enabled`, `is_s_wa_enabled` | TINYINT(1) | DEFAULT 1/0 | WhatsApp comms toggles |
| `email`, `first_name`, `last_name` | VARCHAR | NULL/NOT NULL/NULL | Contact & personalization |
| `preferred_language`, `marketing_opt_in` | CHAR/TINYINT | DEFAULT 'en'/0 | Localization & consent |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `garage_customers`, `vehicles`

#### 🔹 `garage_customers`
**Purpose:** Junction linking global customer to specific garage with garage-only metadata.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `customer_id`, `tenant_id` | BIGINT UNSIGNED | UNIQUE `(customer_id, tenant_id)`, FK | Relationship link |
| `internal_notes`, `loyalty_points` | TEXT / INT UNSIGNED | DEFAULT 0 | Garage-only data |
| `preferred_technician_id` | BIGINT UNSIGNED | FK → `users.id`, NULL | Staff preference |
| `last_visited_at`, `total_spent`, `visit_count` | DATETIME / DECIMAL / INT | | Analytics cache |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**API Representation:** In all customer-facing API responses (`GET /customers`, `GET /customers/{uuid}`, `POST /customers`), `garage_customers` data is serialized as a nested `garage_profile` object — not flattened. This keeps global customer identity (`phone`, `email`, `name`) cleanly separated from garage-specific metadata (`loyalty_points`, `internal_notes`, `preferred_technician_id`, analytics cache fields). The API spec is the authoritative reference for this shape.
---

### 3️⃣ Vehicles & Compliance

#### 🔹 `vehicles`
**Purpose:** Customer-owned vehicles. RC-compliant fields for Indian context.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `customer_id` | BIGINT UNSIGNED | FK, INDEX | Primary owner |
| `registration_number` | VARCHAR(50) | INDEX, NOT NULL | RC display ID |
| `chassis_number`, `engine_number` | VARCHAR(100) | UNIQUE/INDEX, NOT NULL | Global/secondary IDs |
| `registration_date`, `registration_validity`, `fitness_validity` | DATE | NOT NULL/NULL | Compliance dates |
| `owner_serial`, `ownership_transfer_date` | TINYINT / DATE | | Ownership history |
| `fuel_type`, `emission_norms`, `vehicle_class`, `body_type`, `transmission` | ENUMs | | Technical specs |
| `maker`, `model`, `variant`, `year`, `color`, `nickname` | VARCHAR/YEAR | | Display fields |
| `odometer_reading`, `gps_estimated_odometer`, `gps_tracking_consent` | INT/TINYINT | DEFAULT 0/0 | Tracking & consent |
| `odometer_review_status` | ENUM('none','pending_approval','approved','manually_corrected','auto_accepted') | DEFAULT 'none' | App UI prompt state |
| `gps_last_sync_at` | DATETIME | NULL | Last aggregation timestamp |
| `insurance_*`, `permit_*`, `blacklisted_status` | VARCHAR/DATE/ENUM | | Claim/risk tracking |
| `photo_url`, `is_active` | VARCHAR / TINYINT | | Visual ID / archive |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `service_jobs`, `vehicle_documents`, `vehicle_mileage_logs`

#### 🔹 `vehicle_documents`
**Purpose:** Compliance & legal document tracker (RC, Insurance, PUC, etc.).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `vehicle_id`, `tenant_id` | BIGINT UNSIGNED | FK, INDEX | Vehicle & garage link |
| `document_type` | ENUM('rc','insurance','puc','fitness','permit','other') | NOT NULL | Category |
| `document_number`, `issuing_authority` | VARCHAR | | Reference data |
| `issue_date`, `expiry_date` | DATE | NULLABLE | Validity period |
| `file_url` | VARCHAR(500) | NULLABLE | S3 scan path |
| `is_verified`, `is_active` | TINYINT(1) | DEFAULT 0/1 | Status flags |
| `ocr_extracted_data` | JSON | NULLABLE | AI-ready extraction |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** One active doc per type. Expiry cron triggers reminders. Job intake blocks/warns on expired docs.

#### 🔹 `vehicle_mileage_logs`
**Purpose:** Consent-based odometer tracking. No background polling — only high-value, customer-triggered or context-aware entries.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `vehicle_id` | BIGINT UNSIGNED | FK → `vehicles.id`, NOT NULL, INDEX | Tracked vehicle |
| `recorded_at` | DATETIME | NOT NULL, INDEX | Timestamp of log |
| `odometer_value_km`, `previous_value_km` | INT UNSIGNED | NOT NULL/DEFAULT 0 | Verified km & delta baseline |
| `source` | ENUM('gps_background','customer_approved','customer_manual_correct','job_intake','admin_override') | NOT NULL | Origin of truth |
| `review_status` | ENUM('pending','confirmed','auto_accepted') | DEFAULT 'confirmed' | Lifecycle state |
| `gps_delta_km` | INT UNSIGNED | NULLABLE | Distance added since last sync |
| `created_at` | TIMESTAMP | Auto | Audit |
**Rules:** Append-only. `source='gps_background'` only after approval/correction. Reminder engine consumes `review_status IN ('confirmed', 'auto_accepted')`.

#### 🔹 `service_interval_preferences`
**Purpose:** Customer-personalized service reminder settings. Overrides garage defaults for elite engagement.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `vehicle_id` | BIGINT UNSIGNED | FK → `vehicles.id`, NOT NULL, UNIQUE | One preference set per vehicle |
| `preferred_interval_km`, `preferred_interval_months` | INT UNSIGNED | NULLABLE | Customer's chosen intervals |
| `reminder_channel` | ENUM('push','whatsapp','sms','email','none') | DEFAULT 'push' | Preferred method |
| `advance_notice_days`, `advance_notice_km` | INT UNSIGNED | DEFAULT 7/500 | Trigger thresholds |
| `is_active`, `last_acknowledged_at` | TINYINT / DATETIME | DEFAULT 1/NULL | Toggle & engagement tracking |
| `created_at`, `updated_at` | TIMESTAMP | Auto | Audit |

#### 🔹 `customer_engagement_events`
**Purpose:** Behavioral intelligence for smart, contextual notifications. Tracks value-driven interactions only.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id`, `uuid` | BIGINT/CHAR | PK/UNIQUE | Identity |
| `customer_id` | BIGINT UNSIGNED | FK → `customers.id`, NOT NULL, INDEX | Global customer |
| `event_type` | ENUM('app_opened','viewed_job_progress','confirmed_odometer','booked_service','dismissed_reminder','updated_preferences') | NOT NULL, INDEX | Meaningful interaction |
| `reference_type`, `reference_id` | VARCHAR / BIGINT | NULLABLE | Related entity |
| `metadata` | JSON | NULLABLE | Context payload |
| `created_at` | TIMESTAMP | Auto, INDEX | Event timestamp |

---

### 4️⃣ Service Operations

#### 🔹 `service_categories`
**Purpose:** Tenant-configurable service menu. Controls workflow flags.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `name`, `code` | VARCHAR | UNIQUE `(code, tenant_id)` | Display & programmatic ID |
| `default_duration_min` | INT UNSIGNED | DEFAULT 60 | Scheduling baseline |
| `requires_intake_inspection`, `requires_approval`, `is_billable` | TINYINT(1) | DEFAULT 1/0/1 | Workflow toggles |
| `tenant_id`, `is_active`, `sort_order` | BIGINT / TINYINT / INT | | Scope & UI order |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `service_items`, `job_service_categories`

#### 🔹 `service_items`
**Purpose:** Billable task/product catalog (cart-style billing).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `category_id`, `tenant_id` | BIGINT UNSIGNED | FK, INDEX | Parent & scope |
| `name`, `code` | VARCHAR | UNIQUE `(code, tenant_id)` | Display & key |
| `default_price`, `default_labor_minutes` | DECIMAL / INT | | Baseline billing/scheduling |
| `requires_parts`, `is_package`, `tax_applicable` | TINYINT(1) | DEFAULT 0/0/1 | Feature flags |
| `is_active`, `sort_order` | TINYINT / INT | | UI control |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `job_tasks`, `service_item_skills`

#### 🔹 `skills`, `technician_skills`, `service_item_skills`
**Purpose:** Capability mapping for algorithmic technician assignment.
- `skills`: Master catalog (`name`, `code`, `category_id`, `is_active`)
- `technician_skills`: Junction `(technician_id, skill_id)` + `proficiency_level`, `years_experience`, `is_verified`
- `service_item_skills`: Junction `(service_item_id, skill_id)` + `is_primary`
**Impact:** Enables skill-based routing, workload balancing, and pricing tiers.

#### 🔹 `job_service_categories`
**Purpose:** Junction linking one job to multiple service categories (multi-select UI).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `job_id`, `category_id` | BIGINT UNSIGNED | UNIQUE `(job_id, category_id)`, FK | Relationship link |
| `is_primary`, `sort_order` | TINYINT / INT | | Billing/routing priority |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Aggregates category flags for inspection/approval triggers.

#### 🔹 `job_tasks`
**Purpose:** Dynamic instance tracker for every action on a job. Handles mid-job changes, approvals, liability.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `job_id` | BIGINT UNSIGNED | FK, INDEX | Parent job |
| `service_item_id`, `required_skill_id` | BIGINT UNSIGNED | FK, NULLABLE | Catalog & skill alignment |
| `name`, `description` | VARCHAR / TEXT | NOT NULL/NULL | Task details |
| `source` | ENUM('planned','discovered','accidental_damage','upsell','customer_request') | NOT NULL | Origin trigger |
| `status` | ENUM('pending_approval','approved','in_progress','completed','cancelled','waived') | DEFAULT 'pending' | Lifecycle |
| `assigned_technician_id` | BIGINT UNSIGNED | FK → `users.id`, NULL | Staff assignment |
| `estimated_price`, `final_price`, `labor_minutes` | DECIMAL / INT | | Billing/tracking |
| `requires_customer_approval`, `liability_flag`, `is_billable` | TINYINT / ENUM | | Workflow & cost control |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Auto-populates `required_skill_id` from `service_item_skills`. Approval thresholds configurable per tenant.

#### 🔹 `service_jobs`
**Purpose:** Central job card & workflow tracker. Intake → Estimate → Assignment → Execution → QC → Delivery.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `customer_id`, `vehicle_id` | BIGINT UNSIGNED | FK, INDEX | Core entities |
| `job_number` | VARCHAR(50) | UNIQUE `(tenant_id, job_number)` | Auto-generated ID |
| `status` | ENUM('draft'→'delivered' + 'cancelled','on_hold') | DEFAULT 'draft' | Workflow state |
| `priority` | ENUM('low','normal','urgent','critical') | DEFAULT 'normal' | Scheduling weight |
| `odometer_at_intake`, `fuel_level` | INT / ENUM | NULLABLE | Intake baseline |
| `estimated_amount`, `approval_status`, `customer_approved_at` | DECIMAL / ENUM / DATETIME | | Quote & sign-off |
| `primary_technician_id`, `assigned_bay_id` | BIGINT UNSIGNED | FK, NULL | Resource allocation |
| `scheduled_start_at`, `actual_start_at`, `estimated_completion_at`, `actual_completion_at` | DATETIME | | Timeline tracking |
| `delivery_method`, `delivery_address` | ENUM / JSON | | Handover logistics |
| `handover_notes`, `created_by` | TEXT / BIGINT UNSIGNED | | Final notes & audit |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `job_tasks`, `job_inspection_records`, `invoices`

#### 🔹 `inspection_templates`, `job_inspection_records`
**Purpose:** Master checklist catalog + instance tracker for dispute-proof intake/delivery.
- `inspection_templates`: `(name, code, component_name, component_category, expected_condition, is_mandatory, requires_photo, sort_order, tenant_id, is_active)`
- `job_inspection_records`: `(job_id, template_id, inspection_phase, component_name, category, condition_status, severity, notes, media_urls (JSON), signature_url, inspected_by, customer_acknowledged, acknowledged_at)`
**Rules:** Auto-populated from templates on job creation. Pre-delivery auto-compares vs intake to flag new damage.

#### 🔹 `service_bays`
**Purpose:** Physical workstations & lifts for capacity-aware routing.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `name`, `code` | BIGINT / VARCHAR | UNIQUE `(code, tenant_id)` | Bay identity |
| `bay_type` | ENUM('general_lift','alignment','paint_booth','wash_bay','diagnostic','waiting_area') | NOT NULL | Routing filter |
| `capacity_concurrent` | TINYINT UNSIGNED | DEFAULT 1 | Max simultaneous jobs |
| `equipment_features` | JSON | NULLABLE | Tooling tags |
| `status` | ENUM('available','occupied','maintenance','reserved') | DEFAULT 'available' | Real-time state |
| `is_active`, `sort_order` | TINYINT / INT | | UI control |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Impact:** Algorithm matches job requirements → bay type/equipment → availability.

---

### 5️⃣ Inventory & Supply Chain

#### 🔹 `parts_categories`
**Purpose:** Hierarchical grouping for inventory items.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `name`, `code` | VARCHAR | UNIQUE `(code, tenant_id)` | Display & key |
| `parent_id` | BIGINT UNSIGNED | FK → `parts_categories.id`, NULL | Self-referencing hierarchy |
| `tenant_id`, `is_active`, `sort_order` | BIGINT / TINYINT / INT | | Scope & UI order |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `inventory_items`

#### 🔹 `inventory_items`
**Purpose:** Lightweight parts catalog + stock tracker.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `sku` | BIGINT / VARCHAR | UNIQUE `(tenant_id, sku)` | Scope & internal code |
| `name`, `description`, `brand` | VARCHAR / TEXT | | Catalog data |
| `category_id`, `unit_of_measure` | BIGINT / ENUM | | Grouping & counting |
| `cost_price`, `selling_price`, `tax_rate_id` | DECIMAL / BIGINT | | Pricing & GST |
| `stock_on_hand`, `low_stock_threshold`, `reorder_quantity` | INT UNSIGNED | DEFAULTS | Stock management |
| `preferred_vendor_id`, `requires_serial_warranty`, `is_active` | BIGINT / TINYINT | | Supplier & tracking flags |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Auto-decrement on job task creation. Low-stock cron triggers vendor reorder alerts.

#### 🔹 `vendors`
**Purpose:** Supplier & partner management (parts, insurance, towing, workshops).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `name`, `code` | BIGINT / VARCHAR | UNIQUE `(code, tenant_id)` | Scope & identity |
| `vendor_type` | ENUM('parts_supplier','insurance_agent','towing_service','external_workshop','misc') | NOT NULL | Capability filter |
| `contact_*`, `address_*`, `gst_number` | VARCHAR | NULLABLE | Communication & compliance |
| `payment_terms`, `credit_limit`, `current_balance` | ENUM / DECIMAL | | Financial control |
| `rating`, `average_lead_time_days`, `is_preferred`, `is_active` | DECIMAL / TINYINT | DEFAULTS | Performance metrics |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `purchase_orders`, `inventory_items` (preferred)

#### 🔹 `purchase_orders`, `purchase_order_items`
**Purpose:** Procurement header & line items for vendor ordering.
- `purchase_orders`: `(tenant_id, vendor_id, po_number, status, order_date, expected/actual_delivery_date, subtotal, tax_total, grand_total, payment_status, notes, created_by)`
- `purchase_order_items`: `(purchase_order_id, inventory_item_id, quantity_ordered, quantity_received, unit_cost, tax_rate_id, line_total, batch_serial_numbers (JSON))`
**Rules:** Supports partial receipts. Updates `stock_on_hand` & optionally `cost_price` on receipt completion.

---

### 6️⃣ Billing & Payments

#### 🔹 `invoices`
**Purpose:** Customer-facing billing header & receipt.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `customer_id`, `vehicle_id`, `job_id` | BIGINT UNSIGNED | FK, INDEX | Core links |
| `invoice_number` | VARCHAR(50) | UNIQUE `(tenant_id, invoice_number)` | Tenant-scoped ID |
| `type` | ENUM('final','advance','proforma','credit_note','warranty') | DEFAULT 'final' | Document type |
| `status` | ENUM('draft','sent','paid','partially_paid','overdue','void') | DEFAULT 'draft' | Payment lifecycle |
| `issued_date`, `due_date`, `paid_at` | DATETIME / DATE | | Timeline |
| `subtotal`, `tax_total`, `discount_total`, `grand_total` | DECIMAL(12,2) | NOT NULL/DEFAULTS | Financial aggregates |
| `amount_paid`, `balance_due` | DECIMAL(12,2) | DEFAULT/NOT NULL | Tracking |
| `customer_pay_amount`, `insurance_claim_amount` | DECIMAL(12,2) | NULLABLE | Split billing |
| `payment_method`, `payment_reference`, `gateway`, `gateway_transaction_id` | VARCHAR | NULLABLE | Reconciliation |
| `qr_code_url`, `pdf_url`, `customer_notes`, `internal_notes`, `terms_conditions` | VARCHAR / TEXT | NULLABLE | UI & compliance |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `hasMany` → `invoice_items`, `payments`  
**Rules:** Immutable after `status='sent'`. Corrections via `credit_note` type.

#### 🔹 `invoice_items`
**Purpose:** Billable line items (catalog selection + manual entry).
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `invoice_id`, `job_task_id`, `service_item_id`, `part_id` | BIGINT UNSIGNED | FK, NULLABLE | Traceability links |
| `line_type` | ENUM('service','part','labor','package','manual','discount','tax') | NOT NULL | Category |
| `name`, `description` | VARCHAR / TEXT | NOT NULL/NULL | Display details |
| `quantity`, `unit_price`, `tax_rate_id`, `tax_amount`, `discount_amount`, `total_amount` | DECIMAL / BIGINT | NOT NULL/DEFAULTS | Calculation fields |
| `is_taxable`, `sort_order`, `internal_notes` | TINYINT / INT / TEXT | DEFAULT/NULLABLE | Control & staff notes |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Supports quick manual entry + catalog auto-fill. Aggregates to invoice header.

#### 🔹 `payments`
**Purpose:** Transaction log & reconciliation for invoices.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `invoice_id`, `payment_method_id` | BIGINT UNSIGNED | FK, INDEX | Core links |
| `amount`, `currency` | DECIMAL / CHAR | DEFAULT 'INR' | Transaction value |
| `status` | ENUM('pending','processing','success','failed','refunded','partial_refund','chargeback') | DEFAULT 'pending' | Gateway state |
| `payment_type` | ENUM('customer_pay','insurance_claim','advance','refund','adjustment') | DEFAULT 'customer_pay' | Purpose |
| `reference_number`, `gateway_transaction_id`, `gateway_response (JSON)` | VARCHAR | NULLABLE | External tracking |
| `paid_at`, `failed_reason`, `refunded_amount`, `refunded_at`, `reconciled_at`, `notes` | DATETIME / TEXT / DECIMAL | NULLABLE | Lifecycle & audit |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Webhook-driven status updates. Supports split payments. `reconciled_at` for bank matching.

#### 🔹 `payment_methods`
**Purpose:** Tenant-configurable payment channels for checkout & reconciliation.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id` | BIGINT UNSIGNED | NULLABLE, INDEX | `NULL` = global defaults; `SET` = tenant override |
| `name`, `code` | VARCHAR | UNIQUE `(code, tenant_id)`, NOT NULL | Display & programmatic ID |
| `type` | ENUM('cash','digital','card','cheque','insurance','split') | NOT NULL, INDEX | Processing flow |
| `gateway_provider` | VARCHAR(50) | NULLABLE | "razorpay", "phonepe", "cashfree" |
| `requires_reference` | TINYINT(1) | DEFAULT 0 | Enforce transaction ID/cheque capture |
| `processing_fee_type`, `processing_fee_value` | ENUM / DECIMAL | DEFAULT 'none'/0.00 | Future monetization |
| `is_active`, `sort_order` | TINYINT / INT | DEFAULT 1/0 | UI control & ordering |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `belongsTo` → `tenants`; `hasMany` → `payments`  
**Rules:** Global defaults copied on onboarding; tenants enable/disable per operational capability. `type='split'` enables multi-payer billing.

#### 🔹 `tax_rates`
**Purpose:** Region-aware GST/VAT configuration & billing compliance.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id` | BIGINT UNSIGNED | NULLABLE, INDEX | `NULL` = global/default; `SET` = tenant override |
| `name`, `code` | VARCHAR | UNIQUE `(code, tenant_id)`, NOT NULL | Display & programmatic ID |
| `tax_type` | ENUM('gst','vat','service_tax','luxury_tax','cess','nil') | DEFAULT 'gst' | Tax regime |
| `rate_percentage` | DECIMAL(5,2) | NOT NULL | Actual rate (e.g., 18.00) |
| `is_compound`, `component_breakdown (JSON)` | TINYINT / JSON | DEFAULT 0/NULL | CGST+SGST split support |
| `applicable_to` | ENUM('services','parts','both') | DEFAULT 'both' | Scope |
| `region_scope`, `state_code` | ENUM / CHAR(2) | DEFAULT 'all_india'/NULL | Geographic applicability |
| `hsn_sac_codes (JSON)`, `effective_from`, `effective_to` | JSON / DATE | NULLABLE/NOT NULL/NULL | Compliance & temporal rates |
| `is_active`, `is_default`, `sort_order` | TINYINT / TINYINT / INT | DEFAULT 0/1/0 | UI control & fallback |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Relations:** `belongsTo` → `tenants`; `hasMany` → `invoice_items`, `inventory_items`  
**Rules:** Auto-resolves rate by tenant location + item type + effective date. Supports compound taxes with JSON breakdown for invoice display. Temporal fields handle GST rate changes without breaking historical invoices.

----

### 7️⃣ Scheduling & Communication

#### 🔹 `appointments`
**Purpose:** Pre-intake scheduling & slot management.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `customer_id`, `vehicle_id`, `service_category_id` | BIGINT UNSIGNED | FK, INDEX | Booking entities |
| `appointment_number` | VARCHAR(50) | UNIQUE `(tenant_id, appointment_number)` | Tracking ID |
| `scheduled_date`, `start_time`, `end_time` | DATE / TIME | NOT NULL | Slot definition |
| `status` | ENUM('booked','confirmed','checked_in','completed','no_show','cancelled') | DEFAULT 'booked' | Lifecycle |
| `source`, `assigned_technician_id`, `assigned_bay_id` | ENUM / BIGINT | NULLABLE | Channel & pre-allocation |
| `converted_job_id`, `reminder_sent_at`, `customer_acknowledged`, `notes` | BIGINT / DATETIME / TINYINT / TEXT | NULLABLE | Conversion & tracking |
| `created_by` | BIGINT UNSIGNED | FK → `users.id`, NULL | Booked by |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Collision prevention via overlapping time queries. Converts to `service_jobs` on check-in.

#### 🔹 `notification_templates`, `notifications`
**Purpose:** UI-configurable message engine + immutable delivery log.
- `notification_templates`: `(tenant_id, event_code, name, channel, subject, template_body, is_active)`
- `notifications`: `(tenant_id, customer_id, template_id, channel, recipient, content_snapshot (TEXT), status, external_id, reference_type/reference_id, sent_at)`
**Rules:** `event_code` drives triggers. `content_snapshot` preserves legal proof. Webhooks update delivery status. Added event codes: `mileage_due`, `time_due`, `job_status_updated`, `odometer_confirmation_needed`.

#### 🔹 `feedback_reviews`
**Purpose:** Post-service satisfaction & technician performance tracking.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `customer_id`, `job_id`, `technician_id` | BIGINT UNSIGNED | FK, UNIQUE `(job_id)` | Context links |
| `rating_overall` | TINYINT UNSIGNED | NOT NULL | 1-5 scale |
| `rating_breakdown` | JSON | NULLABLE | Dimension scores |
| `comments`, `channel` | TEXT / ENUM | | Feedback content & source |
| `status` | ENUM('requested','submitted','needs_attention','resolved','escalated') | DEFAULT 'requested' | Follow-up flow |
| `response_text`, `responded_by`, `response_at`, `sent_at`, `submitted_at` | TEXT / BIGINT / DATETIME | NULLABLE | Resolution tracking |
| `is_anonymous` | TINYINT(1) | DEFAULT 0 | Privacy flag |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |
**Rules:** Rating ≤3 auto-triggers `needs_attention`. Feeds technician performance metrics.

---

### 8️⃣ Loyalty & Retention

#### 🔹 `loyalty_programs`
**Purpose:** Tenant-configurable points engine.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id` | BIGINT UNSIGNED | UNIQUE | One active per garage |
| `name` | VARCHAR(100) | NOT NULL | Program title |
| `earning_mode` | ENUM('spend_based','visit_based','service_based') | DEFAULT 'spend_based' | Accumulation logic |
| `points_per_amount`, `min_spend_threshold` | DECIMAL | DEFAULTS | Earning rules |
| `redemption_rate`, `min_points_to_redeem`, `max_discount_percent` | DECIMAL / INT / TINYINT | DEFAULTS | Checkout caps |
| `points_expiry_days`, `stack_with_other_discounts`, `is_active` | INT / TINYINT | DEFAULTS | Validity & stacking |
| `created_at`, `updated_at`, `deleted_at` | TIMESTAMP | Auto/Soft | Audit |

#### 🔹 `loyalty_transactions`
**Purpose:** Immutable points ledger.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `customer_id` | BIGINT UNSIGNED | FK, INDEX | Scope & owner |
| `type` | ENUM('earned','redeemed','expired','adjusted','voided') | NOT NULL | Movement category |
| `points`, `balance_after` | INT / INT UNSIGNED | NOT NULL | Amount & running total |
| `reference_type`, `reference_id` | VARCHAR / BIGINT | NULLABLE | Source entity link |
| `expires_at`, `description` | DATETIME / TEXT | NULLABLE | Expiry & audit note |
| `created_at` | TIMESTAMP | Auto, INDEX | Transaction time |
**Rules:** Append-only. FIFO expiry via cron. `garage_customers.loyalty_points` = read-through cache.

---

### 9️⃣ Audit & System Tracking

#### 🔹 `audit_logs`
**Purpose:** Immutable activity tracker for SaaS operations & compliance.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `tenant_id`, `user_id`, `impersonator_id` | BIGINT UNSIGNED | NULLABLE/INDEX | Actor & scope |
| `action_type`, `target_type` | VARCHAR(50) | NOT NULL, INDEX | Event & entity |
| `target_id` | BIGINT UNSIGNED | NULLABLE, INDEX | Modified record ID |
| `old_values`, `new_values` | JSON | NULLABLE | State diffs |
| `ip_address`, `user_agent`, `notes` | VARCHAR / TEXT | NULLABLE | Forensics & context |
| `created_at` | TIMESTAMP | Auto, INDEX | Timestamp |
**Rules:** Logs financial changes, workflow transitions, impersonation. Immutable. Hot/cold archival strategy.

#### 🔹 `customer_app_sessions`
**Purpose:** Push token management & app engagement tracking for mobile/web clients.
| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK, AI | Internal FK |
| `customer_id` | BIGINT UNSIGNED | FK → `customers.id`, NOT NULL, INDEX | Global customer |
| `device_token` | VARCHAR(255) | NOT NULL | FCM/APNS push token |
| `platform` | ENUM('ios','android','web') | NOT NULL | Client platform |
| `app_version`, `last_active_at` | VARCHAR / DATETIME | NULLABLE | Feature flagging & engagement |
| `is_active` | TINYINT(1) | DEFAULT 1 | Toggle push delivery |
| `created_at`, `updated_at` | TIMESTAMP | Auto | Audit |
**Rules:** Auto-prunes inactive tokens >90 days. Enables targeted push campaigns.

---

## 🔗 Complete ERD & Relationship Map
[TENANTS] 1 ──< [USERS] (Staff/Owners)
│ │
├──────────────┼─< [TENANT_MEMBERSHIPS] (Junction)
│ │
├─< [SUBSCRIPTION_PLANS] 1 ──< [TENANT_SUBSCRIPTIONS]
│
├─< [CUSTOMERS] 1 ──< [GARAGE_CUSTOMERS] (Junction: Tenant + Customer + Metadata)
│ │
│ └─< [VEHICLES] 1 ──< [SERVICE_JOBS]
│ │ │
│ ├─< [VEHICLE_DOCUMENTS] ├─< [JOB_SERVICE_CATEGORIES] (Junction)
│ │ ├─< [JOB_TASKS] 1 ──< [INVOICE_ITEMS]
│ │ │ │ │
│ │ │ └─< [SERVICE_ITEMS] ──< [SERVICE_ITEM_SKILLS] ──> [SKILLS]
│ │ │
│ │ ├─< [JOB_INSPECTION_RECORDS] ──< [INSPECTION_TEMPLATES]
│ │ │
│ │ └─< [INVOICES] 1 ──< [INVOICE_ITEMS]
│ │ │
│ │ └─< [PAYMENTS] ──< [PAYMENT_METHODS]
│ │
│ └─< [APPOINTMENTS] ──(converts to)── [SERVICE_JOBS]
│
├─< [SERVICE_CATEGORIES] 1 ──< [SERVICE_ITEMS]
│
├─< [SERVICE_BAYS]
│
├─< [VENDORS] 1 ──< [PURCHASE_ORDERS] 1 ──< [PURCHASE_ORDER_ITEMS]
│ │ │
│ └─< [INVENTORY_ITEMS] ─────┘
│ │
│ └─< [PARTS_CATEGORIES]
│
├─< [TAX_RATES] ──> [INVOICE_ITEMS], [PURCHASE_ORDER_ITEMS], [INVENTORY_ITEMS]
│
├─< [NOTIFICATION_TEMPLATES] 1 ──< [NOTIFICATIONS] ──< [CUSTOMERS], [TENANTS]
│
├─< [FEEDBACK_REVIEWS] ──> [SERVICE_JOBS], [USERS (Technicians)]
│
├─< [LOYALTY_PROGRAMS] ──< [LOYALTY_TRANSACTIONS] ──< [CUSTOMERS], [GARAGE_CUSTOMERS]
│
├─< [VEHICLE_MILEAGE_LOGS] ──> [VEHICLES]
├─< [SERVICE_INTERVAL_PREFERENCES] ──> [VEHICLES]
├─< [CUSTOMER_ENGAGEMENT_EVENTS] ──> [CUSTOMERS]
├─< [CUSTOMER_APP_SESSIONS] ──> [CUSTOMERS]
│
└─< [AUDIT_LOGS] (Polymorphic: targets any entity)

7. **Future Scaling Paths**:
   - `inventory_ledger` table — replace denormalized `stock_on_hand` with append-only ledger entries for full auditability and multi-location stock isolation.
   - `vehicle_makes/models` normalization — replace free-text `maker`/`model`/`variant` VARCHAR fields with a seeded lookup table to enable analytics grouping and fleet reporting.
   - Multi-location routing — introduce a `locations` table; add `location_id` FK to `service_bays`, `users`, and `service_jobs` to support multi-branch tenants.
   - **`tenant_memberships` (Phase 2)** — activate the deferred junction table (schema defined in Section 2️⃣) to replace single-tenant role assignment with full multi-tenant staff membership, invitation flows, and per-user permission overrides.
   - `subscription_plan_features` table — replace the `features` JSON/array on `subscription_plans` with a normalized feature-flag table for granular plan gating without schema changes.

---

## 📋 Implementation Guidelines
1. **Multi-Tenant Isolation**: Enforce `tenant_id` via Laravel Global Scopes on all non-master tables. Never query without tenant context.
2. **Soft Deletes Everywhere**: `deleted_at` preserves historical integrity for invoices, jobs, and compliance records.
3. **No Hardcoded Enums for Business Logic**: All workflows, categories, templates, and limits are UI-configurable via master/tenant tables.
4. **Index Strategy**: Prioritize `(tenant_id, foreign_key, status)` composites for dashboard queries. Use covering indexes for dropdowns.
5. **Event-Driven Architecture**: Use Laravel Model Observers + Queues for:
   - Stock deduction on job task creation
   - Ledger updates for loyalty points
   - Notification dispatch on job status changes
   - Invoice status recalculation on payment webhook
6. **Audit & Compliance**: `audit_logs` + `notifications.content_snapshot` + `job_inspection_records.signature_url` = dispute-proof trail.
7. **Future Scaling Paths**:
   - `inventory_ledger` (replace denormalized `stock_on_hand`)
   - `vehicle_makes/models` normalization (replace VARCHAR fields)
   - Multi-location routing (`locations` table → `service_bays.tenant_location_id`)

---
**✅ PRD Status**: Schema Design Complete. Ready for Migration Generation & UI Wireframing.  
**Next Step**: Generate Laravel migrations, seed master data, and begin React/Flutter component architecture.