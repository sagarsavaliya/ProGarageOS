import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/staff_pin_otp_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/jobs/presentation/screens/jobs_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/create_job_screen.dart';
import '../../features/jobs/presentation/screens/vehicle_inspection_screen.dart';
import '../../features/jobs/presentation/screens/estimate_screen.dart';
import '../../features/team/presentation/screens/technicians_screen.dart';
import '../../features/team/presentation/screens/technician_detail_screen.dart';
import '../../features/team/presentation/screens/add_technician_screen.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/presentation/screens/add_customer_screen.dart';
import '../../features/customers/presentation/screens/add_vehicle_screen.dart';
import '../../features/customers/presentation/screens/edit_customer_screen.dart';
import '../../features/customers/presentation/screens/edit_vehicle_screen.dart';
import '../../features/jobs/presentation/screens/edit_job_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_screen.dart';
import '../../features/vehicles/presentation/screens/vehicle_detail_screen.dart';
import '../../features/invoices/presentation/screens/invoices_screen.dart';
import '../../features/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../features/invoices/presentation/screens/create_invoice_screen.dart';
import '../../features/inventory/presentation/screens/add_part_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/inventory_detail_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/payments/presentation/screens/payments_hub_screen.dart';
import '../../features/onboarding/presentation/screens/garage_setup_wizard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/garage_profile_screen.dart';
import '../../features/settings/presentation/screens/integrations_screen.dart';
import '../../features/settings/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/user_profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

part 'app_router.g.dart';

