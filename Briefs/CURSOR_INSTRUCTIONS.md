# ProGarage Flutter — Cursor AI Master Instructions
## Complete Hands-Off AI-Driven Development Guide

> **READ THIS FIRST — CURSOR OPERATING RULES**
>
> You are the sole developer of this production Flutter application. The human will not write a single line of code.
> Every decision — architecture, naming, file structure, algorithm, UI implementation — is yours to make and execute.
>
> **Your Prime Directives:**
> 1. Never ask the human to write code. If you need a decision, make the best one and document it.
> 2. Never get stuck in a loop. If an approach fails twice, switch strategy immediately.
> 3. After completing each task, update `PROGRESS.md` before stopping.
> 4. Never leave the project in a broken/non-compiling state at end of session.
> 5. Always run `flutter analyze` after each sprint and fix ALL warnings before marking sprint complete.
> 6. Performance and UX are non-negotiable — never ship janky, slow, or visually generic screens.

---

## Project Identity

| Key | Value |
|---|---|
| **App Name** | ProGarage |
| **Package** | `com.akshara.progarage` |
| **Platform** | Android (primary), iOS (secondary) |
| **Flutter SDK** | ≥ 3.19.0 |
| **Dart SDK** | ≥ 3.3.0 |
| **State Management** | Riverpod 2.x (code generation) |
| **Navigation** | GoRouter 13.x |
| **HTTP** | Dio 5.x |
| **Local DB** | Drift 2.x + SQLite |
| **Backend** | Laravel REST API (base URL in `.env`) |
| **Auth** | JWT (stored in `flutter_secure_storage`) |
| **Push** | Firebase Cloud Messaging |

---

## Design System — Non-Negotiable

Cursor must implement this design system from Sprint 0 and never deviate.

### Visual Identity

**Aesthetic Direction:** Industrial Precision — clean, dark-primary, high-contrast, mechanical. Think workshop-grade tooling, not a consumer lifestyle app. Every pixel must communicate speed, reliability, and professional control.

**Color Palette (implement as const in `app_colors.dart`):**
```dart
// Brand
static const Color primaryOrange = Color(0xFFFF6B2B);   // Main CTA, active states
static const Color primaryOrangeDim = Color(0xFFFF6B2B).withOpacity(0.15); // backgrounds

// Backgrounds (dark-first)
static const Color bgPrimary    = Color(0xFF0F1117);   // Main scaffold
static const Color bgSurface    = Color(0xFF1A1D27);   // Cards, sheets
static const Color bgElevated   = Color(0xFF222536);   // Input fields, elevated cards
static const Color bgOverlay    = Color(0xFF2A2D3E);   // Hover, selected states

// Text
static const Color textPrimary  = Color(0xFFF0F2FF);   // Headlines, primary content
static const Color textSecondary= Color(0xFF8B90A7);   // Labels, secondary info
static const Color textMuted    = Color(0xFF4A4F6A);   // Hints, disabled

// Status (semantic)
static const Color statusGreen  = Color(0xFF22C55E);   // Completed, paid, online
static const Color statusOrange = Color(0xFFFF9500);   // In Progress, pending
static const Color statusBlue   = Color(0xFF3B82F6);   // Awaiting Parts, info
static const Color statusRed    = Color(0xFFEF4444);   // Overdue, error, out of stock
static const Color statusPurple = Color(0xFFA855F7);   // Ready for Collection

// Utility
static const Color divider      = Color(0xFF2A2D3E);
static const Color shimmerBase  = Color(0xFF1A1D27);
static const Color shimmerHigh  = Color(0xFF2A2D3E);
```

**Typography (implement as const in `app_text_styles.dart`):**
```dart
// Font: 'Sora' for display/headlines, 'DM Sans' for body/UI
// Add to pubspec.yaml under google_fonts or bundled assets

// Display
static const displayLarge  = TextStyle(fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5);
static const displayMedium = TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3);

// Title
static const titleLarge    = TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
static const titleMedium   = TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

// Body (DM Sans)
static const bodyLarge     = TextStyle(fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
static const bodyMedium    = TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);

// Label
static const labelLarge    = TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.3);
static const labelMedium   = TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5);
static const labelSmall    = TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.8);
```

**Spacing System (implement as const in `app_sizes.dart`):**
```dart
static const double xs  = 4.0;
static const double sm  = 8.0;
static const double md  = 12.0;
static const double lg  = 16.0;
static const double xl  = 20.0;
static const double xxl = 24.0;
static const double xxxl= 32.0;

// Radius
static const double radiusSm  = 6.0;
static const double radiusMd  = 10.0;
static const double radiusLg  = 14.0;
static const double radiusXl  = 20.0;
static const double radiusFull= 100.0;

// Card elevation
static const double cardShadowBlur    = 20.0;
static const double cardShadowOffset  = 4.0;
```

### UI Component Rules (Cursor must follow)

1. **Cards** — Always `Container` with `BoxDecoration`, color `bgSurface`, borderRadius `radiusLg`, NO `Card` widget (it adds unwanted elevation flicker on dark theme).
2. **Buttons** — Custom `AppButton` widget only. No raw `ElevatedButton`/`TextButton`.
3. **Text Fields** — Custom `AppTextField` only. Border: `bgElevated`, focused: `primaryOrange`, error: `statusRed`.
4. **Status Chips** — `AppStatusChip` widget with color map keyed to job status string.
5. **Loading** — Always `shimmer` skeleton, never `CircularProgressIndicator` in list screens.
6. **Empty States** — Always a custom illustration + headline + subtext. Never a plain "No data found" text.
7. **Animations** — Use `AnimatedSwitcher`, `AnimatedContainer`, `TweenAnimationBuilder` for state transitions. Duration: 200ms standard, 350ms for page-level reveals.
8. **List Performance** — Always `ListView.builder` or `SliverList`. Never `Column` with `.map()` for lists > 3 items.
9. **Images** — Always `CachedNetworkImage` with `shimmer` placeholder and error fallback.
10. **Icons** — Use `phosphor_flutter` package (line weight icons match industrial aesthetic). No Material icons.

---

## Progress Tracking System

**Cursor must maintain `PROGRESS.md` in the project root at all times.**

### `PROGRESS.md` format Cursor must use:

```markdown
# ProGarage — Development Progress

**Last Updated:** [DATE TIME]
**Current Sprint:** S[N] — [Sprint Name]
**Overall Status:** [X/10 Sprints Complete]

## Active Sprint: S[N]

### Completed Tasks ✅
- [x] Task description — completed [DATE]

### In Progress 🔄
- [ ] Task description — started [DATE]

### Blocked ⛔
- (list any blockers with reason and attempted solutions)

### Next Session Pickup
> Cursor: Start here next session.
> File: `lib/features/[module]/[file].dart`
> Task: [exact task description]
> Context: [any critical context needed]

## Sprint History
| Sprint | Status | Completed Date | Notes |
|---|---|---|---|
| S0 | ✅ Complete | [DATE] | |
| S1 | 🔄 In Progress | — | |
```

**Rule:** Update `PROGRESS.md` every time a task is completed. Never end a session without updating it.

---

## Sprint 0 — Project Foundation

**Cursor Goal:** Create a runnable, architecturally complete project shell. Zero features, but every system in place.

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 0. Execute all incomplete tasks in order. After each task, update `PROGRESS.md`. Do not stop until Sprint 0 is fully complete and `flutter run` produces a branded splash screen."

---

### S0-T1: Create Flutter Project

```bash
flutter create pro_garage --org com.akshara --platforms android,ios
cd pro_garage
```

Immediately rename `lib/main.dart` content to minimal:
```dart
import 'package:flutter/material.dart';
import 'core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProGarageApp());
}
```

Create `lib/core/app.dart` — empty `ProGarageApp` returning `MaterialApp` with placeholder `Scaffold`.

---

### S0-T2: Establish Folder Architecture

Create ALL these folders and an empty `.gitkeep` file in each:

