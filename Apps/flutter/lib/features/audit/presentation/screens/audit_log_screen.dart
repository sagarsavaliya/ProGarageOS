import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../data/models/audit_models.dart';
import '../providers/audit_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(globalAuditProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Audit log', style: AppTextStyles.titleMedium),
      ),
      body: auditAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
        error: (e, _) => ApiErrorView(
          title: 'Could not load audit log',
          message: e.toString(),
          onRetry: () => ref.invalidate(globalAuditProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text('No audit entries yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: () async => ref.invalidate(globalAuditProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AuditTile(entry: entries[index]),
            ),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('dd MMM · HH:mm').format(entry.createdAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.actionLabel, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${entry.user?.name ?? 'Staff'} · ${entry.targetType}',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(when, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
