# Pro Garage OS Flutter — Master Autonomous Build Prompt
> Paste this entire file into Claude Code. It runs end-to-end without further input.
> Claude Code will build, verify, and self-correct each phase before moving to the next.

---

## HOW TO USE

1. Open Claude Code in your terminal: `claude`
2. Paste this entire document as your first message
3. Claude Code will execute all phases sequentially
4. Review the checkpoint output at the end of each phase
5. Type `continue` to proceed or describe any correction needed

---

# MASTER BUILD PROMPT — PRO GARAGE OS FLUTTER

You are an expert Flutter developer building the Pro Garage OS SaaS mobile application for an Indian garage management platform. You have access to the full PRD, API specification, and design system. Execute every phase completely before moving to the next. After each phase, print a checklist of what was built and verify it compiles with `flutter analyze`.

---

## CONTEXT & CONSTRAINTS

**Project**: Pro Garage OS — Multi-tenant garage operations SaaS
**Stack**: Flutter 3.22.x (stable) · Dart 3.4 · Riverpod 2.5 · GoRouter 13 · Dio 5 · Freezed 2
**Two app flavors in one project**:
- `staff` flavor → garage owners, technicians, service advisors (PIN auth)
- `customer` flavor → vehicle owners (OTP auth)
**API Base URL**: `https://api.progarageos.in/v1`
**Auth**: Laravel Sanctum Bearer tokens stored in FlutterSecureStorage
**Realtime**: Pusher Channels (Laravel Reverb backend)
**Indian market**: INR currency, +91 phone prefix, GST tax, RC compliance

**Non-negotiable architecture rules**:
- Every color, spacing, radius references a token class — zero hardcoded values
- Riverpod providers only — no setState except for purely local animation state
- Freezed models for every API response — no Map<String, dynamic> in business logic
- GoRouter for all navigation — no Navigator.push directly
- Dio interceptors handle auth headers, 401 refresh, and error normalization
- Repository pattern: UI → Provider → Repository → Dio → API
- Never call API from a widget directly

---

## DESIGN SYSTEM TOKENS

Implement these exactly. All UI must reference these constants — never hardcode.

### AppColors
```dart
// Ink scale (neutral)
static const ink0 = Color(0xFF0A0E14);   // Primary text
static const ink1 = Color(0xFF1C2230);   // Body text
static const ink2 = Color(0xFF364052);   // Secondary body
static const ink3 = Color(0xFF566076);   // Muted text
static const ink4 = Color(0xFF8898AA);   // Placeholder / caption
static const ink5 = Color(0xFFB8C5D0);   // Disabled text
static const ink6 = Color(0xFFDDE5EC);   // Default border
static const ink7 = Color(0xFFEEF2F6);   // Hover border / dividers
static const ink8 = Color(0xFFF7F9FB);   // Page background
static const ink9 = Color(0xFFFFFFFF);   // Card / surface

// Sky — Primary actions
static const sky50  = Color(0xFFE8F4FD);
static const sky100 = Color(0xFFBEE0F8);
static const sky200 = Color(0xFF90C8F2);
static const sky400 = Color(0xFF2BB0ED);
static const sky600 = Color(0xFF0A7DBF);  // Primary button, links, active
static const sky800 = Color(0xFF065E91);  // Hover
static const sky900 = Color(0xFF033D61);

// Teal — Delivery, GPS, completion
static const teal50  = Color(0xFFEBF7F5);
static const teal200 = Color(0xFF93DDD3);
static const teal400 = Color(0xFF26B8A8);
static const teal600 = Color(0xFF138878);
static const teal800 = Color(0xFF076358);

// Sage — Paid, approved, earned
static const sage50  = Color(0xFFEBF5EE);
static const sage200 = Color(0xFF95D3A2);
static const sage400 = Color(0xFF3BAD5B);
static const sage600 = Color(0xFF1E7F3C);
static const sage800 = Color(0xFF0E5C26);

// Amber — Pending, warning, low stock
static const amber50  = Color(0xFFFEF7EC);
static const amber200 = Color(0xFFF8C96C);
static const amber400 = Color(0xFFF0A018);
static const amber600 = Color(0xFFC07A08);
static const amber800 = Color(0xFF8A5602);

// Rose — Error, expired, cancelled
static const rose50  = Color(0xFFFEF0F0);
static const rose200 = Color(0xFFF79898);
static const rose400 = Color(0xFFEF4444);
static const rose600 = Color(0xFFC01E1E);
static const rose800 = Color(0xFF8A1010);

// Violet — Loyalty, premium
static const violet50  = Color(0xFFF0EFFE);
static const violet200 = Color(0xFFB1ABF8);
static const violet400 = Color(0xFF7C71F0);
static const violet600 = Color(0xFF4F46C8);
static const violet800 = Color(0xFF312E8A);

// Slate — Navigation, sidebar, staff header
static const slate600 = Color(0xFF486581);
static const slate800 = Color(0xFF243B53);
static const slate900 = Color(0xFF102A43);

// Job status color mapping
static Color statusBackground(String status) => switch (status) {
  'draft' || 'intake_inspection'  => ink7,
  'estimate_pending'              => amber50,
  'estimate_approved'             => sky50,
  'in_progress'                   => sky50,
  'qc_pending'                    => teal50,
  'ready_for_delivery'            => teal50,
  'delivered'                     => sage50,
  'cancelled'                     => rose50,
  'on_hold'                       => Color(0xFFF0F4F8),
  _                               => ink7,
};

static Color statusForeground(String status) => switch (status) {
  'draft' || 'intake_inspection'  => ink3,
  'estimate_pending'              => amber800,
  'estimate_approved'             => sky800,
  'in_progress'                   => sky800,
  'qc_pending'                    => teal800,
  'ready_for_delivery'            => teal800,
  'delivered'                     => sage800,
  'cancelled'                     => rose800,
  'on_hold'                       => slate600,
  _                               => ink3,
};

static Color statusDot(String status) => switch (status) {
  'draft' || 'intake_inspection'  => ink4,
  'estimate_pending'              => amber400,
  'estimate_approved'             => sky400,
  'in_progress'                   => sky600,
  'qc_pending'                    => teal400,
  'ready_for_delivery'            => teal600,
  'delivered'                     => sage400,
  'cancelled'                     => rose400,
  'on_hold'                       => slate600,
  _                               => ink4,
};
```

### AppTypography
```dart
// Uses google_fonts package with DM Sans + DM Mono
static TextStyle display   = GoogleFonts.dmSans(fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: -0.025 * 36, color: AppColors.ink0);
static TextStyle title     = GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: -0.015 * 24, color: AppColors.ink0);
static TextStyle heading   = GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.01 * 18, color: AppColors.ink0);
static TextStyle subheading= GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink1);
static TextStyle body      = GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink2, height: 1.7);
static TextStyle small     = GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.ink2);
static TextStyle label     = GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.06 * 11, color: AppColors.ink4);
static TextStyle micro     = GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.08 * 10, color: AppColors.ink5);
static TextStyle mono      = GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.ink2);
static TextStyle monoSmall = GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.ink3);
```

### AppSpacing
```dart
static const double sp1  = 4;   static const double sp2  = 8;
static const double sp3  = 12;  static const double sp4  = 16;
static const double sp5  = 20;  static const double sp6  = 24;
static const double sp8  = 32;  static const double sp10 = 40;
static const double sp12 = 48;  static const double sp16 = 64;

static const double rxXs   = 4;   static const double rxSm  = 6;
static const double rxMd   = 10;  static const double rxLg  = 16;
static const double rxXl   = 24;  static const double rxFull= 999;

static const EdgeInsets cardPadding = EdgeInsets.all(20);
static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 24);
static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
```