```
lib/
  core/
    api/
    constants/
    errors/
    router/
    theme/
    utils/
    widgets/
  data/
    models/
    repositories/
    local/
      daos/
      tables/
  domain/
    repositories/
  features/
    auth/
      data/
      presentation/
        screens/
        widgets/
        providers/
    dashboard/
      presentation/
        screens/
        widgets/
        providers/
    jobs/
      data/
      presentation/
        screens/
        widgets/
        providers/
    customers/
      data/
      presentation/
        screens/
        widgets/
        providers/
    vehicles/
      data/
      presentation/
        screens/
        widgets/
        providers/
    technicians/
      data/
      presentation/
        screens/
        widgets/
        providers/
    parts/
      data/
      presentation/
        screens/
        widgets/
        providers/
    billing/
      data/
      presentation/
        screens/
        widgets/
        providers/
    notifications/
      presentation/
        screens/
        widgets/
        providers/
    settings/
      presentation/
        screens/
        widgets/
        providers/
```

---

### S0-T3: pubspec.yaml — Complete Dependencies

Replace `pubspec.yaml` entirely with:

```yaml
name: pro_garage
description: ProGarage — Car Garage Management System
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5

  # Navigation
  go_router: ^13.2.0

  # HTTP & API
  dio: ^5.4.3
  pretty_dio_logger: ^1.3.1

  # JSON & Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # Local Storage
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.3
  path: ^1.9.0

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # Firebase
  firebase_core: ^2.30.1
  firebase_messaging: ^14.9.4

  # UI & UX
  shimmer: ^3.0.0
  cached_network_image: ^3.3.1
  phosphor_flutter: ^2.0.1
  flutter_animate: ^4.5.0
  gap: ^3.0.1

  # Charts
  fl_chart: ^0.67.0

  # PDF & Sharing
  pdf: ^3.10.8
  printing: ^5.13.1
  share_plus: ^9.0.0

  # Connectivity
  connectivity_plus: ^6.0.3

  # Utilities
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0
  logger: ^2.3.0
  equatable: ^2.0.5
  dartz: ^0.10.1

  # Splash & Icons
  flutter_native_splash: ^2.4.0

  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.18.0
  flutter_launcher_icons: ^0.13.1
  mocktail: ^1.0.3

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
    - .env
```

Create `assets/images/.gitkeep`, `assets/icons/.gitkeep`, `assets/animations/.gitkeep`.

Run: `flutter pub get`

---

### S0-T4: Environment Configuration

Create `.env` in project root:
```
# ProGarage Environment Config
APP_ENV=development
API_BASE_URL=http://69.62.78.240/api
API_TIMEOUT_SECONDS=30
FCM_SENDER_ID=your_fcm_sender_id
```

Create `lib/core/constants/app_env.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static int get apiTimeoutSeconds => int.parse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30');
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';
  static bool get isDevelopment => appEnv == 'development';
}
```

Update `main.dart` to load dotenv:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: ProGarageApp()));
}
```

---

### S0-T5: Design System Implementation

**File: `lib/core/constants/app_colors.dart`**
Implement the full color palette defined in the Design System section above. Every color as a `static const`.

**File: `lib/core/constants/app_text_styles.dart`**
Implement the full typography system. Use `google_fonts` package:
```dart
import 'package:google_fonts/google_fonts.dart';
// Use GoogleFonts.sora() for display fonts
// Use GoogleFonts.dmSans() for body fonts
```

**File: `lib/core/constants/app_sizes.dart`**
Implement the full spacing and radius constants.

**File: `lib/core/theme/app_theme.dart`**
Create `ThemeData` using Material 3:
```dart
class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryOrange,
      surface: AppColors.bgSurface,
      background: AppColors.bgPrimary,
      error: AppColors.statusRed,
    ),
    // Set all other ThemeData properties to match design system
    // No defaults — every component must use our colors
  );
}
```

---

### S0-T6: Core Shared Widgets

Create each widget as a separate file in `lib/core/widgets/`:

**`app_button.dart`** — Three variants: `AppButton.primary()`, `AppButton.secondary()`, `AppButton.ghost()`.
- Primary: `primaryOrange` fill, white text, `borderRadius: AppSizes.radiusMd`
- Loading state: replace label with `SizedBox(16,16)` white spinner
- Disabled state: 40% opacity
- All variants have `HapticFeedback.lightImpact()` on tap

**`app_text_field.dart`** — Single reusable input:
- Dark fill `bgElevated`, no outline border by default
- Focused: 1.5px `primaryOrange` border
- Error: 1.5px `statusRed` border + error text below
- Label floats above on focus (custom animated label, not Flutter's default which looks generic)
- Suffix/prefix icon support

**`app_status_chip.dart`** — Maps job status string → color + label:
```dart
static const statusConfig = {
  'created':              (AppColors.textMuted,    AppColors.bgElevated,  'New'),
  'in_progress':          (AppColors.statusOrange, Color(0xFF2A1F0A),     'In Progress'),
  'awaiting_parts':       (AppColors.statusBlue,   Color(0xFF0A1A2A),     'Awaiting Parts'),
  'ready_for_collection': (AppColors.statusPurple, Color(0xFF1A0A2A),     'Ready'),
  'completed':            (AppColors.statusGreen,  Color(0xFF0A2A1A),     'Completed'),
  'overdue':              (AppColors.statusRed,    Color(0xFF2A0A0A),     'Overdue'),
};
```
Chip style: colored text on tinted background, 4px horizontal padding, 2px vertical, `radiusFull`.

**`app_card.dart`** — Base card wrapper:
```dart
BoxDecoration(
  color: AppColors.bgSurface,
  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
  border: Border.all(color: AppColors.divider, width: 0.5),
)
```

**`app_shimmer.dart`** — Shimmer base:
```dart
Shimmer.fromColors(
  baseColor: AppColors.shimmerBase,
  highlightColor: AppColors.shimmerHigh,
  child: child,
)
```

**`app_empty_state.dart`** — Props: `icon`, `title`, `subtitle`, `actionLabel`, `onAction`.
Uses phosphor icon + styled text + optional `AppButton.primary()`.

**`app_error_state.dart`** — Full-screen error with retry. Props: `message`, `onRetry`.

**`loading_overlay.dart`** — `Stack` with semi-transparent `bgPrimary` + centered animated logo.

---

### S0-T7: API Client

**`lib/core/api/api_client.dart`**
```dart
class ApiClient {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: Duration(seconds: AppEnv.apiTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppEnv.apiTimeoutSeconds),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    dio.interceptors.addAll([
      AuthInterceptor(),       // adds Bearer token
      RetryInterceptor(dio),   // retries on network error (max 1 retry)
      if (AppEnv.isDevelopment) PrettyDioLogger(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}
```

**`lib/core/api/auth_interceptor.dart`**
- On request: read JWT from `FlutterSecureStorage`, add `Authorization: Bearer $token`
- On 401: call `POST /api/auth/refresh`, save new token, retry original request once
- If refresh fails: clear token, redirect to login via `GoRouter`

**`lib/core/api/retry_interceptor.dart`**
- Retry on `DioExceptionType.connectionTimeout` and `DioExceptionType.receiveTimeout`
- Max 1 retry with 1 second delay
- Do NOT retry on 4xx responses

**`lib/core/errors/failures.dart`**
```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure extends Failure { ... }
class ServerFailure extends Failure { final int statusCode; ... }
class AuthFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class ValidationFailure extends Failure { final Map<String, List<String>> errors; ... }
class CacheFailure extends Failure { ... }
```

**`lib/core/api/api_provider.dart`** — Riverpod provider:
```dart
@riverpod
Dio dio(DioRef ref) => ApiClient.createDio();
```

---

### S0-T8: Drift Local Database

**`lib/data/local/app_database.dart`** — Define `@DriftDatabase`, register all tables.

**Tables to create:**
- `JobsCache` — id, jobNumber, customerName, vehicleReg, status, technicianName, updatedAt
- `CustomersCache` — id, name, phone, totalVehicles, lastVisitDate
- `VehiclesCache` — id, registrationNumber, makeModel, year, ownerName, lastServiceDate
- `NotificationsCache` — id, type, title, body, entityId, entityType, isRead, createdAt

Each table: `IntColumn get id => integer()()`, use `@JsonKey` for serialization alignment.

**DAOs:**
- `JobsDao` — upsertAll, getAll, getByStatus, deleteAll
- `CustomersDao` — upsertAll, searchByName, getAll
- `VehiclesDao` — upsertAll, searchByReg, getAll
- `NotificationsDao` — insertNotification, markAsRead, getUnreadCount, getAll

Run codegen: `dart run build_runner build --delete-conflicting-outputs`

---

### S0-T9: GoRouter Configuration

**`lib/core/router/app_router.dart`**

Routes:
```
/splash                     → SplashScreen
/login                      → LoginScreen
/                           → AppShell (requires auth)
  /dashboard                → DashboardScreen
  /jobs                     → JobListScreen
    /jobs/create            → CreateJobScreen
    /jobs/:id               → JobDetailScreen
    /jobs/:id/edit          → EditJobScreen
  /customers                → CustomerListScreen
    /customers/create       → CreateCustomerScreen
    /customers/:id          → CustomerProfileScreen
  /vehicles                 → VehicleListScreen
    /vehicles/create        → CreateVehicleScreen
    /vehicles/:id           → VehicleProfileScreen
  /technicians              → TechnicianListScreen
    /technicians/create     → CreateTechnicianScreen
    /technicians/:id        → TechnicianDetailScreen
  /parts                    → PartsListScreen
    /parts/create           → CreatePartScreen
    /parts/:id              → PartDetailScreen
  /billing/invoices         → InvoiceListScreen
    /billing/invoices/:id   → InvoiceDetailScreen
  /billing/payments         → PaymentListScreen
  /billing/dues             → OutstandingDuesScreen
  /notifications            → NotificationsScreen
  /settings                 → SettingsScreen
```

Redirect logic:
```dart
redirect: (context, state) async {
  final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
  final isOnLogin = state.matchedLocation == '/login';
  if (!isLoggedIn && !isOnLogin) return '/login';
  if (isLoggedIn && isOnLogin) return '/dashboard';
  return null;
}
```

---

### S0-T10: App Entry & Splash

**`lib/core/app.dart`**
```dart
class ProGarageApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ProGarage',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
    );
  }
}
```

> `TextScaler.noScaling` is critical — prevents OS accessibility font size from breaking the UI layout.

**`SplashScreen`** — Full dark screen with ProGarage wordmark (Text widget using Sora font, `primaryOrange` accent on "Pro"), fade-in animation via `flutter_animate`, auto-navigates after 1.5s based on auth state.

**S0 Done Criteria:**
- [ ] `flutter run` launches without errors
- [ ] Splash screen appears with branding
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated with S0 complete

---

## Sprint 1 — Auth & Navigation Shell

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 1. Execute all incomplete tasks in order. Goal: working login screen, JWT auth flow, and app shell with bottom navigation."

---

### S1-T1: Auth Models & Repository

**`lib/features/auth/data/models/auth_models.dart`**
```dart
@freezed
class LoginRequest with _$LoginRequest {
  factory LoginRequest({required String email, required String password}) = _LoginRequest;
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  factory AuthResponse({
    required String token,
    required String tokenType,
    required UserModel user,
  }) = _AuthResponse;
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}

