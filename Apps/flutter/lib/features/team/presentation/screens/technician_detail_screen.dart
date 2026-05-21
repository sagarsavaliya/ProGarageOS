import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../providers/staff_provider.dart';

class TechnicianDetailScreen extends ConsumerWidget {
  final String staffUuid;

  const TechnicianDetailScreen({super.key, required this.staffUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffDetailProvider(staffUuid));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Team member', style: AppTextStyles.titleMedium),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
        error: (e, _) => ApiErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(staffDetailProvider(staffUuid)),
        ),
        data: (member) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(member.roleLabel, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Phone', value: member.phone),
                  if (member.email != null && member.email!.isNotEmpty)
                    _InfoRow(label: 'Email', value: member.email!),
                  _InfoRow(label: 'Open jobs', value: '${member.openJobs}'),
                  if (member.completedJobs != null)
                    _InfoRow(label: 'Completed jobs', value: '${member.completedJobs}'),
                  _InfoRow(
                    label: 'Availability',
                    value: member.isAvailable ? 'Available' : 'At capacity',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.bodySmall)),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
