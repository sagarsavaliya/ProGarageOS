# Pro Garage OS — Development Progress

**Last Updated:** 2026-05-22 IST (EOD)
**Current Phase:** Staff app v1 — awaiting device sign-off
**Production API:** `https://api.progarage.cloud/api` · commit `80d6eaa`
**Release APK:** `build/app/outputs/flutter-apk/app-release.apk` (63.4MB)
**Overall Status:** Staff v1 built & deployed — gate: CEO device E2E sign-off

---

## Active Sprint: S1

### Completed Tasks ✅

- [x] `pubspec.yaml` — Added `google_fonts ^6.2.1`, `fl_chart ^0.67.0`, `local_auth ^2.3.0` — 2026-05-14
- [x] `lib/core/constants/app_colors.dart` — Full dark-first color palette (primaryOrange, bgPrimary, status colors) — 2026-05-14
- [x] `lib/core/constants/app_sizes.dart` — Spacing, radius, touch-target, nav constants — 2026-05-14
- [x] `lib/core/constants/app_text_styles.dart` — Sora (display), DM Sans (body), DM Mono (numbers) — 2026-05-14
- [x] `lib/core/theme/app_theme.dart` — Updated to industrial dark theme with primaryOrange — 2026-05-14
- [x] `lib/core/storage/secure_storage.dart` — Extended with user JSON, saved-login, PIN fail-count, lockout expiry — 2026-05-14
- [x] `lib/core/widgets/app_status_chip.dart` — Status → colored dot+label chip widget — 2026-05-14
- [x] `lib/features/auth/data/models/auth_models.dart` — `UserModel`, `StaffAuthResponse`, `StaffLoginRequest`, `OtpRequestBody`, `OtpVerifyRequest` — 2026-05-14
- [x] `lib/features/auth/data/auth_repository.dart` — `loginStaff`, `logout`, `requestOtp`, `verifyOtp` — 2026-05-14
- [x] `lib/features/auth/presentation/providers/staff_login_provider.dart` — `StaffLoginNotifier` with PIN entry, 5-attempt lockout (30s), biometric, switch-user — 2026-05-14
- [x] `lib/features/auth/presentation/screens/login_screen.dart` — Pixel-perfect PIN pad screen from `02-Staff-Login.html`; dot grid bg, saved-user card, 6-dot PIN indicator, 3×4 numpad, biometric button, lock overlay with countdown — 2026-05-14
- [x] `lib/features/auth/presentation/screens/otp_screen.dart` — Customer OTP flow; phone input → 6-digit OTP entry with auto-advance, resend cooldown — 2026-05-14
- [x] `lib/features/dashboard/data/models/dashboard_models.dart` — `DashboardSummary`, `RevenuePoint`, `ServiceBay`, `ActiveJob` + demo data fallback — 2026-05-14
- [x] `lib/features/dashboard/presentation/providers/dashboard_provider.dart` — `DashboardNotifier` with period selector, API fetch + demo fallback, 60s auto-refresh — 2026-05-14
- [x] `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — Full dashboard adapted from `03-Dashboard.html` to dark theme: app bar with greeting+date+notif bell, period chips, 4 KPI cards (horizontal scroll), fl_chart revenue sparkline, service bays 2×2 grid with progress bars, active jobs list with status chips — 2026-05-14
- [x] `lib/core/router/app_router.dart` — Added `/auth/otp` route; `ScaffoldWithNav` with 4-tab bottom navigation (Dashboard, Jobs, Customers, More) using `primaryOrange` active state — 2026-05-14
- [x] `build_runner` — Regenerated all `.g.dart` files (riverpod, drift codegen) — 2026-05-14
- [x] `flutter analyze` — **Zero issues** — 2026-05-14

### In Progress 🔄

*(None — all S1 tasks shipped)*

### Blocked ⛔

- **Biometric auth (login screen):** Requires a real Android/iOS device with fingerprint enrolled. Works correctly in code — `local_auth` is wired up. Cannot test on emulator without biometric enrollment.
- **Real API integration:** Backend at `http://10.0.2.2:8000/api` must be running on host machine. Dashboard falls back gracefully to embedded demo data when API is unreachable.
- **`google-services.json`:** Firebase not yet configured — FCM (Sprint 8) will require this file from the Firebase Console.