@freezed
class UserModel with _$UserModel {
  factory UserModel({
    required int id,
    required String name,
    required String email,
    required String role,  // 'owner' | 'manager' | 'technician'
    String? phone,
    String? avatar,
  }) = _UserModel;
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
```

**`lib/features/auth/data/auth_repository.dart`**
- `Future<Either<Failure, AuthResponse>> login(LoginRequest request)`
- `Future<Either<Failure, void>> logout()`
- On login success: store token in `FlutterSecureStorage`, store user as JSON in secure storage
- On logout: clear all secure storage keys

---

### S1-T2: Auth State Provider

**`lib/features/auth/presentation/providers/auth_provider.dart`**

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => _checkStoredAuth();

  Future<void> login(String email, String password) async { ... }
  Future<void> logout() async { ... }
  AuthState _checkStoredAuth() { /* read from secure storage */ }
}

@freezed
class AuthState with _$AuthState {
  factory AuthState.initial()               = _Initial;
  factory AuthState.loading()               = _Loading;
  factory AuthState.authenticated(UserModel user) = _Authenticated;
  factory AuthState.unauthenticated()       = _Unauthenticated;
  factory AuthState.error(String message)   = _Error;
}
```

---

### S1-T3: Login Screen

**`lib/features/auth/presentation/screens/login_screen.dart`**

**Layout (no AppBar, full-screen dark):**

Top 40%: Large mechanic/garage atmospheric background — use a `CustomPaint` widget drawing a subtle grid pattern in `bgElevated` color (5px spacing, 0.3 opacity lines). Overlay the ProGarage logo centered.

Bottom 60%: White-on-dark form card sliding up from bottom via `flutter_animate` `.slideY(begin: 0.3).fadeIn()`:
- Headline: "Welcome back" (Sora, displayMedium)
- Subtitle: "Sign in to your garage" (DM Sans, bodyMedium, textSecondary)
- Gap 32px
- `AppTextField` for Email/Phone
- `AppTextField` for Password (obscured, toggle suffix icon)
- Gap 8px
- `AppButton.primary` full-width "Sign In" with loading state
- Error message area: animated slide-down banner in `statusRed` tint

**Behavior:**
- Form validates on submit (not on change — avoids premature error messages)
- On success: GoRouter redirects to `/dashboard`
- Keyboard dismisses on tap outside
- Auto-fills last used email from secure storage (UX convenience)

**Animations:**
- Logo: `flutter_animate` `.fadeIn(duration: 600ms).scale(begin: Scalar(0.8, 0.8))`
- Form card: `.slideY(begin: 0.15, duration: 500ms, curve: Curves.easeOutCubic).fadeIn()`
- Error banner: `AnimatedSize` + `AnimatedOpacity`

---

### S1-T4: App Shell (Bottom Navigation)

**`lib/core/router/app_shell.dart`**

Custom `NavigationBar` with 5 items for owner/manager, 3 for technician:

Owner/Manager nav items:
1. House icon → `/dashboard` — label "Home"
2. Wrench icon → `/jobs` — label "Jobs" — badge with open jobs count
3. Users icon → `/customers` — label "Customers"
4. Receipt icon → `/billing/invoices` — label "Billing"
5. Grid icon → `/more` — label "More"

Technician nav items:
1. Wrench icon → `/jobs` — label "My Jobs"
2. Car icon → `/vehicles` — label "Vehicles"
3. Grid icon → `/more` — label "More"

**Custom `NavigationBar` styling:**
- Background: `bgSurface`
- Top border: 0.5px `divider`
- Selected indicator: small `primaryOrange` pill under icon (NOT the full-width Material 3 default)
- Selected icon: `primaryOrange`
- Unselected icon: `textMuted`
- No labels visible by default — icons only, label appears on selected item only

**Top AppBar** (custom, not Flutter's default `AppBar`):
- Height: 56px
- Background: `bgPrimary`
- Bottom border: 0.5px `divider`
- Left: Page title (Sora, titleLarge)
- Right: Notification bell icon (phosphor) with unread badge dot

**"More" Sheet:**
Tapping More tab opens a `DraggableScrollableSheet` bottom sheet (not a new screen) with a 3-column icon grid:
- Parts Inventory, Technicians, Reports, Settings, About

---

### S1-T5: Role-Based Navigation Guard

In `GoRouter` redirect:
- Read `authStateProvider` — if unauthenticated, redirect to `/login`
- Read user role from `UserModel.role`
- If `technician` and tries to access `/dashboard`, redirect to `/jobs`
- If `technician` and tries to access `/billing`, `/parts`, `/technicians`: redirect to `/jobs` with a snackbar "Access restricted"

---

**S1 Done Criteria:**
- [ ] Login screen renders with animations
- [ ] Login with valid credentials stores JWT and navigates to shell
- [ ] Invalid credentials shows animated error banner
- [ ] Bottom navigation works for all tabs
- [ ] Role-based routing redirects correctly
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 2 — Dashboard

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 2. Build the owner dashboard with KPIs, charts, quick actions, and activity feed. The dashboard must look premium — this is the first real screen the owner sees every day."

---

### S2-T1: Dashboard Models & Provider

**`lib/features/dashboard/data/models/dashboard_summary.dart`**
```dart
@freezed
class DashboardSummary with _$DashboardSummary {
  factory DashboardSummary({
    required int openJobs,
    required int completedToday,
    required int awaitingCollection,
    required double revenueToday,
    required double revenueWeek,
    required double revenueMonth,
    required int overdueJobs,
    required int lowStockParts,
    required List<JobStatusCount> jobsByStatus,
    required List<RecentJob> recentJobs,
    required List<TechnicianLoad> technicianLoads,
    required List<RevenuePoint> weeklyRevenue,
  }) = _DashboardSummary;
  factory DashboardSummary.fromJson(Map<String, dynamic> json) => _$DashboardSummaryFromJson(json);
}

@freezed
class JobStatusCount with _$JobStatusCount {
  factory JobStatusCount({required String status, required int count}) = _JobStatusCount;
  factory JobStatusCount.fromJson(Map<String, dynamic> json) => _$JobStatusCountFromJson(json);
}

@freezed
class RecentJob with _$RecentJob {
  factory RecentJob({
    required int id,
    required String jobNumber,
    required String vehicleReg,
    required String customerName,
    required String status,
    required DateTime updatedAt,
  }) = _RecentJob;
  factory RecentJob.fromJson(Map<String, dynamic> json) => _$RecentJobFromJson(json);
}

@freezed
class TechnicianLoad with _$TechnicianLoad {
  factory TechnicianLoad({
    required int id,
    required String name,
    required int openJobs,
    String? avatar,
  }) = _TechnicianLoad;
  factory TechnicianLoad.fromJson(Map<String, dynamic> json) => _$TechnicianLoadFromJson(json);
}

@freezed
class RevenuePoint with _$RevenuePoint {
  factory RevenuePoint({required String day, required double amount}) = _RevenuePoint;
  factory RevenuePoint.fromJson(Map<String, dynamic> json) => _$RevenuePointFromJson(json);
}
```

**`DashboardNotifier`** — `AsyncNotifier<DashboardSummary>`:
- `build()`: fetch immediately
- `refresh()`: re-fetch
- Auto-refresh timer: 60s using `Timer.periodic`, cancelled on `dispose` (override `dispose` in notifier)

---

### S2-T2: Dashboard Screen Layout

**File: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`**

Use `CustomScrollView` with slivers for buttery scroll performance:

```
SliverAppBar (collapsed: title "ProGarage", expanded: greeting + date)
  ↓
SliverToBoxAdapter → KPI Cards Row
  ↓
SliverToBoxAdapter → Revenue Chart
  ↓
SliverToBoxAdapter → Quick Actions
  ↓
SliverToBoxAdapter → Status Distribution
  ↓
SliverToBoxAdapter → Technician Workload Strip
  ↓
SliverToBoxAdapter → "Recent Activity" header
  ↓
SliverList → Recent Jobs (last 5, not paginated)
```

**Greeting Section (SliverAppBar expanded):**
- "Good morning, Sagar 👋" (dynamic based on time and user name)
- "Wednesday, 14 May · 3 open jobs need attention" (dynamic)
- Subtle horizontal gradient: `bgPrimary` to `bgSurface`

---

### S2-T3: KPI Cards

4 cards in a `2x2` grid (not horizontal scroll — grid is more scannable on mobile):

```
┌─────────────────┬─────────────────┐
│  🔧 Open Jobs   │  ✅ Done Today  │
│      12         │       8         │
│  +2 since 9am   │  ▲ 3 from yest  │
├─────────────────┼─────────────────┤
│  🕐 Awaiting    │  💰 Revenue     │
│  Collection     │  ₹ 24,500       │
│       3         │  Today          │
└─────────────────┴─────────────────┘
```

**`KpiCard` widget spec:**
- Container: `bgSurface`, `radiusLg`, 1px `divider` border
- Top row: small colored icon container (phosphor icon in a 32x32 `bgElevated` rounded box) + 3-dot menu (future: drill down)
- Middle: large number (Sora, 28px, `textPrimary`, `FontWeight.w700`)
- Bottom: delta indicator (green arrow up or red arrow down + % or count change)
- Tap: navigate to filtered view (Open Jobs → `/jobs?status=open`)
- Loading: full shimmer skeleton maintaining exact same dimensions

---

### S2-T4: Revenue Chart

`fl_chart` `LineChart` showing 7-day revenue trend:

Styling:
- Background: transparent (shows through `bgSurface` card)
- Line: `primaryOrange`, strokeWidth 2.5, smooth curve (`isCurved: true, curveSmoothness: 0.3`)
- Area fill: gradient `primaryOrange` 20% opacity → transparent
- No grid lines (X or Y)
- X labels: day abbreviations (Mon, Tue...) in `labelSmall` style
- Y labels: none — tooltip shows values on tap
- Touch tooltip: `bgElevated` container, `primaryOrange` indicator dot, `₹ X,XXX` formatted value
- Chart height: 160px

---

### S2-T5: Quick Action Buttons

2-column grid of action cards:

| Icon | Label | Route |
|---|---|---|
| Plus (orange) | New Job Card | `/jobs/create` |
| MagnifyingGlass | Search Vehicle | `/vehicles?search=true` |
| UserPlus | Add Customer | `/customers/create` |
| CurrencyInr | Record Payment | Quick payment bottom sheet |

Each action card: `bgSurface`, icon in `primaryOrangeDim` circle, label in `labelLarge`, `ripple` effect with `borderRadius: radiusMd`.

---

### S2-T6: Job Status Distribution

Horizontal stacked progress bar showing proportion of jobs by status:

- Single bar, full width, height 10px, `radiusFull`
- Each segment: status color, proportional width
- Legend below: colored dot + status name + count, `Wrap` widget (auto wraps to next line)

---

### S2-T7: Technician Workload Strip

Horizontal `ListView.builder` (scroll):

Each technician card (width: 100px):
- Avatar circle (initials in `bgElevated`, or `CachedNetworkImage`)
- Name (truncated, `labelMedium`)
- `AppStatusChip`-style job count badge: "5 jobs" in `primaryOrangeDim`
- Tap → `/technicians/:id`

---

### S2-T8: Recent Jobs List

Last 5 jobs as `RecentJobTile`:
- Left: vehicle reg in monospaced tag style (`bgElevated`, `radiusSm`, `primaryOrange` text, Sora font)
- Center: customer name (bodyMedium) + "2h ago" (labelSmall, textMuted)
- Right: `AppStatusChip`
- Tap → `/jobs/:id`
- "View All Jobs →" text button at bottom

---

**S2 Done Criteria:**
- [ ] Dashboard renders with all sections
- [ ] Real data loads from API (or graceful empty state if API not yet ready)
- [ ] Pull-to-refresh works
- [ ] Charts animate on load
- [ ] Shimmer shows while loading
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 3 — Jobs / Job Cards

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 3. This is the most critical module — the full job card lifecycle. Every interaction must feel instant and professional. Execute all tasks in order."

---

### S3-T1: Job Models (Freezed)

```dart
@freezed
class Job with _$Job {
  factory Job({
    required int id,
    required String jobNumber,
    required String status,
    required Vehicle vehicle,
    required Customer customer,
    Technician? technician,
    required String description,
    String? jobType,
    DateTime? estimatedCompletionDate,
    required List<JobPart> parts,
    required List<JobNote> notes,
    required double totalAmount,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Job;
  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

@freezed
class JobPart with _$JobPart {
  factory JobPart({
    required int id,
    required int partId,
    required String partName,
    required String partNumber,
    required int quantity,
    required double unitPrice,
    required double subtotal,
  }) = _JobPart;
  factory JobPart.fromJson(Map<String, dynamic> json) => _$JobPartFromJson(json);
}

@freezed
class JobNote with _$JobNote {
  factory JobNote({
    required int id,
    required String content,
    required String authorName,
    required DateTime createdAt,
  }) = _JobNote;
  factory JobNote.fromJson(Map<String, dynamic> json) => _$JobNoteFromJson(json);
}

// Paginated list response wrapper
@freezed
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  factory PaginatedResponse({
    required List<T> data,
    required int total,
    required int currentPage,
    required int lastPage,
    required int perPage,
  }) = _PaginatedResponse;
}
```

---

### S3-T2: Jobs Repository & Provider

**Repository:** `JobsRepository`
- `Future<Either<Failure, PaginatedResponse<Job>>> getJobs({String? status, String? search, int page = 1})`
- `Future<Either<Failure, Job>> getJob(int id)`
- `Future<Either<Failure, Job>> createJob(CreateJobRequest request)`
- `Future<Either<Failure, Job>> updateJob(int id, UpdateJobRequest request)`
- `Future<Either<Failure, Job>> updateStatus(int id, String newStatus)`
- `Future<Either<Failure, Job>> addPart(int jobId, AddPartRequest request)`
- `Future<Either<Failure, Job>> addNote(int jobId, String content)`
- `Future<Either<Failure, Job>> assignTechnician(int jobId, int technicianId)`

**Providers:**
- `jobsListProvider(status, search)` — `AsyncNotifier` with pagination
- `jobDetailProvider(id)` — `AsyncNotifier<Job>`

Pagination pattern:
```dart
// Support infinite scroll with page tracking
class JobsListNotifier extends _$JobsListNotifier {
  int _page = 1;
  bool _hasMore = true;
  final List<Job> _jobs = [];

  Future<void> loadMore() async {
    if (!_hasMore) return;
    // fetch next page, append to _jobs, update state
  }
}
```

After every successful write (create/update/status change): invalidate `jobsListProvider` and `dashboardSummaryProvider` to force refresh.

---

### S3-T3: Job List Screen

**`lib/features/jobs/presentation/screens/job_list_screen.dart`**

**Layout:**
```
Custom SliverAppBar (pinned)
  ├── Title "Jobs"
  └── Search icon → opens SearchBar inline (animated expand)
Status Filter Tabs (pinned below AppBar)
  └── Scrollable tabs: All · New · In Progress · Awaiting Parts · Ready · Completed
Job List (SliverList)
  └── JobListTile × N
  └── Load More indicator at bottom
FAB (owner/manager only) → `/jobs/create`
```

**Status Filter Tab bar:**
- NOT default `TabBar` — use custom `SingleChildScrollView` + `Row` of `FilterChip`-style buttons
- Selected: `primaryOrange` fill, white text
- Unselected: `bgElevated`, `textSecondary`
- Smooth color transition on selection

**`JobListTile` widget:**
```
┌──────────────────────────────────────────┐
│ [JOB-0042] ──────────────── [In Progress]│
│  Toyota Camry · MH04AB1234               │
│  Rahul Sharma · 2h ago    [Tech: Ketan] │
│  ₹ 4,500  ────────────── [progress bar] │
└──────────────────────────────────────────┘
```
- Job number: Sora font, `primaryOrange`
- Vehicle reg: `AppStatusChip`-style tag
- Thin 2px progress indicator at bottom (orange fill based on estimated completion %)
- Swipe right: quick status change
- Swipe left: call customer (opens phone dialer)

**Search behavior:**
- Debounced 400ms after last keystroke
- Searches across: job number, vehicle reg, customer name
- While searching: shimmer on results
- No results: `AppEmptyState` with "No jobs match your search"

**Offline state:**
- When `ConnectivityService.isOffline`: show `OfflineBanner`, load from `JobsDao.getAll()`
- Offline data has slightly different tile style (small "Cached" label, `textMuted`)

---

### S3-T4: Job Detail Screen

**`lib/features/jobs/presentation/screens/job_detail_screen.dart`**

Use `CustomScrollView`:

**Section 1 — Header:**
- Job number + status chip side by side
- Created date (small, `textMuted`)

**Section 2 — Vehicle Card:**
- Vehicle reg as large tag
- Make, model, year row
- Last mileage recorded
- Tap → `/vehicles/:id`

**Section 3 — Customer Card:**
- Avatar (initials circle) + name + phone
- Phone: `GestureDetector` → `url_launcher` tel: link
- WhatsApp icon button → `https://wa.me/91XXXXXXXXXX`

**Section 4 — Status Timeline:**
Visual horizontal step tracker:
```
Created → In Progress → Awaiting Parts → Ready → Completed
   ●─────────●─────────────○──────────────○──────○
 (green)  (orange)       (grey)          (grey)  (grey)
```
- Completed steps: `statusGreen` dot + filled line
- Current step: pulsing `primaryOrange` dot (CSS-style pulse via `TweenAnimationBuilder`)
- Future steps: `bgElevated` dot + dashed line

**Section 5 — Technician:**
- Assigned technician card (avatar + name + "X active jobs")
- "Reassign" button (owner/manager only) → opens technician picker bottom sheet

**Section 6 — Parts Used:**
- List of `JobPartRow` widgets
- Each row: part name + number, quantity × unit price, subtotal right-aligned
- Divider between rows
- Total row at bottom: "Parts Total: ₹ X,XXX"
- "+ Add Part" button → opens parts picker bottom sheet

**Section 7 — Notes:**
- Thread-style display (similar to WhatsApp notes)
- Each note: author initial circle + name + date + content
- "+ Add Note" button → `showModalBottomSheet` with text input

**Bottom Action Bar (fixed, outside scroll):**
- Status = created/in_progress/awaiting: "Update Status" (primary orange)
- Status = ready_for_collection: "Generate Invoice" (primary orange)
- Status = completed: "View Invoice" (secondary)

---

### S3-T5: Status Update Bottom Sheet

**`JobStatusUpdateSheet`** widget (modal bottom sheet):

```
Current: [In Progress] → Move to:
┌─────────────────────────────────┐
│  ⏳ Awaiting Parts              │  ← tap to select
│  ✅ Ready for Collection        │
└─────────────────────────────────┘
[ Confirm Update ]
```

- Only valid next statuses shown (enforced by status machine map)
- On confirm: optimistic UI update (immediate), API call in background
- On API failure: revert optimistic update + error snackbar
- "Ready for Collection" option: shows additional toggle "Send customer notification?" (default ON)

---

### S3-T6: Create Job — Stepper Form

**`lib/features/jobs/presentation/screens/create_job_screen.dart`**

Custom `PageView`-based stepper (3 pages, swipe-disabled — only next/back buttons navigate):

**Step indicator** (top, custom widget):
```
[1] Vehicle ──── [2] Customer ──── [3] Details
```
Active step: `primaryOrange` numbered circle
Completed step: green check circle
Inactive: `bgElevated` circle

**Step 1 — Vehicle:**
- `AppTextField` for registration number (auto-uppercase on change)
- "Search" button → `GET /api/vehicles?search=$reg`
- If found: show `VehicleSummaryCard` (make, model, year, owner name) with "Use This Vehicle" button
- If not found: "Add New Vehicle" form expands inline:
  - Make (text), Model (text), Year (number, 4-digit), Color, Fuel Type (dropdown)
- Form validates before Step 2 is unlocked

**Step 2 — Customer:**
- `AppTextField` for phone number search (live search, debounced 400ms)
- Results list below (3 max, then "see all")
- On select: shows `CustomerSummaryCard`
- "Add New Customer" link → inline mini form (name + phone required)
- Auto-populated if customer found via vehicle (vehicle linked to customer)

**Step 3 — Job Details:**
- Job Type dropdown (options: Service, Repair, Inspection, Accident Repair, AC Service, Electrical, Body Work, Other)
- Description `AppTextField` (multiline, 4 rows)
- Estimated Completion Date picker (Material 3 `DatePicker`, styled with our theme)
- Assign Technician (searchable dropdown)
- Priority toggle: Normal / Urgent (urgent adds a red tag to job)

**Navigation:**
- "Back" button: `AppButton.secondary`
- "Next" button: `AppButton.primary` with validation
- "Create Job" on Step 3: shows `LoadingOverlay`, calls API, navigates to new job detail on success

---

### S3-T7: Add Parts Bottom Sheet

Reusable `AddPartsToJobSheet`:
- Search `AppTextField` at top (debounced, calls `GET /api/parts?search=`)
- Results: `PartSearchTile` — name, part number, current stock, unit price
- On tap: expands inline to show quantity input (stepper: minus/plus buttons)
- Stock warning: if quantity > stock, show orange warning "Only X in stock"
- Confirm button: adds part, updates job detail parts section optimistically

---

**S3 Done Criteria:**
- [ ] Job list with all filter tabs loads and paginates
- [ ] Search works with debounce
- [ ] Job detail shows all sections
- [ ] Status update works with optimistic UI
- [ ] Create job stepper completes end-to-end
- [ ] Add parts and notes work
- [ ] Offline job list loads from cache
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 4 — Customers & Vehicles

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 4. Build the full Customer and Vehicle modules. Focus on the service history timeline — it must look like a premium automotive history report."

---

### S4-T1: Customer & Vehicle Models

```dart
@freezed
class Customer with _$Customer {
  factory Customer({
    required int id,
    required String name,
    required String phone,
    String? email,
    String? address,
    required int totalVehicles,
    required int totalJobs,
    required double totalSpent,
    required double outstandingBalance,
    DateTime? lastVisitDate,
    required DateTime createdAt,
    List<Vehicle>? vehicles,
  }) = _Customer;
  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
}

@freezed
class Vehicle with _$Vehicle {
  factory Vehicle({
    required int id,
    required String registrationNumber,
    required String make,
    required String model,
    required int year,
    String? color,
    String? fuelType,
    int? currentMileage,
    required int ownerId,
    String? ownerName,
    DateTime? lastServiceDate,
    List<ServiceHistoryEntry>? serviceHistory,
  }) = _Vehicle;
  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}

@freezed
class ServiceHistoryEntry with _$ServiceHistoryEntry {
  factory ServiceHistoryEntry({
    required int jobId,
    required String jobNumber,
    required String description,
    required String status,
    required int mileageAtService,
    required double amount,
    required DateTime serviceDate,
  }) = _ServiceHistoryEntry;
  factory ServiceHistoryEntry.fromJson(Map<String, dynamic> json) => _$ServiceHistoryEntryFromJson(json);
}
```

---

### S4-T2: Customer List Screen

Same pattern as Job List:
- `CustomScrollView`, search bar, infinite scroll
- `CustomerListTile`: avatar (colored initials), name, phone, vehicle count badge, last visit date
- Search: debounced, name + phone
- FAB → add customer

---

### S4-T3: Customer Profile Screen

**Layout (CustomScrollView):**

**Sticky header card:**
- Large initials avatar (60px circle, random-but-deterministic color based on name hash)
- Name (displayMedium), phone (tap to call), email (tap to email)
- 3 action icon buttons: Call · WhatsApp · Edit

**Stats Strip:**
3 mini stat cards in a row: Total Visits · Total Spent · Outstanding (red if > 0)

**Vehicles section:**
- Horizontal `ListView` of `VehicleMiniCard`:
  - Vehicle reg (orange tag), make+model, year
  - Last service date
  - Tap → Vehicle Profile

**Service History:**
- Section header with job count
- `ServiceHistoryList` — all jobs for this customer, newest first
- Each `ServiceHistoryTile`: job number, vehicle reg, date, description snippet, amount, status chip
- Tap → Job Detail

---

### S4-T4: Vehicle Profile Screen

**Hero section:**
- Vehicle registration as large display text (Sora, 32px, `primaryOrange`)
- Make + Model + Year (displayMedium, `textSecondary`)
- Color indicator dot + color name
- Fuel type chip

**Vehicle Details Grid:**
2-column grid: Mileage · Color · Fuel Type · Year · Make · Model (structured info display)

**Owner Card:**
- Tap → Customer Profile

**Service History Timeline:**
This must look premium:

```
────── 2024 ──────
         │
    ○────┤  14 May 2024
         │  Full Service & Oil Change
         │  Ketan · ₹ 4,500 · 45,230 km
         │  [Completed ✅]
         │
    ○────┤  12 Feb 2024
         │  Brake Pad Replacement
         │  Arjun · ₹ 2,100 · 43,100 km
         │  [Completed ✅]
         │
────── 2023 ──────
```

- Year headers: centered with horizontal lines on either side (custom `Row` + `Expanded` + `Divider`)
- Timeline line: 2px vertical `primaryOrangeDim` left border
- Entry dots: 10px `primaryOrange` circles on the line
- Card content: right of line, in `AppCard`

**Mileage Chart:**
`fl_chart` `LineChart` — x: service dates, y: mileage — shows vehicle's kilometer progression over time.

---

**S4 Done Criteria:**
- [ ] Customer list + search + profile complete
- [ ] Vehicle list + search + profile complete  
- [ ] Service history timeline renders correctly
- [ ] Mileage chart animates on load
- [ ] Call/WhatsApp actions work
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 5 — Technicians

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 5. Build the Technician module including workload board and performance stats."

---

### S5-T1: Technician Models

```dart
@freezed
class Technician with _$Technician {
  factory Technician({
    required int id,
    required String name,
    required String phone,
    required String specialization,
    required int openJobs,
    required int completedThisMonth,
    required double avgCompletionHours,
    bool? isAvailable,
    DateTime? joiningDate,
    List<WeeklyPerformance>? weeklyPerformance,
    List<Job>? assignedJobs,
  }) = _Technician;
  factory Technician.fromJson(Map<String, dynamic> json) => _$TechnicianFromJson(json);
}

@freezed
class WeeklyPerformance with _$WeeklyPerformance {
  factory WeeklyPerformance({required String weekLabel, required int completedJobs}) = _WeeklyPerformance;
  factory WeeklyPerformance.fromJson(Map<String, dynamic> json) => _$WeeklyPerformanceFromJson(json);
}
```

---

### S5-T2: Technician List Screen

**`TechnicianListTile`:**
- Avatar circle (initials)
- Name + specialization
- Right side: job count badge + availability indicator dot (green/red)
- Progress bar below showing workload (jobs / max_jobs_capacity)

**Workload Board View** (toggle between list and board):
- Board: `GridView.builder` 2-column, each card shows technician + count prominently
- Board card has a color intensity that increases with workload (low=green tint, high=red tint) — use `Color.lerp`

---

### S5-T3: Technician Detail Screen

- Profile header (avatar, name, phone, specialization, joining date)
- Stats row: Open Jobs · Completed This Month · Avg Hours Per Job
- Performance chart: `fl_chart` `BarChart` — last 4 weeks, jobs completed per week
- Assigned jobs list: paginated `JobListTile` filtered to this technician
- Edit button → edit form

---

### S5-T4: Technician Picker (Reusable)

`TechnicianPickerSheet` — bottom sheet used in:
- Create Job Step 3
- Job Detail reassign
- Shows all technicians sorted by open job count (least loaded first)
- Clearly shows workload to help manager make smart assignment decision

---

**S5 Done Criteria:**
- [ ] Technician list with workload indicators
- [ ] Technician detail with performance chart
- [ ] Technician picker works from job detail
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 6 — Parts & Inventory

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 6. Build the Parts catalog with inventory tracking. Low stock alerts must be prominent."

---

### S6-T1: Parts Models

```dart
@freezed
class Part with _$Part {
  factory Part({
    required int id,
    required String name,
    required String partNumber,
    required String category,
    String? description,
    required double unitPrice,
    required int stockQuantity,
    required int reorderLevel,
    required String stockStatus,  // 'in_stock' | 'low_stock' | 'out_of_stock'
    List<StockTransaction>? stockHistory,
  }) = _Part;
  factory Part.fromJson(Map<String, dynamic> json) => _$PartFromJson(json);
}

@freezed
class StockTransaction with _$StockTransaction {
  factory StockTransaction({
    required int id,
    required String type,        // 'addition' | 'deduction'
    required int quantity,
    required int balanceAfter,
    String? jobReference,
    required DateTime createdAt,
  }) = _StockTransaction;
  factory StockTransaction.fromJson(Map<String, dynamic> json) => _$StockTransactionFromJson(json);
}
```

---

### S6-T2: Parts List Screen

**Features:**
- Category filter chips row (scrollable): All · Engine · Body · Electrical · AC · Consumables · Other
- Search by name or part number
- `PartListTile`: part name + number, category chip, price (right), stock badge
- Stock badge design:
  - In Stock: green dot + "X in stock"
  - Low Stock: orange warning icon + "X in stock (low)"
  - Out of Stock: red badge "OUT OF STOCK"
- Sort dropdown: Name A-Z · Price Low-High · Stock Low-High

---

### S6-T3: Part Detail Screen

- Part info header: name, number, category, description
- Price: large display, `primaryOrange`
- Stock gauge: custom `CustomPaint` arc gauge showing stock level vs reorder level
- Stock history list: transaction rows with type indicator (green + for additions, red - for deductions)
- Edit button

---

### S6-T4: Add/Edit Part Form

Fields: Name, Part Number, Category (dropdown), Description, Unit Price, Current Stock, Reorder Level.
Validation: price must be > 0, stock must be ≥ 0, reorder level must be < stock.

---

**S6 Done Criteria:**
- [ ] Parts list with category filter and search
- [ ] Part detail with stock gauge
- [ ] Stock history visible
- [ ] Low stock highlighted prominently
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 7 — Billing & Payments

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 7. Build the billing module. The invoice PDF must look like a real professional Indian GST invoice — this is what the garage owner sends to customers. Quality here is critical."

---

### S7-T1: Invoice & Payment Models

```dart
@freezed
class Invoice with _$Invoice {
  factory Invoice({
    required int id,
    required String invoiceNumber,
    required Job job,
    required String status,       // 'unpaid' | 'partially_paid' | 'paid' | 'overdue'
    required List<InvoiceLineItem> lineItems,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double totalAmount,
    required double paidAmount,
    required double outstandingAmount,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required GarageDetails garageDetails,
  }) = _Invoice;
  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
}

@freezed
class InvoiceLineItem with _$InvoiceLineItem {
  factory InvoiceLineItem({
    required String description,
    required String type,   // 'labour' | 'part'
    required double quantity,
    required double unitPrice,
    required double amount,
  }) = _InvoiceLineItem;
  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) => _$InvoiceLineItemFromJson(json);
}

@freezed
class GarageDetails with _$GarageDetails {
  factory GarageDetails({
    required String name,
    required String address,
    required String phone,
    String? gstNumber,
    String? email,
  }) = _GarageDetails;
  factory GarageDetails.fromJson(Map<String, dynamic> json) => _$GarageDetailsFromJson(json);
}

@freezed
class Payment with _$Payment {
  factory Payment({
    required int id,
    required int invoiceId,
    required String invoiceNumber,
    required String customerName,
    required double amount,
    required String paymentMode,  // 'cash' | 'upi' | 'card' | 'bank_transfer'
    String? referenceNumber,
    required DateTime paymentDate,
    required DateTime createdAt,
  }) = _Payment;
  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}
```

---

### S7-T2: Invoice List Screen

Filter tabs: All · Unpaid · Paid · Overdue

`InvoiceListTile`:
- Invoice number (Sora, `primaryOrange`)
- Customer name + vehicle reg
- Amount (right, bold)
- Status chip
- Due date (red if overdue)

---

### S7-T3: Invoice Detail Screen (In-App View)

Full-screen invoice view styled like the PDF but rendered in Flutter widgets:

```
┌─────────────────────────────────────────┐
│  ProGarage                   INVOICE    │
│  123 Workshop Road, Rajkot              │
│  GST: 24XXXXXX                          │
│─────────────────────────────────────────│
│  Bill To:          Invoice #: PG-0042   │
│  Rahul Sharma      Date: 14 May 2024    │
│  9876543210        Due: 21 May 2024     │
│─────────────────────────────────────────│
│  Vehicle: MH04AB1234 · Toyota Camry     │
│─────────────────────────────────────────│
│  DESCRIPTION          QTY   RATE   AMT  │
│  Oil Change Labour    1    500    500   │
│  Engine Oil 5W30      4    350   1400   │
│  Oil Filter           1    250    250   │
│─────────────────────────────────────────│
│                    Subtotal:  ₹ 2,150   │
│                    CGST 9%:   ₹   194   │
│                    SGST 9%:   ₹   194   │
│                    TOTAL:    ₹ 2,538   │
│─────────────────────────────────────────│
│  Paid: ₹ 1,000     Outstanding: ₹1,538 │
└─────────────────────────────────────────┘
```

Action bar at bottom:
- "Download PDF" → generates PDF + saves to downloads
- "Share" → `share_plus` with PDF file
- "Record Payment" → opens payment bottom sheet
- "Print" → `printing` package

---

### S7-T4: PDF Invoice Generation

**`lib/features/billing/data/services/invoice_pdf_service.dart`**

Uses `pdf` package to generate a proper A4 GST invoice:

```dart
class InvoicePdfService {
  static Future<Uint8List> generatePdf(Invoice invoice) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => _buildInvoicePage(invoice),
    ));
    return doc.save();
  }
}
```

PDF styling requirements:
- Header: garage name in bold (Sora equivalent in PDF), "TAX INVOICE" right-aligned in orange
- Professional table with `pw.TableBorder`
- GST breakdown clearly shown (CGST + SGST)
- Footer: "Thank you for your business. Payment due within 7 days."
- Watermark "PAID" in green diagonal text if `invoice.status == 'paid'`
- Font: use `pw.Font.ttf` with embedded Sora/DMSans font files from assets

---

### S7-T5: Record Payment Bottom Sheet

`RecordPaymentSheet`:
- Outstanding amount prominently displayed at top
- Amount input (`AppTextField`, numeric, pre-filled with outstanding amount)
- Payment mode selector: horizontal chip row (Cash · UPI · Card · Bank Transfer)
- Reference number field: visible only for UPI/Card/Bank Transfer modes
- Date picker (defaults to today)
- "Record Payment" button

On submit:
- If amount == outstanding: invoice marked as Paid, green success animation
- If amount < outstanding: invoice stays Unpaid/Partially Paid, shows remaining balance

---

### S7-T6: Outstanding Dues Screen

- Total outstanding amount: large display at top in `statusRed`
- Sorted by oldest due date first
- `DuesTile`: customer name, vehicle, invoice ref, amount, days overdue badge
- "Record Payment" swipe action on each tile

---

**S7 Done Criteria:**
- [ ] Invoice list with status filters
- [ ] Invoice detail screen renders correctly
- [ ] PDF generates and is shareable via WhatsApp
- [ ] Payment recording works (partial + full)
- [ ] Outstanding dues screen works
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 8 — Notifications & Offline

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 8. Implement FCM push notifications and offline support. Every list screen must work when offline."

---

### S8-T1: Firebase Setup

1. Create `android/app/google-services.json` (placeholder — note in PROGRESS.md that this requires the actual Firebase project file from the human)
2. Update `android/build.gradle` and `android/app/build.gradle` for Firebase
3. Initialize Firebase in `main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

---

### S8-T2: Notification Service

**`lib/features/notifications/data/notification_service.dart`**

```dart
class NotificationService {
  static Future<void> initialize(WidgetRef ref) async {
    // Request permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Get FCM token and send to backend
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _sendTokenToBackend(token, ref);

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken, ref);
    });

    // Foreground messages → in-app notification banner
    FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message, ref);
      _storeNotification(message);
    });

    // Background tap → deep link
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message, ref);
    });

    // Cold start
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial, ref);
  }
}
```

**Deep link routing:**
```dart
static void _handleNotificationTap(RemoteMessage message, WidgetRef ref) {
  final type = message.data['type'];
  final id = message.data['entity_id'];
  switch (type) {
    case 'job_status_changed': ref.read(routerProvider).push('/jobs/$id');
    case 'invoice_created':    ref.read(routerProvider).push('/billing/invoices/$id');
    case 'payment_received':   ref.read(routerProvider).push('/billing/invoices/$id');
  }
}
```

**In-app notification banner:**
Custom overlay widget at top of screen (slides down, auto-dismisses in 4s):
- `bgElevated` background, `radiusMd`, subtle shadow
- Icon based on notification type + title + body (2 lines max)
- Tap to navigate to entity

---

### S8-T3: Notifications Center Screen

- `NotificationsDao.getAll()` — local Drift data
- `NotificationTile`: icon (type-based), title, body, time, unread dot
- Mark all as read button in app bar
- Pull-to-refresh triggers `GET /api/notifications` and syncs to local DB
- Empty state: "You're all caught up 🎉"

---

### S8-T4: Offline Support Implementation

**`ConnectivityService` (Riverpod provider):**
```dart
@riverpod
Stream<ConnectivityResult> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}