### AppMotion
```dart
static const Duration instant = Duration(milliseconds: 80);
static const Duration fast    = Duration(milliseconds: 140);
static const Duration normal  = Duration(milliseconds: 240);
static const Duration slow    = Duration(milliseconds: 380);
static const Duration glacial = Duration(milliseconds: 600);

static const Curve feather     = Cubic(0.16, 1.0, 0.3, 1.0);   // Card reveals, page transitions
static const Curve outQuart    = Cubic(0.25, 1.0, 0.5, 1.0);   // Modal open, hover states
static const Curve spring      = Cubic(0.34, 1.56, 0.64, 1.0); // Button release, badge pop
static const Curve inOutQuart  = Cubic(0.77, 0.0, 0.18, 1.0);  // Drawer, panel slide
```

---

## PHASE 0 — ENVIRONMENT SETUP

Create a `Dockerfile` and `docker-compose.yml` in the project root:

```dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

RUN apt-get update && apt-get install -y \
  curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk \
  wget ca-certificates clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev && \
  rm -rf /var/lib/apt/lists/*

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME \
  --depth 1 --branch stable
RUN flutter precache --android

# Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O /tmp/cmdline.zip && \
  unzip -q /tmp/cmdline.zip -d /tmp && \
  mv /tmp/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
  rm /tmp/cmdline.zip

RUN yes | sdkmanager --licenses && \
  sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

RUN flutter config --android-sdk $ANDROID_SDK_ROOT && \
  flutter config --no-analytics && \
  flutter doctor

WORKDIR /workspace
```

```yaml
# docker-compose.yml
services:
  flutter:
    build: .
    volumes:
      - .:/workspace
      - flutter_cache:/root/.pub-cache
    working_dir: /workspace
    command: sleep infinity
    environment:
      - FLUTTER_ROOT=/opt/flutter
volumes:
  flutter_cache:
```

Also create `.devcontainer/devcontainer.json`:
```json
{
  "name": "Pro Garage OS Flutter",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "flutter",
  "workspaceFolder": "/workspace",
  "extensions": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker"
  ],
  "settings": {
    "editor.formatOnSave": true,
    "dart.flutterSdkPath": "/opt/flutter"
  }
}
```

---

## PHASE 1 — PROJECT SCAFFOLD

Run these commands in sequence:

```bash
flutter create progarageos \
  --org in.akshara.progarageos \
  --project-name progarageos \
  --platforms android,ios \
  --template app

cd progarageos
```

Replace `pubspec.yaml` entirely with:

```yaml
name: progarageos
description: Pro Garage OS — Garage Operations SaaS
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.0

  # Network
  dio: ^5.4.3
  pretty_dio_logger: ^1.4.0

  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.3

  # Code generation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Realtime
  pusher_channels_flutter: ^2.1.0

  # Push notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.8.1

  # Design
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1

  # Camera & media
  image_picker: ^1.0.7
  camera: ^0.10.5+9
  path_provider: ^2.1.3

  # PDF & print
  pdf: ^3.10.8
  printing: ^5.12.0

  # Signature capture
  signature: ^5.4.1

  # Charts
  fl_chart: ^0.67.0

  # Calendar
  table_calendar: ^3.1.1

  # Utility
  intl: ^0.19.0
  connectivity_plus: ^6.0.1
  flutter_slidable: ^3.1.0
  shimmer: ^3.0.0
  url_launcher: ^6.3.0
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.7.6
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

Create directories:
```bash
mkdir -p assets/images assets/icons
mkdir -p lib/core/theme
mkdir -p lib/core/network
mkdir -p lib/core/router
mkdir -p lib/core/storage
mkdir -p lib/core/utils
mkdir -p lib/core/widgets
mkdir -p lib/features/auth/staff/screens
mkdir -p lib/features/auth/staff/providers
mkdir -p lib/features/auth/customer/screens
mkdir -p lib/features/auth/customer/providers
mkdir -p lib/features/dashboard/screens
mkdir -p lib/features/dashboard/providers
mkdir -p lib/features/dashboard/widgets
mkdir -p lib/features/jobs/screens
mkdir -p lib/features/jobs/providers
mkdir -p lib/features/jobs/widgets
mkdir -p lib/features/jobs/repositories
mkdir -p lib/features/inspection/screens
mkdir -p lib/features/inspection/providers
mkdir -p lib/features/inspection/widgets
mkdir -p lib/features/customers/screens
mkdir -p lib/features/customers/providers
mkdir -p lib/features/customers/widgets
mkdir -p lib/features/vehicles/screens
mkdir -p lib/features/vehicles/providers
mkdir -p lib/features/inventory/screens
mkdir -p lib/features/inventory/providers
mkdir -p lib/features/appointments/screens
mkdir -p lib/features/appointments/providers
mkdir -p lib/features/billing/screens
mkdir -p lib/features/billing/providers
mkdir -p lib/features/loyalty/screens
mkdir -p lib/features/loyalty/providers
mkdir -p lib/features/reports/screens
mkdir -p lib/features/reports/providers
mkdir -p lib/features/settings/screens
mkdir -p lib/features/notifications/providers
mkdir -p lib/shared/models
mkdir -p lib/shared/extensions
mkdir -p lib/shared/mixins

flutter pub get
```

**CHECKPOINT 1**: Run `flutter analyze` — must show zero errors before proceeding.

---

## PHASE 2 — CORE LAYER

Build every file in `lib/core/` completely. No stubs — full implementations.

### 2A — Design Tokens

Create `lib/core/theme/app_colors.dart` with the complete AppColors class from the design system above.

Create `lib/core/theme/app_typography.dart` with the complete AppTypography class.

Create `lib/core/theme/app_spacing.dart` with the complete AppSpacing class.

Create `lib/core/theme/app_motion.dart` with the complete AppMotion class.

Create `lib/core/theme/app_theme.dart`:
- `lightTheme` ThemeData using all token classes above
- ColorScheme: primary=sky600, onPrimary=white, surface=ink9, background=ink8, error=rose600
- TextTheme: all roles mapped to AppTypography styles
- CardTheme: white surface, 0.5px border (ink6), 16px radius, elevation 0
- InputDecorationTheme: 36px height, 10px radius, ink6 border, sky400 focus border + 3px glow
- ElevatedButtonTheme: 36px height, 10px radius, sky600 bg, DM Sans 500 weight
- OutlinedButtonTheme: 36px height, 10px radius, ink5 border
- BottomNavigationBarTheme: white bg, sky600 selected, ink4 unselected, no elevation line
- AppBarTheme: white bg, ink0 title, elevation 0, 0.5px bottom border ink7
- DividerTheme: ink7 color, 0.5px thickness

### 2B — Network Layer

Create `lib/core/network/api_endpoints.dart`:
```dart
class ApiEndpoints {
  static const String baseUrl = 'https://api.progarageos.in/v1';

  // Auth
  static const staffLogin         = '/auth/staff/login';
  static const staffLogout        = '/auth/staff/logout';
  static const staffPinChange     = '/auth/staff/pin/change';
  static const customerOtpRequest = '/auth/customer/otp/request';
  static const customerOtpVerify  = '/auth/customer/otp/verify';

  // Tenant
  static const tenantProfile        = '/tenant/profile';
  static const subscriptionPlans    = '/platform/subscription-plans';
  static const subscriptionUpgrade  = '/tenant/subscription/upgrade';

  // Users
  static const users                = '/users';
  static String user(String uuid)   => '/users/$uuid';
  static const skills               = '/skills';

  // Customers
  static const customers               = '/customers';
  static String customer(String uuid)  => '/customers/$uuid';
  static String customerLoyalty(String uuid) => '/customers/$uuid/loyalty';

  // Vehicles
  static String customerVehicles(String custUuid) => '/customers/$custUuid/vehicles';
  static String vehicle(String uuid)               => '/vehicles/$uuid';
  static String vehicleDocuments(String uuid)      => '/vehicles/$uuid/documents';
  static String vehicleMileageLogs(String uuid)    => '/vehicles/$uuid/mileage-logs';

  // Service Ops
  static const serviceCategories  = '/service-categories';
  static String serviceCategoryItems(String uuid) => '/service-categories/$uuid/items';
  static const serviceBays        = '/service-bays';
  static String serviceBayStatus(String uuid) => '/service-bays/$uuid/status';