---

## Sprint S3 — Flutter Jobs Module ✅

### Completed Tasks ✅

- [x] `lib/features/jobs/data/models/job_models.dart` — `Job`, `JobDetail`, `JobCustomer`, `JobVehicle`, `JobTechnician`, `JobServiceBay`, `TasksSummary`, `TaskItem`, `PaginatedJobs` + `jobsDemoData` fallback — 2026-05-15
- [x] `lib/features/jobs/data/jobs_repository.dart` — `fetchJobs` (paginated + filters), `fetchJob` (detail), `updateStatus` — 2026-05-15
- [x] `lib/features/jobs/presentation/providers/jobs_provider.dart` — `JobsNotifier` (status filter, search debounce 400ms, pagination, demo fallback) + `jobDetailProvider` family — 2026-05-15
- [x] `lib/features/jobs/presentation/screens/jobs_screen.dart` — Status filter tabs (7 filters), search bar, infinite scroll list with `_JobListTile`, shimmer loading, empty + error states, pull-to-refresh, FAB — 2026-05-15
- [x] `lib/features/jobs/presentation/screens/job_detail_screen.dart` — App bar, status banner, vehicle+customer card, tasks list, billing summary, timeline — 2026-05-15
- [x] `lib/core/router/app_router.dart` — `/jobs/:id` → `JobDetailScreen(jobUuid: id)` — 2026-05-15
- [x] `flutter analyze` — Zero issues — 2026-05-15

### Blocked ⛔

- **Real API integration:** Same as S1/S2 — backend must be running. Jobs screen falls back to `jobsDemoData` when API is unreachable.

---

## Sprint S2 — Laravel Backend ✅

### Completed Tasks ✅

**MySQL Database — 40 Tables (all in `Apps/api/database/migrations/`)**
- [x] `tenants` — Garage business accounts (multi-tenant root)
- [x] `subscription_plans` + `tenant_subscriptions` — SaaS billing lifecycle
- [x] `users` — Staff (owner, technician, advisor, manager) with PIN hash
- [x] `tenant_memberships` — Phase 2 stub (multi-tenant staff junction)
- [x] `customers` — Global customer identity + OTP fields
- [x] `garage_customers` — Junction: tenant ↔ customer + loyalty/analytics cache
- [x] `vehicles` — RC-compliant (fuel, chassis, engine, insurance, permit, odometer, GPS consent)
- [x] `vehicle_documents` — RC, Insurance, PUC, Fitness, Permit tracker
- [x] `vehicle_mileage_logs` — Append-only odometer ledger (consent-based)
- [x] `service_interval_preferences` — Per-vehicle reminder settings
- [x] `service_categories` + `service_items` — Billable task catalog
- [x] `skills` + `technician_skills` + `service_item_skills` — Skill routing
- [x] `service_bays` — Physical workstations (lift, alignment, wash, diagnostic)
- [x] `service_jobs` — Central job card (draft → delivered lifecycle, 11 statuses)
- [x] `job_tasks` — Dynamic per-job task tracker (source, approval, liability)
- [x] `job_service_categories` — Job ↔ category junction
- [x] `inspection_templates` + `job_inspection_records` — Dispute-proof inspection
- [x] `tax_rates` — GST/VAT config (CGST+SGST breakdown, temporal rates)
- [x] `invoices` + `invoice_items` — Billing header + line items (7 line types)
- [x] `payment_methods` + `payments` — Transaction log + reconciliation
- [x] `parts_categories` + `vendors` + `inventory_items` — Parts catalog + stock
- [x] `purchase_orders` + `purchase_order_items` — Procurement (partial receipts)
- [x] `appointments` — Pre-intake scheduling
- [x] `notification_templates` + `notifications` — Event-driven delivery log
- [x] `feedback_reviews` — Post-service CSAT + technician rating
- [x] `loyalty_programs` + `loyalty_transactions` — Points ledger (append-only, FIFO expiry)
- [x] `audit_logs` — Immutable activity tracker (polymorphic, JSON diffs)
- [x] `customer_app_sessions` — Push token management
- [x] `customer_engagement_events` — Behavioral intelligence

