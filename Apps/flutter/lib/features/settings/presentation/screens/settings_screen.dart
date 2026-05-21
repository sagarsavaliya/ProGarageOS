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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _apiVersion;
  bool _checkingHealth = false;
  String? _healthError;

  @override
  void initState() {
    super.initState();
    _checkHealth();
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
    await ref.read(secureStorageProvider).clearAll();
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
          _SettingsTile(
            icon: PhosphorIconsRegular.usersThree,
            title: 'Team',
            subtitle: 'Technicians and service advisors',
            onTap: () => context.push('/team'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('App'),
          _SettingsTile(
            icon: PhosphorIconsRegular.bell,
            title: 'Notifications',
            subtitle: 'Job updates and alerts',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Account'),
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
    return Material(
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
    );
  }
}