/// Root navigator — detail routes push above the tab shell.
final rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final secureStorage = ref.watch(secureStorageProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final isSplash = state.matchedLocation == '/';
      if (isSplash) return null; // Splash handles its own navigation
      final hasToken = await secureStorage.hasToken();
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      if (!hasToken && !isAuthRoute && !isOnboardingRoute && state.matchedLocation != '/') {
        return '/auth/login';
      }
      if (hasToken && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/setup',
        name: 'garage-setup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GarageSetupWizardScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/auth/staff-pin',
        name: 'staff-pin',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final query = state.uri.queryParameters;
          return StaffPinOtpScreen(
            login: extra['login'] as String? ?? query['login'] ?? '',
            purpose: extra['purpose'] as String? ?? query['purpose'] ?? 'reset',
          );
        },
      ),
      // Shell wraps ONLY the tab screens — detail screens are outside to hide bottom nav.
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/jobs',
            name: 'jobs',
            builder: (context, state) => const JobsScreen(),
          ),
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            builder: (context, state) => const PaymentsHubScreen(),
          ),
          GoRoute(
            path: '/team',
            name: 'team-tab',
            builder: (context, state) => const TechniciansScreen(showBackButton: false),
          ),
          GoRoute(
            path: '/vehicles',
            name: 'vehicles',
            builder: (context, state) => const VehiclesScreen(),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/invoices',
            name: 'invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
        ],
      ),
      // Detail screens — full screen, no bottom nav
      GoRoute(
        path: '/jobs/add',
        name: 'job-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateJobScreen(),
      ),
      GoRoute(
        path: '/jobs/:id/inspection/delivery',
        name: 'job-inspection-delivery',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VehicleInspectionScreen(jobUuid: id, phase: 'delivery');
        },
      ),
      GoRoute(
        path: '/jobs/:id/inspection',
        name: 'job-inspection',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return VehicleInspectionScreen(jobUuid: id, phase: 'intake');
        },
      ),
      GoRoute(
        path: '/jobs/:id/estimate',
        name: 'job-estimate',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EstimateScreen(jobUuid: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id/edit',
        name: 'job-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditJobScreen(jobUuid: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id',
        name: 'job-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JobDetailScreen(jobUuid: id);
        },
      ),
      GoRoute(
        path: '/customers/add',
        name: 'customer-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/vehicle/add',
        name: 'vehicle-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AddVehicleScreen(
            customerUuid: extra['customerUuid'] as String? ?? '',
            customerName: extra['customerName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/customers/:id/edit',
        name: 'customer-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditCustomerScreen(customerUuid: id);
        },
      ),
      GoRoute(
        path: '/customers/:id',
        name: 'customer-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomerDetailScreen(customerUuid: id);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        name: 'vehicle-edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EditVehicleScreen(
            vehicleUuid: id,
            customerUuid: extra['customerUuid'] as String? ?? extra['customer'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/vehicles/:id',
        name: 'vehicle-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final customerUuid = extra?['customer'] as String? ?? '';
          return VehicleDetailScreen(vehicleUuid: id, customerUuid: customerUuid);
        },
      ),
      GoRoute(
        path: '/invoices/add',
        name: 'invoice-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateInvoiceScreen(jobUuid: extra?['jobUuid'] as String?);
        },
      ),
      GoRoute(
        path: '/invoices/:id',
        name: 'invoice-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InvoiceDetailScreen(invoiceUuid: id);
        },
      ),
      // Stub: add part screen (coming soon) — must be before /:id to avoid capture
      GoRoute(
        path: '/inventory/add',
        name: 'inventory-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddPartScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        name: 'inventory-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InventoryDetailScreen(itemUuid: id);
        },
      ),
      GoRoute(
        path: '/team/add',
        name: 'team-add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddTechnicianScreen(),
      ),
      GoRoute(
        path: '/team/:id',
        name: 'team-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TechnicianDetailScreen(staffUuid: id);
        },
      ),
      GoRoute(
        path: '/team',
        name: 'team',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TechniciansScreen(),
      ),
      GoRoute(
        path: '/settings/garage-profile',
        name: 'garage-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GarageProfileScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        name: 'user-profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/settings/integrations',
        name: 'integrations',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const IntegrationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// App shell with bottom navigation
// ---------------------------------------------------------------------------

class ScaffoldWithNav extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<ScaffoldWithNav> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentUserProvider.notifier).refresh();
    });
  }

  List<String> _tabs(bool isTechnician, bool showTeam, bool showPayments) {
    if (isTechnician) {
      return const ['/dashboard', '/jobs', '/appointments', '/customers', '/inventory'];
    }
    if (showTeam && showPayments) {
      return const ['/dashboard', '/jobs', '/appointments', '/payments', '/team'];
    }
    if (showPayments) {
      return const ['/dashboard', '/jobs', '/appointments', '/payments', '/customers'];
    }
    return const ['/dashboard', '/jobs', '/appointments', '/customers', '/inventory'];
  }

  int _locationToIndex(String location, List<String> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isTechnician = ref.watch(isTechnicianProvider);
    final showTeam = ref.watch(showTeamTabProvider);
    final showPayments = ref.watch(showPaymentsTabProvider);
    final tabs = _tabs(isTechnician, showTeam, showPayments);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location, tabs);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: widget.child,
        bottomNavigationBar: Container(
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: PhosphorIconsRegular.squaresFour,
                activeIcon: PhosphorIconsFill.squaresFour,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/dashboard');
                },
              ),
              _NavItem(
                icon: PhosphorIconsRegular.clipboardText,
                activeIcon: PhosphorIconsFill.clipboardText,
                label: 'Jobs',
                isActive: currentIndex == 1,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/jobs');
                },
              ),
              _NavItem(
                icon: PhosphorIconsRegular.calendarBlank,
                activeIcon: PhosphorIconsFill.calendarBlank,
                label: 'Appts',
                isActive: currentIndex == 2,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/appointments');
                },
              ),
              if (showPayments && !isTechnician)
                _NavItem(
                  icon: PhosphorIconsRegular.currencyInr,
                  activeIcon: PhosphorIconsFill.currencyInr,
                  label: 'Pay',
                  isActive: currentIndex == 3,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/payments');
                  },
                ),
              if (showTeam && !isTechnician)
                _NavItem(
                  icon: PhosphorIconsRegular.usersThree,
                  activeIcon: PhosphorIconsFill.usersThree,
                  label: 'Team',
                  isActive: currentIndex == 4,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/team');
                  },
                ),
              if (isTechnician)
                _NavItem(
                  icon: PhosphorIconsRegular.users,
                  activeIcon: PhosphorIconsFill.users,
                  label: 'Customers',
                  isActive: currentIndex == 3,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/customers');
                  },
                ),
              if (isTechnician)
                _NavItem(
                  icon: PhosphorIconsRegular.package,
                  activeIcon: PhosphorIconsFill.package,
                  label: 'Parts',
                  isActive: currentIndex == 4,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/inventory');
                  },
                ),
              if (!isTechnician && !showTeam && showPayments)
                _NavItem(
                  icon: PhosphorIconsRegular.users,
                  activeIcon: PhosphorIconsFill.users,
                  label: 'Customers',
                  isActive: currentIndex == 4,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/customers');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? AppColors.primaryOrange : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.primaryOrange : AppColors.textMuted,
                  letterSpacing: 0.03 * 9,
                ),
              ),
              const SizedBox(height: 3),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