**Eloquent Models — 31 Models (all in `Apps/api/app/Models/`)**
- [x] All models with `$fillable`, `$casts`, relationships, `SoftDeletes`, `HasApiTokens`
- [x] UUID auto-generation on boot (`Str::uuid()`)
- [x] `ServiceJob` — Global scope for tenant isolation
- [x] `Invoice::recalculate()` — Auto-aggregates line items + payments
- [x] `Customer::generateOtp()` / `verifyOtp()` — OTP lifecycle
- [x] `User::verifyPin()` — PIN hash comparison
- [x] `VehicleDocument::isExpired()` / `isExpiringSoon()` — Compliance helpers

**Laravel API Controllers (all in `Apps/api/app/Http/Controllers/Api/`)**
- [x] `AuthController` — Staff PIN login, Customer OTP request/verify, logout, /me
- [x] `DashboardController` — KPIs, revenue chart (7d), service bays, active jobs
- [x] `CustomerController` — List (search/paginate), show, create, update
- [x] `VehicleController` — CRUD + odometer update + mileage log
- [x] `ServiceJobController` — List (filter/search), show (full detail), create, status update, update
- [x] `InvoiceController` — List, show (with line items), create (with items), record payment
- [x] `ServiceBayController` — List with current job, status update
- [x] `InventoryController` — List (search/low-stock filter), create, stock adjustment

**Routes & Infrastructure (`Apps/api/routes/api.php`)**
- [x] `GET /api/health` — Health check
- [x] Auth routes with rate limiting (OTP: 5/10min, Staff login: 10/15min)
- [x] All staff routes behind `auth:sanctum` + 300/min throttle
- [x] Standard error envelope in `bootstrap/app.php` (ValidationException, AuthException, ModelNotFound, RateLimit)

**Database Seeders (`Apps/api/database/seeders/`)**
- [x] Demo tenant: "Patel Auto Works" (Surat, Gujarat)
- [x] 4 staff users (owner, 2 technicians, service advisor) with test PINs
- [x] 6 service categories + 18 service items
- [x] 5 service bays (lifts, alignment, wash, diagnostic)
- [x] GST tax rates (18%, 12%, 5%, nil)
- [x] 6 payment methods (cash, UPI, card, net banking, cheque, insurance)
- [x] 5 demo customers + vehicles + active jobs with invoices

---

## Sprint S4 — Flutter Customers + Vehicles ✅

### Completed Tasks ✅

- [x] `lib/features/customers/data/models/customer_models.dart` — `Customer`, `CustomerDetail`, `GarageProfile`, `CustomerVehicleSummary`, `RecentJobSummary`, `Vehicle`, `ComplianceAlert`, `VehicleDocument`, `PaginatedCustomers` + demo fallback — 2026-05-15
- [x] `lib/features/customers/data/customers_repository.dart` — `fetchCustomers`, `fetchCustomer`, `fetchVehicles`, `fetchDocuments` — 2026-05-15
- [x] `lib/features/customers/presentation/providers/customers_provider.dart` — `CustomersNotifier` (search debounce, pagination), `customerDetailProvider`, `customerVehiclesProvider`, `vehicleDocumentsProvider` — 2026-05-15
- [x] `lib/features/customers/presentation/screens/customers_screen.dart` — Search bar, paginated list, `_CustomerListTile` (avatar, stats, relative date), Add Customer FAB — 2026-05-15
- [x] `lib/features/customers/presentation/screens/customer_detail_screen.dart` — Profile card, action buttons, 3-stat row, horizontal vehicle scroll, recent jobs list — 2026-05-15
- [x] `lib/features/vehicles/presentation/screens/vehicle_detail_screen.dart` — Compliance alert banner, identity card, specs grid, documents list with expiry status — 2026-05-15
- [x] `lib/features/vehicles/presentation/screens/vehicles_screen.dart` — Updated stub (fleet view planned later) — 2026-05-15
- [x] `lib/core/router/app_router.dart` — `/customers/:id` → `CustomerDetailScreen`, `/vehicles/:id` → `VehicleDetailScreen` (with customer UUID via `extra`) — 2026-05-15
- [x] `flutter analyze` — Zero issues — 2026-05-15

