import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/config/env.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/tenant_repository.dart';
import '../widgets/gps_tracking_info_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _apiVersion;
  bool _checkingHealth = false;
  String? _healthError;
  bool _gpsDefaultEnabled = false;
  bool _gpsPrefLoaded = false;
  bool? _garageSetupDone;

  @override
  void initState() {
    super.initState();
    _checkHealth();
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    final storage = ref.read(secureStorageProvider);
    final gps = await storage.isGpsDefaultConsentEnabled();
    final user = ref.read(currentUserProvider).valueOrNull;
    bool? setupDone;
    if (ref.read(isOwnerProvider) && user?.tenantUuid != null) {
      setupDone = await resolveGarageSetupComplete(
        tenantRepo: ref.read(tenantRepositoryProvider),
        storage: storage,
        tenantUuid: user!.tenantUuid!,
      );
    } else if (user?.tenantUuid != null) {
      setupDone = await storage.isGarageSetupCompleted(user!.tenantUuid!);
    }
    if (mounted) {
      setState(() {
        _gpsDefaultEnabled = gps;
        _gpsPrefLoaded = true;
        _garageSetupDone = setupDone;
      });
    }
  }

  Future<void> _checkHealth() async {
    setState(() {
      _checkingHealth = true;
      _healthError = null;
    });
    try {
      final dio = Dio(BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Accept': 'application/json'},
      ));
      final response = await dio.get('/health');
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _apiVersion = data['version'] as String? ?? '—';
        _checkingHealth = false;
      });
    } catch (e) {
      setState(() {
        _healthError = failureMessage(e);
        _checkingHealth = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Sign out?', style: AppTextStyles.titleMedium),
        content: Text(
          'You will need your PIN to sign in again.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out', style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Local sign-out even if API fails.
    }
    await ref.read(secureStorageProvider).clearSession();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Settings', style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileHeader(
            onTap: () => context.push('/settings/profile'),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Connection'),
          _SettingsTile(
            icon: PhosphorIconsRegular.globe,
            title: 'API server',
            subtitle: Env.apiBaseUrl,
            onTap: () {
              Clipboard.setData(ClipboardData(text: Env.apiBaseUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API URL copied')),
              );
            },
          ),
          _SettingsTile(
            icon: PhosphorIconsRegular.image,
            title: 'Media base URL',
            subtitle: Env.mediaBaseUrl,
          ),
          _SettingsTile(
            icon: PhosphorIconsRegular.pulse,
            title: 'API health',
            subtitle: _checkingHealth
                ? 'Checking…'
                : _healthError != null
                    ? _healthError!
                    : 'Version $_apiVersion · ProGarageOS',
            trailing: _healthError != null
                ? IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18),
                    onPressed: _checkHealth,
                  )
                : null,
          ),
          if (_healthError != null) ...[
            const SizedBox(height: 8),
            ApiErrorView(
              title: 'Server unreachable',
              message: _healthError!,
              onRetry: _checkHealth,
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle('Garage'),
          if (ref.watch(isOwnerProvider)) ...[
            if (_garageSetupDone == false)
              _SettingsTile(
                icon: PhosphorIconsRegular.flag,
                title: 'Complete setup',
                subtitle: 'Finish garage profile and bays',
                onTap: () => context.push('/onboarding/setup'),
              ),
            _SettingsTile(
              icon: PhosphorIconsRegular.storefront,
              title: 'Garage profile',
              subtitle: 'Business name, GSTIN, address for invoices',
              onTap: () => context.push('/settings/garage-profile'),
            ),
            _SettingsTile(
              icon: PhosphorIconsRegular.car,
              title: 'Fleet',
              subtitle: 'All registered vehicles',
              onTap: () => context.go('/vehicles'),
            ),
            _SettingsTile(
              icon: PhosphorIconsRegular.users,
              title: 'Customers',
              subtitle: 'Customer and vehicle records',
              onTap: () => context.go('/customers'),
            ),
            _SettingsTile(
              icon: PhosphorIconsRegular.receipt,
              title: 'Invoices',
              subtitle: 'All invoices and billing history',
              onTap: () => context.go('/invoices'),
            ),
            _SettingsTile(
              icon: PhosphorIconsRegular.package,
              title: 'Parts inventory',
              subtitle: 'Stock levels and low-stock alerts',
              onTap: () => context.go('/inventory'),
            ),
            _SettingsTile(
              icon: PhosphorIconsRegular.plugsConnected,
              title: 'Integrations',
              subtitle: 'WhatsApp and connected services',
              onTap: () => context.push('/settings/integrations'),
            ),
          ],
          _SettingsTile(
            icon: PhosphorIconsRegular.usersThree,
            title: 'Team',
            subtitle: 'Technicians and service advisors',
            onTap: () => context.go('/team'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('App'),
          _SettingsTile(
            icon: PhosphorIconsRegular.mapPinLine,
            title: 'GPS odometer tracking',
            subtitle: 'Default consent for new vehicles',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.info, size: 18, color: AppColors.textMuted),
                  onPressed: () => GpsTrackingInfoSheet.show(context),
                ),
                if (_gpsPrefLoaded)
                  Switch.adaptive(
                    value: _gpsDefaultEnabled,
                    activeColor: AppColors.primaryOrange,
                    onChanged: (v) async {
                      setState(() => _gpsDefaultEnabled = v);
                      await ref.read(secureStorageProvider).setGpsDefaultConsentEnabled(v);
                    },
                  ),
              ],
            ),
          ),
          _SettingsTile(
            icon: PhosphorIconsRegular.bell,
            title: 'Notifications',
            subtitle: 'Job updates and alerts',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Account'),
          _SettingsTile(
            icon: PhosphorIconsRegular.user,
            title: 'My profile',
            subtitle: 'Name, role, change PIN',
            onTap: () => context.push('/settings/profile'),
          ),
          _SettingsTile(
            icon: PhosphorIconsRegular.signOut,
            title: 'Sign out',
            subtitle: 'End session on this device',
            titleColor: AppColors.statusRed,
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final VoidCallback onTap;

  const _ProfileHeader({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.bgPrimary,
                child: Text(
                  user?.initials ?? '?',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryOrange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Staff member', style: AppTextStyles.titleSmall),
                    Text(
                      user?.garageName ?? 'Tap to view profile',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.08 * 11,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 2),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
      ),
    );
  }
}
