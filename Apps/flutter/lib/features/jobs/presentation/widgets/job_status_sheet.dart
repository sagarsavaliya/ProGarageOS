import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/job_models.dart';

class JobStatusAction {
  final String label;
  final String apiStatus;
  final IconData icon;

  const JobStatusAction({
    required this.label,
    required this.apiStatus,
    required this.icon,
  });
}

List<JobStatusAction> jobStatusActionsFor(JobStatus status) {
  return switch (status) {
    JobStatus.draft => [
        const JobStatusAction(
          label: 'Start intake',
          apiStatus: 'inspecting',
          icon: PhosphorIconsRegular.clipboardText,
        ),
      ],
    JobStatus.intakeInspection => [
        const JobStatusAction(
          label: 'Send for estimate',
          apiStatus: 'estimate_pending',
          icon: PhosphorIconsRegular.paperPlaneTilt,
        ),
      ],
    JobStatus.estimatePending => [
        const JobStatusAction(
          label: 'Customer approved',
          apiStatus: 'estimate_approved',
          icon: PhosphorIconsRegular.checkCircle,
        ),
        const JobStatusAction(
          label: 'Customer rejected',
          apiStatus: 'estimate_rejected',
          icon: PhosphorIconsRegular.xCircle,
        ),
        const JobStatusAction(
          label: 'Put on hold',
          apiStatus: 'on_hold',
          icon: PhosphorIconsRegular.pause,
        ),
      ],
    JobStatus.estimateApproved => [
        const JobStatusAction(
          label: 'Start work',
          apiStatus: 'in_progress',
          icon: PhosphorIconsRegular.wrench,
        ),
      ],
    JobStatus.inProgress => [
        const JobStatusAction(
          label: 'Send to QC',
          apiStatus: 'quality_check',
          icon: PhosphorIconsRegular.sealCheck,
        ),
        const JobStatusAction(
          label: 'Put on hold',
          apiStatus: 'on_hold',
          icon: PhosphorIconsRegular.pause,
        ),
      ],
    JobStatus.qcPending => [
        const JobStatusAction(
          label: 'Ready for delivery',
          apiStatus: 'ready_for_delivery',
          icon: PhosphorIconsRegular.car,
        ),
      ],
    JobStatus.readyForDelivery => [
        const JobStatusAction(
          label: 'Mark delivered',
          apiStatus: 'delivered',
          icon: PhosphorIconsRegular.checkFat,
        ),
      ],
    JobStatus.onHold => [
        const JobStatusAction(
          label: 'Resume work',
          apiStatus: 'in_progress',
          icon: PhosphorIconsRegular.play,
        ),
      ],
    _ => [],
  };
}

Future<void> showJobStatusSheet(
  BuildContext context, {
  required JobStatus current,
  required Future<void> Function(String apiStatus) onSelect,
}) async {
  final actions = jobStatusActionsFor(current);
  if (actions.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Update job status', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text('Current: ${current.label}', style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              ...actions.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    leading: Icon(a.icon, color: AppColors.primaryOrange),
                    title: Text(a.label, style: AppTextStyles.bodyMedium),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      await onSelect(a.apiStatus);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