---

## QA Audit Fixes — All Issues Resolved ✅

**Completed: 2026-05-15 11:15 IST**

### Critical Fixes (previously completed)
- [x] `auth_models.dart` — `UserModel.fromJson` rewrote to match API: `uuid`, `first_name`/`last_name`, `roles[]`, `tenant.business_name`
- [x] `auth_models.dart` — `OtpVerifyRequest` added `device_token`, `platform`, `app_version`
- [x] `dashboard_models.dart` — `ActiveJob` added `uuid` field; navigation fixed
- [x] `jobs_repository.dart` — Status update changed from PUT → PATCH
- [x] `app_status_chip.dart` — All 11 job statuses now mapped
- [x] `app_router.dart` — Detail screens moved outside `ShellRoute` (no bottom nav on detail screens)

### Warning/Design Fixes (completed this session)
- [x] `pubspec.yaml` — Added `phosphor_flutter ^2.1.0` + `url_launcher ^6.3.1`
- [x] `core/widgets/app_button.dart` — Created `AppButton` shared widget (4 variants: primary, secondary, outlined, ghost)
- [x] `core/widgets/app_text_field.dart` — Created `AppTextField` shared widget (label, hint, error, prefix/suffix)
- [x] `jobs_screen.dart` + `customers_screen.dart` — Replaced custom `AnimationController` shimmer with `shimmer` package
- [x] `auth_repository.dart` + `otp_screen.dart` — OTP resend cooldown now reads `Retry-After` header (not static 30s)
- [x] `customer_detail_screen.dart` — Call/WhatsApp buttons now launch `tel:` and `whatsapp://` deep links via `url_launcher`
- [x] `features/splash/presentation/splash_screen.dart` — Full splash screen built (dot grid bg, ambient glow, animated wordmark, pulsing dot, Continue button)
- [x] `app_router.dart` — Splash route `/` added as initial route
- [x] All 11 screens — Material icons replaced with `phosphor_flutter` (caretLeft, squaresFour, users, clipboardText, magnifyingGlass, phone, car, etc.)

---

## Sprint S5 — Flutter Invoicing + Payments ✅

### Completed Tasks ✅

- [x] `lib/features/invoices/data/models/invoice_models.dart` — `InvoiceListItem`, `InvoiceDetail`, `InvoiceItem`, `PaymentRecord`, `PaymentMethod`, `RecordPaymentRequest`, `PaginatedInvoices` + rich demo data (5 invoices with 3-4 items each, multiple statuses) — 2026-05-15
- [x] `lib/features/invoices/data/invoices_repository.dart` — `fetchInvoices` (paginated + filters), `fetchInvoice` (detail with items), `recordPayment`, `fetchPaymentMethods` — 2026-05-15
- [x] `lib/features/invoices/presentation/providers/invoices_provider.dart` — `InvoicesNotifier` (status filter, search debounce 400ms, pagination, demo fallback), `invoiceDetailProvider` (family + `recordPayment`), `paymentMethodsProvider` — 2026-05-15
- [x] `lib/features/invoices/presentation/screens/invoices_screen.dart` — 7-filter status tabs, search bar, infinite scroll list with `_InvoiceListTile`, shimmer loading, empty + error states, pull-to-refresh — 2026-05-15
- [x] `lib/features/invoices/presentation/screens/invoice_detail_screen.dart` — App bar with status chip, customer + vehicle card, line items list with type color chips, financial summary card, payments list, `_RecordPaymentSheet` bottom sheet (amount, method chips, reference, notes, success snackbar) — 2026-05-15
- [x] `lib/core/router/app_router.dart` — `/invoices` in ShellRoute, `/invoices/:id` outside ShellRoute; replaced "More" tab with "Invoices" (receipt icon) — 2026-05-15
- [x] `lib/core/widgets/app_status_chip.dart` — Added `sent`, `paid`, `partially_paid`, `void` invoice statuses — 2026-05-15
- [x] `flutter analyze` — Zero issues — 2026-05-15

---

## Sprint S6 — Inventory + Parts Management ✅

### Completed Tasks ✅