  // Jobs
  static const jobs                        = '/jobs';
  static String job(String uuid)           => '/jobs/$uuid';
  static String jobStatus(String uuid)     => '/jobs/$uuid/status';
  static String jobTasks(String uuid)      => '/jobs/$uuid/tasks';
  static String jobTaskStatus(String jUuid, String tUuid) => '/jobs/$jUuid/tasks/$tUuid/status';
  static String jobEstimateSend(String uuid)    => '/jobs/$uuid/estimate/send';
  static String jobEstimateApprove(String uuid) => '/jobs/$uuid/estimate/approve';
  static String jobInspection(String uuid)      => '/jobs/$uuid/inspection';
  static String jobInspectionMedia(String uuid) => '/jobs/$uuid/inspection/upload-media';
  static String jobInvoice(String uuid)         => '/jobs/$uuid/invoice';
  static String jobFeedbackRequest(String uuid) => '/jobs/$uuid/feedback/request';

  // Inspection templates
  static const inspectionTemplates = '/inspection-templates';

  // Inventory
  static const inventory                        = '/inventory';
  static String inventoryItem(String uuid)      => '/inventory/$uuid';
  static String inventoryStockAdjust(String uuid) => '/inventory/$uuid/stock-adjust';
  static const vendors                          = '/vendors';
  static const purchaseOrders                   = '/purchase-orders';
  static String purchaseOrderReceive(String uuid) => '/purchase-orders/$uuid/receive';

  // Billing
  static String invoiceSend(String uuid)        => '/invoices/$uuid/send';
  static String invoicePayments(String uuid)    => '/invoices/$uuid/payments';
  static String invoiceGateway(String uuid)     => '/invoices/$uuid/payments/gateway/initiate';
  static const taxRates                         = '/tax-rates';
  static const paymentMethods                   = '/payment-methods';

  // Appointments
  static const appointments                     = '/appointments';
  static String appointmentCheckIn(String uuid) => '/appointments/$uuid/check-in';
  static const appointmentAvailability          = '/appointments/availability';

  // Notifications
  static const notificationTemplates = '/notification-templates';
  static const notifications         = '/notifications';

  // Loyalty
  static const loyaltyProgram = '/loyalty-program';

  // Feedback
  static String feedbackSubmit(String uuid)  => '/feedback/$uuid/submit';
  static String feedbackRespond(String uuid) => '/feedback/$uuid/respond';
  static const feedback = '/feedback';

  // Customer app
  static const customerProfile          = '/customer/profile';
  static const customerVehiclesSelf     = '/customer/vehicles';
  static const customerJobs             = '/customer/jobs';
  static String customerJobProgress(String uuid) => '/customer/jobs/$uuid/progress';
  static String customerTaskApprove(String jUuid, String tUuid) => '/customer/jobs/$jUuid/tasks/$tUuid/approve';
  static String customerServiceReminders(String uuid) => '/customer/vehicles/$uuid/service-reminders';
  static String customerServicePrefs(String uuid)     => '/customer/vehicles/$uuid/service-preferences';
  static String customerOdometerConfirm(String uuid)  => '/customer/vehicles/$uuid/odometer/confirm';
  static const customerSessionsRegister  = '/customer/sessions/register';
  static const customerEngagementTrack   = '/customer/engagement/track';
  static const customerAppointments      = '/customer/appointments';

