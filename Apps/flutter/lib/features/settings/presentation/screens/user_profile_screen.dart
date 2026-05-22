import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Garage owner';
      case 'service_advisor':
        return 'Service advisor';
      case 'technician':
        return 'Technician';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

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
        title: Text('My profile', style: AppTextStyles.titleMedium),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.read(currentUserProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.bgSurface,
                  child: Text(
                    user.initials,
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryOrange),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(user.name, style: AppTextStyles.titleLarge),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _roleLabel(user.role),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 28),
              _InfoTile(
                icon: PhosphorIconsRegular.envelope,
                label: 'Email',
                value: user.email.isNotEmpty ? user.email : '—',
              ),
              _InfoTile(
                icon: PhosphorIconsRegular.phone,
                label: 'Phone',
                value: user.phone ?? '—',
              ),
              if (user.garageName != null)
                _InfoTile(
                  icon: PhosphorIconsRegular.storefront,
                  label: 'Garage',
                  value: user.garageName!,
                ),
              const SizedBox(height: 24),
              _ActionTile(
                icon: PhosphorIconsRegular.lockKey,
                title: 'Change PIN',
                subtitle: 'Verify with WhatsApp OTP',
                onTap: () {
                  final login = (user.phone != null && user.phone!.isNotEmpty)
                      ? user.phone!
                      : user.email;
                  context.push('/auth/staff-pin', extra: {'login': login, 'purpose': 'reset'});
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    Text(subtitle, style: AppTextStyles.bodySmall),
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