- [x] `lib/features/inventory/data/models/inventory_models.dart` — `InventoryItem` (with `isLowStock`, `isOutOfStock`, `stockStatus`, `marginPercent` computed getters), `StockAdjustment`, `InventoryDetail`, `PartsCategory`, `AddStockAdjustmentRequest`, `PaginatedInventory`, `StockStatus` enum + 12-item demo data (4 categories, 2 out-of-stock, 3 low-stock) — 2026-05-15
- [x] `lib/features/inventory/data/inventory_repository.dart` — `fetchItems` (paginated + search + categoryId + lowStockOnly), `fetchItem` (detail), `adjustStock`, `fetchCategories`; API-first with demo fallback — 2026-05-15
- [x] `lib/features/inventory/presentation/providers/inventory_provider.dart` — `InventoryNotifier` (search debounce 400ms, category filter, low-stock toggle, pagination, demo fallback), `InventoryDetailNotifier` (adjust stock with optimistic update), `inventoryDetailProvider` family, `partsCategoriesProvider` — 2026-05-15
- [x] `lib/features/inventory/presentation/screens/inventory_screen.dart` — Header with count badge + low-stock alert pill, horizontal filter chips (All / Low Stock / category chips), search bar, `ListView.builder` with `_InventoryItemTile` (name, SKU badge, category pill, price row, stock qty coloured by status, OUT/LOW/OK badge), shimmer (10 tiles), empty states (healthy / no results), error state, FAB — 2026-05-15
- [x] `lib/features/inventory/presentation/screens/inventory_detail_screen.dart` — SliverAppBar (item name, SKU, active chip), stock card (48px mono qty, coloured status, LinearProgressIndicator, min/max labels), info card (3-col SKU/Category/Unit grid, selling/cost prices, margin %, notes), adjust stock section (Quick +10 / +1 buttons with per-button loading, Custom opens `_StockAdjustSheet`), recent adjustments list (type icon, reason, adjusted-by, date); `_StockAdjustSheet` (Add/Remove/Set type chips, qty field, reason field, validation, success snackbar) — 2026-05-15
- [x] `lib/core/router/app_router.dart` — `/inventory` in ShellRoute, `/inventory/add` (stub) + `/inventory/:id` outside ShellRoute (ordered correctly); 5th "Parts" tab added to `ScaffoldWithNav` (`PhosphorIconsRegular.package`); nav icon size 20px, label 9px to fit 5 tabs — 2026-05-15
- [x] `lib/core/widgets/app_status_chip.dart` — Added `out_of_stock`, `low_stock`, `in_stock`, `inactive` inventory statuses — 2026-05-15
- [x] `flutter analyze` — **Zero errors** (49 pre-existing `withOpacity` info-level only) — 2026-05-15

---

## UI Polish Fixes — 2026-05-18 ✅

**Completed: 2026-05-18 IST**

### Dashboard (`dashboard_screen.dart`)
- [x] Period chips: `SizedBox` height reduced 40→36px, wrapped each chip in `Center` for proper vertical centering, chip vertical padding 6→5px
- [x] KPI cards: Outer ListView height increased 106→116px, card padding reduced `fromLTRB(14,16,14,14)` → `fromLTRB(12,12,12,10)`, `mainAxisSize` changed `min`→`max` so `Spacer` distributes space correctly, value font 26px→22px, added `TextOverflow.ellipsis` on label and delta texts — eliminates 20px bottom overflow

### Jobs (`jobs_screen.dart`)
- [x] Filter chips: `SizedBox` height 48→38px, removed top padding, wrapped `AnimatedContainer` in `Center` for vertical centering
- [x] FAB: Changed from `FloatingActionButton.extended` (labeled) to icon-only `FloatingActionButton` with `PhosphorIconsRegular.plus`
- [x] Local search: Added instant local filter against `state.jobs` when `_searchController` has text; debounced API call still runs in background

### Customers (`customers_screen.dart`)
- [x] List overflow: Wrapped each `_StatChip` in `Flexible` inside the stats row; added `Flexible` + `overflow: TextOverflow.ellipsis` inside `_StatChip` text — eliminates 13px right overflow
- [x] FAB: Changed to icon-only `FloatingActionButton` with `PhosphorIconsRegular.plus`
- [x] Local search: Added instant local filter against `state.customers` (name, phone, email)