  // Audit & Dashboard
  static const auditLogs         = '/audit-logs';
  static const dashboardSummary  = '/dashboard/summary';
}
```

Create `lib/core/network/dio_client.dart`:
- Single Dio instance as a Riverpod provider
- BaseOptions: baseUrl, connectTimeout 15s, receiveTimeout 30s
- Headers: Accept: application/json, Content-Type: application/json, X-App-Version: 1.0.0
- Interceptors chain: AuthInterceptor → LoggingInterceptor → ErrorInterceptor

Create `lib/core/network/auth_interceptor.dart`:
- On request: reads token from SecureStorage, injects `Authorization: Bearer {token}`
- On 401 response: clears token, redirects to login (via GoRouter ref)
- On 429 response: reads `Retry-After` header, waits, retries once

Create `lib/core/network/error_interceptor.dart`:
- Maps DioException types to ProGarageOSException with: code (string), message (user-friendly), statusCode
- Maps API error envelope `{ success: false, error: { code, message, details } }` to typed exception
- Never exposes raw Dio exceptions to UI layer

Create `lib/core/network/api_exception.dart`:
```dart
class ProGarageOSException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validationErrors;
  // All known codes from API spec error reference
}
```

### 2C — Storage Layer

Create `lib/core/storage/secure_storage.dart`:
```dart
class SecureStorage {
  static const _tokenKey     = 'auth_token';
  static const _userKey      = 'current_user';
  static const _tenantKey    = 'current_tenant';
  static const _roleKey      = 'user_roles';
  static const _flavorKey    = 'app_flavor';

  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveUser(String userJson);
  Future<String?> getUser();
  Future<void> clearAll();
  Future<bool> hasToken();
}
// Expose as Riverpod provider
```

### 2D — Router

Create `lib/core/router/app_router.dart` using GoRouter with:

**Staff routes** (`/staff/*`):
- `/staff/login` → StaffLoginScreen
- `/staff/dashboard` → DashboardScreen
- `/staff/jobs` → JobsListScreen
- `/staff/jobs/create` → JobCreateScreen
- `/staff/jobs/:uuid` → JobDetailScreen
- `/staff/jobs/:uuid/inspection` → InspectionScreen
- `/staff/jobs/:uuid/estimate` → EstimateScreen
- `/staff/customers` → CustomersListScreen
- `/staff/customers/:uuid` → CustomerDetailScreen
- `/staff/vehicles/:uuid` → VehicleDetailScreen
- `/staff/inventory` → InventoryListScreen
- `/staff/appointments` → AppointmentsScreen
- `/staff/billing/:invoiceUuid` → InvoiceScreen
- `/staff/reports` → ReportsScreen
- `/staff/settings` → SettingsScreen

**Customer routes** (`/customer/*`):
- `/customer/login` → CustomerPhoneScreen
- `/customer/otp` → CustomerOtpScreen
- `/customer/home` → CustomerHomeScreen
- `/customer/jobs` → CustomerJobsScreen
- `/customer/jobs/:uuid` → CustomerJobProgressScreen
- `/customer/vehicles` → CustomerVehiclesScreen
- `/customer/vehicles/:uuid` → CustomerVehicleDetailScreen
- `/customer/appointments` → CustomerAppointmentsScreen
- `/customer/loyalty` → CustomerLoyaltyScreen
- `/customer/profile` → CustomerProfileScreen

**Auth guard redirect**:
```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
  final isAuthRoute = state.matchedLocation.startsWith('/staff/login') 
                   || state.matchedLocation.startsWith('/customer/login');
  if (!isLoggedIn && !isAuthRoute) return '/staff/login'; // or /customer/login per flavor
  if (isLoggedIn && isAuthRoute) return '/staff/dashboard'; // or /customer/home
  return null;
}
```

**CHECKPOINT 2**: Run `flutter analyze` — zero errors, zero warnings.

---

## PHASE 3 — FREEZED MODELS

Generate complete Freezed models for every API entity. Each model must:
- Use `@freezed` annotation
- Have `fromJson` / `toJson` via `json_serializable`
- Match the exact field names from the API specification response payloads
- Use nullable fields where API shows NULLABLE
- Use proper Dart types: `DateTime` for timestamps, `double` for decimals, `int` for integers, `bool` for tinyints

Generate these models completely:

**Auth models** (`lib/shared/models/auth/`):
- `staff_user.dart` — StaffUser (uuid, firstName, lastName, email, phone, isPlatformAdmin, isSupportAgent, roles, permissions, lastLoginAt, tenant: TenantSummary)
- `tenant_summary.dart` — TenantSummary (uuid, businessName, status, currency, timezone)
- `customer_user.dart` — CustomerUser (uuid, firstName, lastName, phonePrimary, email, preferredLanguage, marketingOptIn, isPWaEnabled)
- `auth_token.dart` — AuthToken (token, tokenType, expiresAt)

**Tenant models** (`lib/shared/models/tenant/`):
- `tenant.dart` — Tenant (all fields from schema)
- `subscription_plan.dart` — SubscriptionPlan
- `tenant_subscription.dart` — TenantSubscription

**Customer models** (`lib/shared/models/customer/`):
- `customer.dart` — Customer (global identity fields + garageProfile: GarageProfile)
- `garage_profile.dart` — GarageProfile (internalNotes, loyaltyPoints, totalSpent, visitCount, lastVisitedAt, preferredTechnician)
- `customer_list_item.dart` — CustomerListItem (uuid, name, phonePrimary, garageProfile summary, vehiclesCount)

**Vehicle models** (`lib/shared/models/vehicle/`):
- `vehicle.dart` — Vehicle (all RC-compliant fields from schema, complianceAlerts: List<ComplianceAlert>)
- `compliance_alert.dart` — ComplianceAlert (type, status, expiry)
- `vehicle_document.dart` — VehicleDocument (uuid, documentType, documentNumber, issuingAuthority, issueDate, expiryDate, fileUrl, isVerified, status, daysToExpiry)
- `mileage_log.dart` — MileageLog (uuid, recordedAt, odometerValueKm, previousValueKm, gpsDeltaKm, source, reviewStatus)

**Job models** (`lib/shared/models/job/`):
- `service_job.dart` — ServiceJob (all fields from schema including nested customer, vehicle, tasks summary, timeline)
- `service_job_list_item.dart` — ServiceJobListItem (for list view)
- `job_task.dart` — JobTask (uuid, name, source, status, assignedTechnician, estimatedPrice, finalPrice, laborMinutes, isBillable, requiresCustomerApproval, liabilityFlag, description)
- `job_status.dart` — enum JobStatus with all values
- `task_status.dart` — enum TaskStatus with all values
- `inspection_record.dart` — InspectionRecord (uuid, templateUuid, componentName, componentCategory, conditionStatus, severity, notes, mediaUrls, inspectedBy, customerAcknowledged)
- `inspection_template.dart` — InspectionTemplate

**Service models** (`lib/shared/models/service/`):
- `service_category.dart` — ServiceCategory
- `service_item.dart` — ServiceItem
- `service_bay.dart` — ServiceBay (with currentJob: JobSummary?)

**Inventory models** (`lib/shared/models/inventory/`):
- `inventory_item.dart` — InventoryItem
- `vendor.dart` — Vendor
- `purchase_order.dart` — PurchaseOrder
- `purchase_order_item.dart` — PurchaseOrderItem

**Billing models** (`lib/shared/models/billing/`):
- `invoice.dart` — Invoice (with items: List<InvoiceItem>)
- `invoice_item.dart` — InvoiceItem (lineType, name, quantity, unitPrice, taxAmount, discountAmount, totalAmount, isTaxable)
- `payment.dart` — Payment
- `payment_method.dart` — PaymentMethod
- `tax_rate.dart` — TaxRate (with componentBreakdown: Map<String,double>?)

**Scheduling models** (`lib/shared/models/scheduling/`):
- `appointment.dart` — Appointment
- `available_slot.dart` — AvailableSlot

**Loyalty models** (`lib/shared/models/loyalty/`):
- `loyalty_program.dart` — LoyaltyProgram
- `loyalty_balance.dart` — LoyaltyBalance (currentBalance, lifetimeEarned, lifetimeRedeemed, expiringSoon, transactions)
- `loyalty_transaction.dart` — LoyaltyTransaction

**Notification models** (`lib/shared/models/notification/`):
- `notification_template.dart` — NotificationTemplate
- `notification_log.dart` — NotificationLog

**Dashboard models** (`lib/shared/models/dashboard/`):
- `dashboard_summary.dart` — DashboardSummary (period, jobs, revenue, customers, technicians, inventory)

After generating all models, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**CHECKPOINT 3**: `flutter analyze` — zero errors. All generated `.g.dart` and `.freezed.dart` files exist.

---

## PHASE 4 — REPOSITORIES

Create one repository per feature domain. Each repository:
- Takes Dio as constructor parameter (injected via Riverpod)
- Returns typed model results, never raw Maps
- Handles pagination via PaginatedResult<T> wrapper
- Throws ProGarageOSException on error (never raw DioException)

```dart
// lib/shared/models/paginated_result.dart
@freezed
class PaginatedResult<T> with _$PaginatedResult<T> {
  const factory PaginatedResult({
    required List<T> data,
    required int currentPage,
    required int perPage,
    required int total,
    required int lastPage,
  }) = _PaginatedResult<T>;
}
```

Create these repositories with full method implementations:

`lib/features/auth/repositories/auth_repository.dart`:
- `loginStaff(String login, String pin) → Future<(AuthToken, StaffUser)>`
- `logoutStaff() → Future<void>`
- `requestOtp(String phone) → Future<OtpRequestResult>`
- `verifyOtp(String phone, String otp, String deviceToken, String platform) → Future<(AuthToken, CustomerUser)>`
- `changePin(String currentPin, String newPin) → Future<void>`

`lib/features/jobs/repositories/job_repository.dart`:
- `listJobs({String? status, String? priority, String? technicianUuid, DateTime? dateFrom, DateTime? dateTo, int page}) → Future<PaginatedResult<ServiceJobListItem>>`
- `getJob(String uuid) → Future<ServiceJob>`
- `createJob(CreateJobRequest request) → Future<ServiceJob>`
- `updateJobStatus(String uuid, String status, String? notes) → Future<ServiceJob>`
- `addTask(String jobUuid, CreateTaskRequest request) → Future<JobTask>`
- `updateTaskStatus(String jobUuid, String taskUuid, String status) → Future<JobTask>`
- `sendEstimate(String uuid, String channel, String? notes) → Future<EstimateSentResult>`
- `approveEstimate(String uuid, List<String> approvedTaskUuids, String? signatureBase64) → Future<void>`
- `getInspection(String jobUuid) → Future<InspectionResult>`
- `submitInspection(String jobUuid, SubmitInspectionRequest request) → Future<void>`
- `uploadInspectionMedia(String jobUuid, String phase, String componentCode, File file) → Future<String>`
- `getInvoice(String jobUuid) → Future<Invoice>`
- `createInvoice(String jobUuid, CreateInvoiceRequest request) → Future<Invoice>`
- `sendInvoice(String invoiceUuid, String channel) → Future<void>`
- `recordPayment(String invoiceUuid, RecordPaymentRequest request) → Future<Payment>`

`lib/features/customers/repositories/customer_repository.dart`:
- `listCustomers({String? search, int page}) → Future<PaginatedResult<CustomerListItem>>`
- `getCustomer(String uuid) → Future<Customer>`
- `createCustomer(CreateCustomerRequest request) → Future<Customer>`
- `updateCustomer(String uuid, UpdateCustomerRequest request) → Future<Customer>`

`lib/features/vehicles/repositories/vehicle_repository.dart`:
- `listVehicles(String customerUuid) → Future<List<Vehicle>>`
- `addVehicle(String customerUuid, CreateVehicleRequest request) → Future<Vehicle>`
- `updateVehicle(String uuid, UpdateVehicleRequest request) → Future<Vehicle>`
- `listDocuments(String vehicleUuid) → Future<List<VehicleDocument>>`
- `uploadDocument(String vehicleUuid, UploadDocumentRequest request, File file) → Future<VehicleDocument>`
- `listMileageLogs(String vehicleUuid) → Future<List<MileageLog>>`
- `addMileageLog(String vehicleUuid, int odometerValueKm, String source) → Future<MileageLog>`

`lib/features/inventory/repositories/inventory_repository.dart`:
- `listItems({bool? lowStock, String? search, int page}) → Future<PaginatedResult<InventoryItem>>`
- `addItem(CreateInventoryItemRequest request) → Future<InventoryItem>`
- `adjustStock(String uuid, String adjustmentType, int quantity, String reason) → Future<InventoryItem>`
- `listVendors() → Future<List<Vendor>>`
- `createPurchaseOrder(CreatePurchaseOrderRequest request) → Future<PurchaseOrder>`
- `receivePurchaseOrder(String uuid, List<PurchaseOrderReceiveItem> items) → Future<PurchaseOrder>`

`lib/features/appointments/repositories/appointment_repository.dart`:
- `listAppointments({String? date, String? status, int page}) → Future<PaginatedResult<Appointment>>`
- `bookAppointment(CreateAppointmentRequest request) → Future<Appointment>`
- `checkIn(String uuid, int odometerAtIntake, String fuelLevel) → Future<CheckInResult>`
- `getAvailability(String date, String? bayUuid, int durationMinutes) → Future<List<AvailableSlot>>`

`lib/features/dashboard/repositories/dashboard_repository.dart`:
- `getSummary(String period) → Future<DashboardSummary>`
- `listServiceBays() → Future<List<ServiceBay>>`

`lib/features/loyalty/repositories/loyalty_repository.dart`:
- `getProgram() → Future<LoyaltyProgram>`
- `updateProgram(UpdateLoyaltyProgramRequest request) → Future<LoyaltyProgram>`
- `getCustomerBalance(String customerUuid) → Future<LoyaltyBalance>`
- `adjustPoints(String customerUuid, AdjustPointsRequest request) → Future<LoyaltyTransaction>`

**CHECKPOINT 4**: `flutter analyze` — zero errors.

---

## PHASE 5 — RIVERPOD PROVIDERS

Create providers for every feature. Use `@riverpod` annotation with code generation.

### Auth Providers (`lib/features/auth/providers/`)

`auth_provider.dart`:
```dart
// AuthState holds: isAuthenticated, currentUser (StaffUser?), customerUser (CustomerUser?), roles
@riverpod
class AuthNotifier extends _$AuthNotifier {
  // Initializes from SecureStorage on app start
  // staffLogin(login, pin): calls repo, saves token + user, updates state
  // customerLogin(phone, otp, deviceToken): calls repo, saves token + user
  // logout(): clears storage, resets state
  // hasPermission(String permission): checks roles[]
  // isOwner: bool getter (roles contains 'owner')
  // isTechnician: bool getter
}
```

`staff_login_provider.dart`:
```dart
@riverpod
class StaffLoginNotifier extends _$StaffLoginNotifier {
  // State: StaffLoginState { idle, loading, error(String), success }
  // login(String login, String pin)
  // pinDigits: tracks 6 digit entries
  // addDigit(int digit), removeDigit(), clearPin()
  // failCount: tracks failed attempts
  // lockoutTimer: CountdownTimer when locked
}
```

`customer_auth_provider.dart`:
```dart
@riverpod
class CustomerAuthNotifier extends _$CustomerAuthNotifier {
  // State: CustomerAuthState { idle, otpSent, verifying, error, success }
  // requestOtp(String phone)
  // verifyOtp(String otp)
  // resendOtp()
  // otpExpiresAt: DateTime for countdown
  // maskedPhone: String
}
```

### Job Providers (`lib/features/jobs/providers/`)

`jobs_list_provider.dart`:
```dart
@riverpod
class JobsListNotifier extends _$JobsListNotifier {
  // Paginated job list with infinite scroll
  // Filters: status, priority, technicianUuid, dateRange
  // loadMore(), refresh(), applyFilter(JobFilter)
  // Handles WebSocket job.status.updated: surgically updates the matching job in list
}
```

`job_detail_provider.dart`:
```dart
@riverpod
class JobDetailNotifier extends _$JobDetailNotifier {
  // Takes jobUuid as argument
  // Loads full job detail
  // updateStatus(String status, String? notes)
  // addTask(CreateTaskRequest)
  // updateTaskStatus(String taskUuid, String status)
  // Realtime: listens to private-tenant channel for this job's events
}
```

`job_create_provider.dart`:
```dart
@riverpod
class JobCreateNotifier extends _$JobCreateNotifier {
  // Multi-step form state
  // step: 1=customer+vehicle, 2=service categories, 3=assignment+scheduling
  // selectedCustomer, selectedVehicle, selectedCategories, primaryTechUuid, bayUuid
  // nextStep(), prevStep(), submit()
  // customerSearch(String query): debounced, returns List<CustomerListItem>
}
```

`inspection_provider.dart`:
```dart
@riverpod
class InspectionNotifier extends _$InspectionNotifier {
  // Takes jobUuid, phase (intake|delivery)
  // inspectionRecords: Map<templateUuid, InspectionRecord>
  // updateRecord(templateUuid, conditionStatus, severity, notes)
  // addPhoto(templateUuid, File photo): uploads + updates mediaUrls
  // signatureBytes: Uint8List?
  // captureSignature(Uint8List bytes)
  // submit(): calls repo, advances job status
}
```

`estimate_provider.dart`:
```dart
@riverpod
class EstimateNotifier extends _$EstimateNotifier {
  // Takes jobUuid
  // tasks: List<JobTask>
  // editTaskPrice(taskUuid, double price)
  // toggleTaskBillable(taskUuid)
  // totalEstimate: double computed
  // sendEstimate(String channel)
}
```

### Dashboard Providers (`lib/features/dashboard/providers/`)

`dashboard_provider.dart`:
```dart
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  // period: 'today' | 'this_week' | 'this_month'
  // summary: DashboardSummary
  // bays: List<ServiceBay>
  // recentActivity: List<AuditLog>
  // Subscribes to private-tenant.{uuid} WebSocket
  // On job.status.updated: increment/decrement job counters, update bay
  // On payment.received: add revenue delta, flash state
  // On inventory.low_stock: increment lowStock counter
  // refreshSummary(), setPeriod(String period)
}
```

### Realtime Provider (`lib/features/notifications/providers/`)

`realtime_provider.dart`:
```dart
@riverpod
class RealtimeNotifier extends _$RealtimeNotifier {
  // Manages Pusher connection lifecycle
  // connectStaff(String tenantUuid): subscribes to private-tenant.{uuid}
  // connectCustomer(String customerUuid): subscribes to private-customer.{uuid}
  // disconnect()
  // eventStream: Stream<RealtimeEvent> that other providers listen to
  // RealtimeEvent: union type for all WebSocket events from spec
}
```

**CHECKPOINT 5**: `dart run build_runner build --delete-conflicting-outputs` then `flutter analyze` — zero errors.

---

## PHASE 6 — SHARED WIDGETS

Build the complete shared widget library. Every widget uses only AppColors, AppTypography, AppSpacing tokens.

### `lib/core/widgets/gf_button.dart`
```
GfButton widget with:
- variant: primary | secondary | ghost | danger | destructive
- size: sm (28px) | md (36px) | lg (44px)
- leading: Widget? (icon before label)
- trailing: Widget? (icon after label)
- isLoading: bool (shows CircularProgressIndicator, disables tap)
- onPressed: VoidCallback?
- Full width option

Press animation: scale to 0.97 in 80ms ease-in, release 140ms spring curve
```

### `lib/core/widgets/gf_badge.dart`
```
GfBadge widget with:
- label: String
- variant: info | success | warning | danger | neutral | teal | violet
- showDot: bool (default true)
- size: sm | md
Each variant maps to AppColors semantic pair (background + foreground + dot)
Pill shape, pill border-radius
```

### `lib/core/widgets/gf_card.dart`
```
GfCard widget with:
- child: Widget
- padding: EdgeInsets? (defaults to AppSpacing.cardPadding)
- onTap: VoidCallback? (adds InkWell + hover lift animation)
- hasBorder: bool (default true, 0.5px AppColors.ink6)
Hover lift: translateY -2px + shadow-md in 240ms feather curve
```

### `lib/core/widgets/gf_input.dart`
```
GfInput widget with:
- label: String?
- hint: String?
- helpText: String?
- errorText: String?
- prefix: Widget?
- suffix: Widget?
- isMonospace: bool (switches to DM Mono)
- controller, focusNode, keyboardType, inputFormatters, onChanged, onSubmitted
36px height, 10px radius, 0.5px border ink6, sky focus ring 3px
```

### `lib/core/widgets/status_badge.dart`
```
StatusBadge widget:
- status: String (job status string from API)
- Uses AppColors.statusBackground/Foreground/Dot mapping
- Auto-picks correct colors from status
```

### `lib/core/widgets/skeleton_loader.dart`
```
SkeletonLoader widget with:
- width, height, borderRadius
- Shimmer animation using shimmer package
- AppColors.ink7 base, ink6 highlight
```

### `lib/core/widgets/empty_state.dart`
```
EmptyState widget:
- icon: IconData
- title: String
- description: String
- action: GfButton? (optional CTA)
- Centered layout, ink8 background, ink-scale typography
```

### `lib/core/widgets/error_state.dart`
```
ErrorState widget:
- error: ProGarageOSException
- onRetry: VoidCallback
- Shows user-friendly message from exception, retry button
```

### `lib/core/widgets/gf_app_bar.dart`
```
GfAppBar widget implementing PreferredSizeWidget:
- title: String
- subtitle: String? (smaller text below title)
- actions: List<Widget>?
- leading: Widget?
- showBack: bool
- bottomBorderColor: AppColors.ink7 (0.5px)
No elevation, white background, ink0 title text
```

### `lib/core/widgets/amount_text.dart`
```
AmountText widget:
- amount: double
- currency: String (default 'INR')
- style: TextStyle?
- showSymbol: bool
Formats using Intl with Indian number format (₹1,00,000.00)
Uses AppTypography.mono
```

### `lib/core/widgets/job_card_tile.dart`
```
JobCardTile widget showing a job in list:
- job: ServiceJobListItem
- onTap: VoidCallback
- onSwipeRight: VoidCallback? (check in action)
- onSwipeLeft: VoidCallback? (hold action)
Layout: job number (DM Mono) + vehicle + customer + status badge + tech initials + thin progress bar at bottom
Hover lift animation
Uses flutter_slidable for swipe actions
```

### `lib/core/widgets/initials_avatar.dart`
```
InitialsAvatar widget:
- name: String (derives initials from first + last word)
- size: double (default 36)
- backgroundColor: Color (default teal50)
- foregroundColor: Color (default teal600)
Circular, DM Sans 500 weight text
```

### `lib/core/widgets/section_header.dart`
```
SectionHeader widget:
- title: String (11px uppercase, ink4, letter-spacing 0.08em)
- action: Widget? (right-aligned, sky600 link style)
- padding: EdgeInsets
```

### `lib/core/widgets/info_row.dart`
```
InfoRow widget:
- label: String (ink4, 12px)
- value: String (ink1, 13px)
- valueStyle: TextStyle? (override for mono, color)
- icon: IconData?
Row layout, subtle divider below
```

**CHECKPOINT 6**: `flutter analyze` — zero errors.

---

## PHASE 7 — STAFF AUTH SCREENS

### `lib/features/auth/staff/screens/staff_login_screen.dart`

Full implementation:
- Dark Slate-900 full screen background
- Dot pattern overlay (custom painter, 60px grid, white 2.5% opacity)
- Center column, max 320px wide
- "Pro Garage OS Staff" wordmark: DM Sans 28px weight 300, white
- Saved garage name from SharedPreferences (if returning user)
- Email/phone text field: white surface 44px, ink2 text, 10px radius
- 6-dot PIN indicator row: unfilled circle → filled sky400 circle per digit
- 3×4 circular PIN pad (64px buttons): digits 1-9, biometric icon, 0, delete
- Button tap animation: scale 0.94 in 80ms
- Error: all dots flash rose400, horizontal shake animation (3 oscillations, 300ms total)
- Locked state: PIN pad hidden, countdown timer shown
- Loading: dots animate as subtle wave
- LocalAuthentication for biometric (if available + enabled)
- "Forgot PIN?" → shows snackbar with email reset instruction

Uses `StaffLoginNotifier` provider. On success → GoRouter to `/staff/dashboard`.

### `lib/features/auth/customer/screens/customer_phone_screen.dart`

Full implementation:
- White background, centered layout
- Pro Garage OS logo text: DM Sans 28px weight 300, ink0
- "Welcome back" heading + subtitle in ink4
- +91 prefix chip (teal50 background) + phone number field (DM Mono)
- "Send OTP" primary button (full width, 44px, 16px radius)
- Terms caption below (10px ink5)
- Entrance animation: each element translateY 20→0 + opacity, staggered 40ms

### `lib/features/auth/customer/screens/customer_otp_screen.dart`

Full implementation:
- Back button + "Verify OTP" heading
- Masked phone display + "Change" link in sky600
- 6 individual OTP input boxes in a row (48×56px each, 10px radius)
  - Auto-advance on digit entry
  - Auto-backspace on delete
  - Active: sky border + 3px glow
  - Filled: ink8 background, ink0 text
  - Error: rose border, shake animation
- Countdown timer → "Resend OTP" link when expired
- Auto-submit when 6th digit entered
- Skeleton loader while verifying

**CHECKPOINT 7**: Both auth screens render without errors. Run on emulator/device to verify.

---

## PHASE 8 — STAFF APP SHELL + DASHBOARD

### `lib/features/dashboard/screens/dashboard_screen.dart`

This is the home screen for staff after login. Full implementation:

**App bar**: "Good morning, {firstName}" with today's date. Notification bell icon (badge dot if unread). Owner initials avatar.

**Period selector**: Horizontal chip row — Today / This Week / This Month. Tapping updates DashboardSummary.

**KPI Cards** (horizontal scroll, snapping):
- "Today's Jobs" — count from summary.jobs.total
- "Revenue MTD" — ₹ amount in DM Mono weight 300 using AmountText
- "Pending Approval" — count, amber colored if > 0
- "Low Stock Items" — count, rose colored if > 0
Each card: 130px wide, 90px tall, 12px radius, 0.5px border, shadow-sm
WebSocket update → value animates with brief sky400 flash (opacity 0→1→0, 400ms)

**Bay Status Grid** (2-column):
Each bay card: bay name + type icon + status chip + current job info if occupied + time progress bar
Status colors: available=sage, occupied=sky, maintenance=amber, reserved=slate
Tap → navigate to job detail if occupied

**Active Jobs Section**:
SectionHeader("Active Jobs") + "View all" link → `/staff/jobs`
First 5 in_progress or estimate_pending jobs using JobCardTile
flutter_slidable: right=Check In (sky), left=Hold (amber)

**Recent Activity**:
Last 5 events from audit log
Colored dot + description + relative time
Animation: slideIn 380ms feather when new event arrives via WebSocket

**Empty states** for each section using EmptyState widget.

**Real-time wiring**:
```dart
// In initState / build:
ref.listen(realtimeProvider, (_, event) {
  if (event is JobStatusUpdatedEvent) {
    ref.read(dashboardProvider.notifier).handleJobStatusUpdate(event);
  }
  if (event is PaymentReceivedEvent) {
    ref.read(dashboardProvider.notifier).handlePaymentReceived(event);
  }
  // etc.
});
```

**CHECKPOINT 8**: Dashboard renders with skeleton loading → real data. WebSocket events update UI without full reload.

---

## PHASE 9 — JOB MANAGEMENT SCREENS

### `lib/features/jobs/screens/jobs_list_screen.dart`

- Search bar at top (debounced 300ms)
- Horizontal status filter chips (All, In Progress, Pending Approval, Ready, Delivered)
- Infinite scroll list of JobCardTile widgets
- FAB: "+" → `/staff/jobs/create`
- Pull to refresh
- flutter_slidable on each row
- Empty state: "No jobs match your filters"
- Loading: 5 SkeletonLoader items matching JobCardTile height

### `lib/features/jobs/screens/job_create_screen.dart`

Multi-step bottom sheet (full screen modal):

**Step 1 — Customer & Vehicle**:
- Search field: debounced GET /customers?search=
- Results list: InitialsAvatar + name + phone + vehicle count chip
- "New Customer" row at bottom → inline mini-form (name + phone)
- After customer selected: show their vehicles as chips
- "Add New Vehicle" chip → vehicle quick-add form (registration + make + model + year + odometer)

**Step 2 — Service Categories**:
- Multi-select grid of ServiceCategory cards
- Each card: category name + duration + workflow flags (inspection required? approval required?)
- Primary category selector (radio among selected)
- Fuel level picker: Empty / Quarter / Half / Three-Quarter / Full
- Odometer field (DM Mono, int)
- Special instructions text area

**Step 3 — Assignment & Scheduling**:
- Bay selector: horizontal scroll of ServiceBay cards with availability status
- Technician selector: list of staff with skill match indicator (green check if has primary skill for selected category)
- Date/time pickers: scheduled_start_at, estimated_completion_at
- Priority selector: Low / Normal / Urgent / Critical (colored chips)
- Handover notes field

**Step indicator**: 3 pills at top showing current step
**Back / Next / Create buttons**: full-width primary at bottom

### `lib/features/jobs/screens/job_detail_screen.dart`

Full scrollable screen with sticky header:

**Header** (SliverAppBar, Slate-900 background, collapses on scroll):
- Job number (DM Mono white), vehicle registration (white), status badge
- Customer name + phone (tappable) + technician initials
- Thin sky→teal progress bar at very bottom of header

**Body sections** (CustomScrollView with SliverList):

1. **Service Categories**: horizontal chip row

2. **Tasks Section** (SectionHeader + task list):
   Each task row:
   - Leading status icon (✓ sage / ▷ sky / ⏳ amber / — gray)
   - Task name 13px ink1 + source badge (discovered/planned/upsell)
   - Assigned tech initials (right)
   - Estimated price in DM Mono (right)
   - Expand arrow → shows description + liability flag + final price edit
   - Swipe left: "Cancel Task" (rose)
   - Tap on "pending_approval" task → task approval bottom sheet
   "Add Task" ghost button at bottom of task list

3. **Inspection Summary Card**:
   - Intake: completed/pending with component count
   - Delivery: completed/pending
   - Damage flags count (rose badge if > 0)
   - "Start Inspection" primary button → `/staff/jobs/:uuid/inspection`

4. **Billing Summary Card**:
   - Estimated amount, approval status, customer approved at
   - Invoice status + balance due
   - "Generate Invoice" / "Send Invoice" / "Record Payment" buttons (role-gated)

5. **Status Action Bar** (sticky bottom, white):
   - Shows valid next status transition as primary button
   - e.g., if status=estimate_pending → "Send Estimate" button
   - e.g., if status=in_progress → "Mark QC Done" button

### `lib/features/inspection/screens/inspection_screen.dart`

- Phase tabs: Intake | Delivery
- Each template item as an expandable card:
  - Component name + category chip
  - Condition status selector: OK / Minor Scratch / Major Damage / Missing / Other
  - Severity selector (if not OK): Low / Medium / High / Critical
  - Notes text field
  - Camera button → opens camera, captures photo, uploads to inspection media endpoint, shows thumbnail
  - "Requires photo" indicator if template.requiresPhoto
- Signature capture card at bottom (using signature package)
- Customer acknowledged toggle
- "Submit Inspection" primary button
- Progress indicator: X of Y items completed
- Damage auto-comparison on delivery phase (flags items not present in intake)

**CHECKPOINT 9**: Job list, job detail, create flow, inspection screen all functional. Test create → inspect → estimate → in_progress flow end to end.

---

## PHASE 10 — CUSTOMER MANAGEMENT

### `lib/features/customers/screens/customers_list_screen.dart`
- Search with debounce
- Sort by: last visited, total spent, visit count
- Filter: has vehicle / no vehicle
- CustomerCard showing: avatar, name, phone, loyalty points chip, visit count, last visited, vehicle count

### `lib/features/customers/screens/customer_detail_screen.dart`
- Customer header: avatar, name, phone, email, WhatsApp toggle
- Garage profile section: loyalty points (violet), total spent, visit count, preferred tech
- Vehicles list with compliance alert badges
- Recent jobs list (last 5) with status and amount
- Internal notes (editable for staff)
- Action buttons: New Job, Edit, WhatsApp message

---

## PHASE 11 — INVENTORY SCREEN

### `lib/features/inventory/screens/inventory_list_screen.dart`
- Search + category filter chips
- "Low Stock Only" toggle chip (rose badge on chip if any)
- InventoryItem cards: SKU (DM Mono), name, brand, stock on hand, threshold, status chip
  - Low stock: amber badge
  - Out of stock: rose badge
- Swipe right: "Adjust Stock" → stock adjustment bottom sheet
  - Adjustment type: Addition / Reduction / Correction
  - Quantity field, reason field, reference field
  - Confirms → calls stock-adjust endpoint
- FAB: "+" → Add Item form
- Pull to refresh

---

## PHASE 12 — APPOINTMENTS SCREEN

### `lib/features/appointments/screens/appointments_screen.dart`
- TableCalendar at top (compact mode, shows dot markers on days with appointments)
- Selected day → list of appointments below
- AppointmentCard: customer name, vehicle, service category, time slot, status badge, tech assigned
- "Check In" button on booked/confirmed appointments → shows odometer + fuel level sheet → creates job
- FAB: "+" → Book Appointment form
  - Customer search + select
  - Vehicle select (from customer's vehicles)
  - Service category
  - Date picker → loads available slots → slot selector grid
  - Tech/bay (optional pre-assign)

---

## PHASE 13 — BILLING SCREEN

### `lib/features/billing/screens/invoice_screen.dart`
Full invoice view:
- Garage header (name + address placeholder + logo placeholder)
- Invoice number (DM Mono) + status badge + dates
- Customer + vehicle block
- Line items table: scrollable, alternating ink8/ink9 rows, right-aligned amounts in DM Mono
  - Line types: service, part, labor, manual, discount, tax
- Totals block: subtotal, CGST, SGST, discount, grand total (sky600, larger)
- Balance due (rose600 if unpaid)
- Loyalty points redeemed (violet chip if any)
- QR code display (if qrCodeUrl available via CachedNetworkImage)
- Action row: Share (WhatsApp / PDF), Print, Record Payment
- Payment recording bottom sheet: method selector (from payment methods list), amount, reference, paid_at

---

## PHASE 14 — REPORTS SCREEN (OWNER ONLY)

### `lib/features/reports/screens/reports_screen.dart`
Show only if user has 'owner' role (check via authProvider.isOwner).

- Period selector (tabs: Today / Week / Month / Custom date range)
- Revenue chart: fl_chart LineChart, sky400 line, ink8 grid, DM Mono axis labels
- Jobs breakdown: BarChart, grouped by status, using status colors
- Top technician card: initials + name + jobs completed + avg rating + on-time rate
- Low stock table: SKU / name / stock / threshold / reorder qty
- Outstanding invoices: customer / amount / overdue days

---

## PHASE 15 — SETTINGS SCREENS (OWNER ONLY)

### `lib/features/settings/screens/settings_screen.dart`
Grouped settings list:
- Garage Profile (business name, timezone, currency)
- Loyalty Program → loyalty_config_screen.dart
- Notification Templates → template_list_screen.dart
- Staff Management → staff_management_screen.dart
- Service Categories → category_management_screen.dart
- Payment Methods → payment_methods_screen.dart
- Tax Rates → tax_rates_screen.dart

Each settings group: SectionHeader + ListTile cards with trailing arrow

### `lib/features/settings/screens/loyalty_config_screen.dart`
- Program name field
- Earning mode selector (spend-based / visit-based)
- Points per ₹ amount slider
- Minimum spend threshold
- Redemption rate + minimum points + max discount %
- Expiry days
- Active toggle
- Save button → PUT /loyalty-program

### `lib/features/settings/screens/staff_management_screen.dart`
- List of staff with role chips, last login, active toggle
- Add Staff FAB → form (name, email, phone, PIN, roles, skills)
- Tap → edit staff detail, view performance summary (jobs completed, rating)

---

## PHASE 16 — CUSTOMER APP SCREENS

### `lib/features/customer_home/screens/customer_home_screen.dart`
Bottom nav with 5 tabs.

**Home tab**:
- If active job: large JobProgressCard (vehicle registration, status, eta, technician, task progress %)
- Service reminders: cards per vehicle showing due in X km / X days
- Recent appointment chips
- Empty: "No active service right now" with book appointment CTA

**My Cars tab**:
- Vehicle list: registration + make+model + year + compliance alert badges
- Tap → vehicle detail: full specs, compliance docs, mileage history, service history

**Jobs tab**:
- Job history list across all garages
- Job number (DM Mono), garage name, vehicle, status badge, amount, date
- Tap → job progress detail

**Appointments tab**:
- Upcoming and past appointments
- Book New Appointment button → garage selector → category → slot picker

**Profile tab**:
- Customer info display + edit
- Loyalty balance (violet card, points + progress to next tier)
- Notification preferences (WhatsApp toggle, push toggle, channel selector per vehicle)
- Preferred language selector

### `lib/features/jobs/screens/customer_job_progress_screen.dart`
(Full implementation from Phase 9 description above — the customer-facing version)
- Vehicle header (Slate-900)
- Garage info + technician row
- Task timeline with pending approval cards
- Digital signature sheet for approval
- Sticky approval CTA bar
- WebSocket realtime updates

---

## PHASE 17 — REALTIME WIRING

### `lib/features/notifications/providers/realtime_provider.dart`

Complete Pusher implementation:
```dart
@riverpod
class RealtimeNotifier extends _$RealtimeNotifier {
  PusherChannelsFlutter? _pusher;
  
  Future<void> connectStaff(String tenantUuid, String authToken) async {
    _pusher = PusherChannelsFlutter.getInstance();
    await _pusher!.init(
      apiKey: const String.fromEnvironment('PUSHER_KEY'),
      cluster: const String.fromEnvironment('PUSHER_CLUSTER'),
      authEndpoint: '${ApiEndpoints.baseUrl}/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        // Inject auth token for private channel subscription
        final response = await dio.post('/broadcasting/auth', data: {
          'socket_id': socketId,
          'channel_name': channelName,
        });
        return response.data;
      },
    );
    
    final channel = await _pusher!.subscribe(
      channelName: 'private-tenant.$tenantUuid',
      onEvent: (event) => _handleStaffEvent(event),
    );
  }
  
  void _handleStaffEvent(PusherEvent event) {
    final payload = jsonDecode(event.data ?? '{}');
    final realtimeEvent = switch (event.eventName) {
      'job.status.updated'  => JobStatusUpdatedEvent.fromJson(payload),
      'job.task.added'      => JobTaskAddedEvent.fromJson(payload),
      'inventory.low_stock' => InventoryLowStockEvent.fromJson(payload),
      'appointment.booked'  => AppointmentBookedEvent.fromJson(payload),
      'payment.received'    => PaymentReceivedEvent.fromJson(payload),
      _                     => UnknownEvent(event.eventName),
    };
    state = state.copyWith(lastEvent: realtimeEvent);
  }
  
  Future<void> connectCustomer(String customerUuid, String authToken) async {
    // Same pattern, private-customer.{uuid} channel
    // Events: job.status.updated, job.task.approval_required, 
    //         job.ready_for_pickup, odometer.confirmation_needed,
    //         service.reminder, appointment.confirmed
  }
  
  @override
  void dispose() {
    _pusher?.disconnect();
    super.dispose();
  }
}
```

Wire all screens to listen to realtime events via `ref.listen(realtimeProvider, ...)`.

### FCM Push Notifications

`lib/core/notifications/fcm_handler.dart`:
- `FirebaseMessaging.onBackgroundMessage` handler
- Notification tap routing via GoRouter
- Token registration on login → POST /customer/sessions/register
- Topic subscription for staff: `tenant_{tenantUuid}`

**CHECKPOINT 17**: Test WebSocket connection. Simulate a job status change from Postman hitting `PUT /jobs/{uuid}/status` → verify Flutter UI updates without reload.

---

## PHASE 18 — FLAVOR CONFIGURATION

Configure Android flavors:

In `android/app/build.gradle`, add:
```groovy
flavorDimensions "app"
productFlavors {
    customer {
        dimension "app"
        applicationId "in.akshara.progarageos.customer"
        resValue "string", "app_name", "Pro Garage OS"
    }
    staff {
        dimension "app"  
        applicationId "in.akshara.progarageos.staff"
        resValue "string", "app_name", "Pro Garage OS Staff"
    }
}
```

Create entry points:
- `lib/main_customer.dart` → `runApp(CustomerApp())`
- `lib/main_staff.dart` → `runApp(StaffApp())`

`lib/app_staff.dart`:
- ProviderScope wrapper
- MaterialApp.router with staffRouter
- Theme: staffTheme (identical token base, Slate-900 sidebar)
- FCM initialization for staff

`lib/app_customer.dart`:
- ProviderScope wrapper
- MaterialApp.router with customerRouter
- Theme: customerTheme (white-first, feather animations)
- FCM initialization for customer

Build commands:
```bash
# Development
flutter run --flavor staff -t lib/main_staff.dart
flutter run --flavor customer -t lib/main_customer.dart

# Release APK
flutter build apk --flavor staff -t lib/main_staff.dart --release
flutter build apk --flavor customer -t lib/main_customer.dart --release
```

---

## PHASE 19 — FINAL QA CHECKLIST

Run each item. Fix any failures before marking complete.

```bash
# Static analysis — zero issues
flutter analyze

# Format check
dart format --set-exit-if-changed lib/

# Build both flavors
flutter build apk --flavor staff -t lib/main_staff.dart --debug
flutter build apk --flavor customer -t lib/main_customer.dart --debug
```

**Functional verification checklist** (test on emulator):

AUTH:
- [ ] Staff PIN login succeeds with valid credentials → navigates to dashboard
- [ ] Staff PIN login fails → shows error + shake animation + attempt counter
- [ ] Staff lockout after 5 fails → countdown timer visible
- [ ] Customer OTP request → receives OTP screen
- [ ] Customer OTP verify → navigates to home
- [ ] Logout clears storage + redirects to login

DASHBOARD:
- [ ] KPI cards load with real data
- [ ] Bay grid shows correct status colors
- [ ] Active jobs list loads and is tappable
- [ ] Period selector updates data

JOB FLOW (full end-to-end):
- [ ] Create job → step 1 customer search works
- [ ] Create job → step 2 category multi-select works
- [ ] Create job → step 3 assignment + submit creates job in API
- [ ] Job list shows new job
- [ ] Job detail loads all tasks, inspection summary, billing summary
- [ ] Add task to existing job
- [ ] Submit intake inspection → job advances to estimate_pending
- [ ] Send estimate → customer receives approval request
- [ ] Job status transitions are reflected immediately

DESIGN COMPLIANCE:
- [ ] Zero hardcoded colors (grep -r "Color(0x" lib/ | grep -v app_colors should be empty)
- [ ] All text uses AppTypography styles (no raw TextStyle in screens)
- [ ] All spacing uses AppSpacing constants
- [ ] Skeleton loaders appear before data loads
- [ ] Empty states appear correctly
- [ ] All buttons have press animations

REALTIME:
- [ ] Dashboard updates without reload when job status changes via API
- [ ] Customer job progress screen updates when technician updates task status

---

## DELIVERABLES

When all phases are complete, confirm:

1. `flutter analyze` shows 0 errors, 0 warnings
2. Both APKs build successfully
3. All files follow the repository pattern (no API calls in widgets)
4. All colors reference AppColors (zero raw hex in screens)
5. All routes use GoRouter (zero Navigator.push in screens)
6. All state uses Riverpod (zero setState except animation controllers)

Print a final summary of:
- Total files created
- Total screens built
- Total providers created
- Total models generated
- Any known limitations or items deferred to next sprint

---

*Pro Garage OS Flutter Master Prompt v1.0 — Akshara Technologies*
*API Spec v1.0 · PRD v1.0 · Design System v1.0*