@riverpod
bool isOffline(IsOfflineRef ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.when(
    data: (result) => result == ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
}
```

**`OfflineBanner` widget:**
```dart
// Pinned below AppBar when offline
// Animated slide-down appearance
// "You're offline — showing cached data" + wifi-off icon
// Auto-dismisses when connection restores (green flash "Back online!")
```

**Cache sync strategy:**
- After every successful list API response: upsert first 100 records into Drift
- Cache stores only the fields needed for list tiles (not full detail)
- For detail screens when offline: show cached tile data + "Full details require connection" notice

---

**S8 Done Criteria:**
- [ ] FCM token registered (note: requires `google-services.json` from human)
- [ ] In-app notification banner works in foreground
- [ ] Notification center screen shows local notifications
- [ ] Deep links navigate correctly on tap
- [ ] Offline banner appears when no connection
- [ ] Jobs, Customers, Vehicles list from cache when offline
- [ ] `flutter analyze` — zero issues
- [ ] `PROGRESS.md` updated

---

## Sprint 9 — Polish, QA & Play Store

**Session Start Command for Cursor:**
> "Read `PROGRESS.md`. We are in Sprint 9 — the final sprint. Polish every screen, fix all issues, run full regression, and prepare the Play Store build. Zero compromises on quality."

---

### S9-T1: UX Polish Pass (Every Screen)

For each screen, verify and fix:

**Animations checklist:**
- [ ] List items fade/slide in on first load (`flutter_animate` `.fadeIn().slideX()` with staggered delays: `delay: Duration(milliseconds: index * 50)`)
- [ ] Page transitions: `GoRouter` custom transitions using `CustomTransitionPage` — slides from right on push, fades on pop
- [ ] Bottom sheets: `showModalBottomSheet` with `isScrollControlled: true`, drag handle, rounded top corners
- [ ] FABs: scale animation on appearance
- [ ] Status chip: `AnimatedSwitcher` when status changes
- [ ] Loading → content: `AnimatedSwitcher` fade (duration 200ms)

**Interaction checklist:**
- [ ] All tappable areas: min 48x48px touch target
- [ ] All buttons: `HapticFeedback.lightImpact()` on tap
- [ ] Success actions: `HapticFeedback.mediumImpact()`
- [ ] Destructive actions: `HapticFeedback.heavyImpact()`
- [ ] Keyboard: always shows `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` on scrollable screens
- [ ] Forms: focus moves to next field on keyboard "next" action

**Empty state checklist:**
Every list screen must have:
- Custom icon (phosphor, 64px, `textMuted`)
- Headline: context-appropriate ("No jobs yet")
- Subline: action-oriented ("Tap + to create your first job")
- Optional CTA button

---

### S9-T2: Performance Audit

Run these checks and fix anything that fails:

**Widget Performance:**
```dart
// Wrap all list items in RepaintBoundary
// Verify: no setState calls from parent rebuilding entire list
// Verify: all providers read with ref.watch() at lowest widget level possible
// Verify: no synchronous heavy computation in build() methods
```

**Memory:**
- `CachedNetworkImage` — verify `memCacheWidth` set to 2x actual display size
- `fl_chart` — verify `swapAnimationDuration: Duration.zero` for large datasets (> 100 points)

**Run Flutter DevTools:**
- Performance overlay: confirm 60fps on scroll on a mid-range Android device
- Memory tab: no memory leaks on repeated navigate-in/navigate-out
- Widget rebuild inspector: no unexpected rebuilds

---

### S9-T3: Settings Screen

**`lib/features/settings/presentation/screens/settings_screen.dart`**

Sections:
1. **Business Profile** — Garage name, address, phone, GST number, edit button
2. **Account** — Name, email, change password (redirect to API endpoint)
3. **Notifications** — Toggle: Job assignments, Status updates, Payments received
4. **App** — App version, dark mode toggle (already default), clear cache, help
5. **Sign Out** — Destructive red button with confirmation dialog

---

### S9-T4: App Icon & Splash

**App Icon:**
Using `flutter_launcher_icons` — create `flutter_launcher_icons.yaml`:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#0F1117"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

App icon design spec (create as SVG then export PNG):
- Background: `#0F1117` (dark)
- Foreground: Stylized wrench + "PG" monogram in `#FF6B2B`

**Splash screen (`flutter_native_splash.yaml`):**
```yaml
flutter_native_splash:
  color: "#0F1117"
  image: assets/images/splash_logo.png
  android_12:
    color: "#0F1117"
    image: assets/images/splash_logo.png
```

---

### S9-T5: Build Configuration & Signing

**`android/app/build.gradle` — Release config:**
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Generate keystore (add instructions to `PROGRESS.md` for human to run):**
```bash
keytool -genkey -v -keystore progarage-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias progarage
```

**Build release AAB:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

### S9-T6: Final QA Checklist

Cursor must manually trace through each flow and confirm:

**Auth:**
- [ ] Login with valid credentials → dashboard
- [ ] Login with invalid credentials → error banner
- [ ] Token expiry → auto-refresh → continues normally
- [ ] Logout → clears session → login screen

**Jobs (full lifecycle):**
- [ ] Create job (new vehicle + new customer + all details) → success
- [ ] Job appears in job list
- [ ] Update status Created → In Progress → Ready for Collection
- [ ] Add part to job → stock deducted
- [ ] Add note to job → appears in thread
- [ ] Generate invoice from job
- [ ] Share invoice PDF via WhatsApp (mock test)
- [ ] Record payment → invoice marked paid
- [ ] Completed job appears in customer service history

**Offline:**
- [ ] Disable WiFi → offline banner appears
- [ ] Job list loads from cache
- [ ] Attempting to create job shows "unavailable offline" toast
- [ ] Re-enable WiFi → banner disappears → auto-refresh

---

### S9-T7: `PROGRESS.md` Final Update

```markdown
## 🎉 PROJECT COMPLETE

All 10 sprints completed. App is production-ready.

## Play Store Submission Checklist (Human Action Required)
- [ ] Obtain `google-services.json` from Firebase Console and place at `android/app/google-services.json`
- [ ] Generate release keystore with command in S9-T5
- [ ] Create `android/key.properties` with keystore details
- [ ] Run `flutter build appbundle --release`
- [ ] Upload `app-release.aab` to Google Play Console
- [ ] Add 8 screenshots (from running app on phone)
- [ ] Write store listing description
- [ ] Submit for review

## Phase 2 — React Web Admin
Ready to start. All API endpoints built and tested. See `ProGarage_Flutter_Sprint_Plan.md` for React scope.
```

---

## Cursor Operating Rules — Quick Reference

### When you get stuck:
1. Check `PROGRESS.md` for last known state
2. Run `flutter analyze` to see all current errors
3. Fix errors one file at a time — never chase circular errors across files
4. If a package version conflicts: check `flutter pub outdated`, upgrade conflicting package
5. If codegen fails: `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs`

### After every session:
1. Run `flutter analyze` — fix all issues
2. Run `flutter build apk --debug` — confirm it compiles
3. Update `PROGRESS.md` with completed tasks and "Next Session Pickup" section

### Never do these:
- Never use `dynamic` types in models — always typed
- Never put business logic in widget `build()` methods
- Never call `ref.read()` inside `build()` for watching state (use `ref.watch()`)
- Never use `setState()` in screens that use Riverpod (use `ref.read(provider.notifier).method()`)
- Never add `await` inside `build()` — use `AsyncNotifier` or `FutureProvider`
- Never use `MediaQuery.of(context).size` repeatedly — cache it as a local variable
- Never forget `const` constructors on widgets with no dynamic data

### Code quality checklist for every file:
- [ ] All imports organized (dart: first, package: second, relative third)
- [ ] No unused imports
- [ ] All public methods documented with `///`
- [ ] All `async` methods have proper error handling
- [ ] All `Either<Failure, T>` returns handled at the UI layer
- [ ] No hardcoded strings (use `AppStrings` or `l10n`)
- [ ] No hardcoded colors (use `AppColors`)
- [ ] No hardcoded dimensions (use `AppSizes`)

---

*ProGarage Flutter — Complete AI Development Guide*
*Akshara Technologies · May 2026*
*This document is the single source of truth for the entire development process.*