### Invoices (`invoices_screen.dart`)
- [x] Filter chips: Same fix as Jobs (38px SizedBox, Center wrapping)
- [x] List overflow: Invoice number + job number row wrapped in `Flexible` + `TextOverflow.ellipsis`; right-side amount column wrapped in `SizedBox(width: 96)` to prevent unconstrained width; customer name and amounts also get ellipsis — eliminates 13–24px right overflow
- [x] FAB: Added missing `FloatingActionButton` with `PhosphorIconsRegular.plus` to Scaffold
- [x] Local search: Added instant local filter against `state.invoices` (invoice number, customer name, job number)

### Inventory (`inventory_screen.dart`)
- [x] FAB: Already icon-only — no change needed
- [x] Local search: Added instant local filter against `state.items` (name, SKU, category)

### Login (`login_screen.dart`)
- [x] `_IdentifierInput` container: Added `clipBehavior: Clip.antiAlias` to prevent child overflow outside bounds
- [x] `_PhoneField` + `_EmailField`: Replaced `WidgetsBinding.instance.addPostFrameCallback` autofocus with `Future.delayed(100ms)` + `FocusScope.of(context).requestFocus(_focus)`
- [x] Both text fields: Added `keyboardAppearance: Brightness.dark`

### Analysis
- [x] `flutter analyze lib/features` — **Zero errors** (55 pre-existing `info`-level `withOpacity` deprecation notices only — unchanged from previous sprints)

---

---

## Staff app v1 — E2E Verification Pass ✅ (2026-05-22)

**Commit:** `80d6eaa` · **APK:** `app-release.apk` (63.4MB)

### Fixes verified before build
- [x] Onboarding once; logout preserves onboarding + saved phone
- [x] Full-screen PIN lock; phone auto-fill on login; orange theme
- [x] Dashboard quick-action pills; bay badge layout
- [x] Settings in bottom-nav shell; tab routes for Fleet/Customers/Invoices
- [x] Job: call dialer (detail + list + customer), pull-refresh sync, insurance grid
- [x] Delivery: optional photos, signature scroll lock, mark-delivered prompt
- [x] Delivered read-only (non-owners); estimate lock; add-task full form
- [x] Invoice: payment false-failure fix, billed-job filter, rate clears 0.0
- [x] Vehicle: doc view, replace, delete API; GPS consent from API
- [x] Customer: scoped New job / New invoice; fleet parsing hardened

### Next pickup
> Install APK on device → E2E checklist in `memory/RUNBOOK.md` → sign off staff v1 → start Customer app C0

---

## Next Session Pickup

> **Gate:** Sagar device sign-off on staff v1 (commit `80d6eaa`)
> **After sign-off:** Customer app C0 (auth, job tracking, estimate approval)
> **Deferred:** React Web owner portal until after customer app v1
> **Rule:** No new APK until every checklist item is code-verified

---

## Sprint History

| Sprint | Status | Completed Date | Notes |
|---|---|---|---|
| S0 | ✅ Complete | 2026-05-14 | Core arch: Riverpod, GoRouter, Dio, SecureStorage, Drift, themes |
| S1 | ✅ Complete | 2026-05-14 | Login (PIN pad), OTP, Dashboard, AppShell navigation |
| S2 | ✅ Complete | 2026-05-14 | Laravel backend: 40 MySQL tables, 31 models, API controllers, seeders |
| S3 | ✅ Complete | 2026-05-15 | Jobs module: models, repo, provider, list screen, detail screen |
| S4 | ✅ Complete | 2026-05-15 | Customers + Vehicles (list, detail, docs, compliance) |
| S5 | ✅ Complete | 2026-05-15 | Invoicing + Payments (invoice list, detail, record payment sheet) |
| S6 | ✅ Complete | 2026-05-15 | Inventory + Parts Management (catalog, stock levels, adjust sheet, 5th tab) |
| Staff v1 | ✅ Built | 2026-05-22 | Packs 1–4 + E2E verification; production deploy; APK ready |
| Customer C0 | 🔲 Next | — | Blocked on staff v1 sign-off |
| Web W1 | 🔲 Planned | — | After customer app v1 |
