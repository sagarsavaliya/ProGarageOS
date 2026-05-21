import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/models/estimate_models.dart';
import '../../data/models/job_models.dart';
import '../providers/job_tasks_provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/vehicle_inspection_provider.dart';
import '../widgets/job_status_sheet.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobUuid;

  const JobDetailScreen({super.key, required this.jobUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobDetailProvider(jobUuid));
    final notifier = ref.read(jobDetailProvider(jobUuid).notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: state.when(
        loading: () => const _LoadingView(),
        error: (err, _) => _ErrorView(onRetry: notifier.refresh),
        data: (detail) => _DetailView(
          jobUuid: jobUuid,
          detail: detail,
          onRefresh: () async {
            await notifier.refresh();
            ref.invalidate(jobTasksProvider(jobUuid));
          },
          onUpdateStatus: notifier.updateStatus,
        ),
      ),
      floatingActionButton: state.maybeWhen(
        data: (detail) {
          if (jobStatusActionsFor(detail.status).isEmpty) return null;
          return FloatingActionButton.extended(
            onPressed: () {
              showJobStatusSheet(
                context,
                current: detail.status,
                onSelect: (s) => notifier.updateStatus(s),
              );
            },
            backgroundColor: AppColors.primaryOrange,
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise, color: Colors.white),
            label: const Text('Update status', style: TextStyle(color: Colors.white)),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail view
// ---------------------------------------------------------------------------

class _DetailView extends ConsumerWidget {
  final String jobUuid;
  final JobDetail detail;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String apiStatus, {String? notes}) onUpdateStatus;

  const _DetailView({
    required this.jobUuid,
    required this.detail,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  bool get _needsIntakeInspection =>
      detail.status == JobStatus.draft ||
      detail.status == JobStatus.intakeInspection;

  bool get _hasCompletedIntake =>
      detail.inspectionSummary['completed'] == true ||
      (detail.inspectionSummary['items'] as List?)?.isNotEmpty == true;

  bool get _showDeliveryPath =>
      detail.status == JobStatus.qcPending || detail.status == JobStatus.readyForDelivery;

  bool get _needsDeliveryInspection => _showDeliveryPath && !detail.deliveryInspectionCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(jobTasksProvider(jobUuid));
    final tasksNotifier = ref.read(jobTasksProvider(jobUuid).notifier);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(),
                if (_needsIntakeInspection) _buildIntakeCta(context),
                if (!_needsIntakeInspection && _hasCompletedIntake)
                  _buildViewIntakeCta(context),
                if (_needsDeliveryInspection) _buildDeliveryCta(context),
                if (!_needsDeliveryInspection && detail.deliveryInspectionCompleted)
                  _buildViewDeliveryCta(context),
                if (_showDeliveryPath)
                  _buildCompareBanner(context, ref.watch(inspectionCompareProvider(jobUuid))),
                _buildVehicleCustomerCard(),
                const SizedBox(height: 16),
                _buildTasksSection(context, ref, tasksState, tasksNotifier),
                if (tasksState.tasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildEstimateCard(context),
                ],
                const SizedBox(height: 16),
                _buildSectionHeader('Billing', null),
                _buildBillingCard(context),
                const SizedBox(height: 16),
                _buildSectionHeader('Timeline', null),
                _buildTimelineCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      backgroundColor: AppColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.jobNumber, style: AppTextStyles.titleMedium),
          Text(
            detail.serviceCategories
                .map((c) => c['name'] as String? ?? '')
                .where((s) => s.isNotEmpty)
                .join(', '),
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/jobs/${detail.uuid}/edit');
          },
          icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.textSecondary, size: 20),
          tooltip: 'Edit job',
        ),
        AppStatusChip(status: detail.status.apiValue),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  Widget _buildIntakeCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryOrangeDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.clipboardText, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Intake inspection pending',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Complete the vehicle condition checklist before estimate',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/jobs/${detail.uuid}/inspection');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Intake Inspection'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusTeal.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.sealCheck, color: AppColors.statusTeal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery inspection required',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.statusTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Record vehicle condition before handover to customer',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push('/jobs/${detail.uuid}/inspection/delivery');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start delivery inspection'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDeliveryCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/jobs/${detail.uuid}/inspection/delivery');
        },
        icon: const Icon(PhosphorIconsRegular.sealCheck, size: 18),
        label: const Text('View delivery inspection'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.statusTeal,
          side: const BorderSide(color: AppColors.statusTeal),
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCompareBanner(BuildContext context, AsyncValue<InspectionCompareResult> compareAsync) {
    return compareAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (!result.hasNewDamage) return const SizedBox.shrink();
        final items = result.newDamage;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.statusRedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusRed.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsRegular.warning, color: AppColors.statusRed, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'New damage since intake',
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.statusRed),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.componentName}: ${item.intakeStatus} → ${item.deliveryStatus}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
              if (items.length > 3)
                Text('+ ${items.length - 3} more', style: AppTextStyles.labelSmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstimateCard(BuildContext context) {
    final approval = detail.estimateSummary['approval_status'] as String? ??
        detail.billingSummary['approval_status'] as String? ??
        'pending';
    final amount = (detail.estimateSummary['estimated_amount'] as num?)?.toDouble() ??
        (detail.billingSummary['estimated_amount'] as num?)?.toDouble() ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Estimate', null),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${_formatAmount(amount)}', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      switch (approval) {
                        'approved' => 'Approved',
                        'rejected' => 'Rejected',
                        _ => 'Pending approval',
                      },
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/jobs/${detail.uuid}/estimate'),
                child: Text(
                  'Open estimate',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewIntakeCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/jobs/${detail.uuid}/inspection');
        },
        icon: const Icon(PhosphorIconsRegular.images, size: 18),
        label: const Text('View intake inspection'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          side: const BorderSide(color: AppColors.primaryOrange),
          minimumSize: const Size.fromHeight(42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    // Only show if a special condition exists (e.g. estimate pending, ready for delivery)
    if (detail.status != JobStatus.estimatePending &&
        detail.status != JobStatus.readyForDelivery &&
        detail.status != JobStatus.qcPending) {
      return const SizedBox.shrink();
    }

    final (color, icon, message) = switch (detail.status) {
      JobStatus.estimatePending => (
          AppColors.statusOrange,
          PhosphorIconsRegular.clockCounterClockwise,
          'Estimate sent to customer — awaiting approval'
        ),
      JobStatus.readyForDelivery => (
          AppColors.statusGreen,
          PhosphorIconsRegular.checkCircle,
          'Vehicle is ready for customer pickup'
        ),
      JobStatus.qcPending => (
          AppColors.statusTeal,
          PhosphorIconsRegular.sealCheck,
          'Quality check in progress'
        ),
      _ => (AppColors.textSecondary, PhosphorIconsRegular.info, ''),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: color))),
        ],
      ),
    );
  }

  Widget _buildVehicleCustomerCard() {
    final vehicle = detail.vehicle;
    final customer = detail.customer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIconsRegular.car, color: AppColors.textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.makeModel, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.registrationNumber,
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Fuel type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vehicle.fuelType.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          // Compliance alerts
          if (vehicle.complianceAlerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusRedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.warning, color: AppColors.statusRed, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${vehicle.complianceAlerts.join(', ').toUpperCase()} expired',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusRed),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Customer row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrangeDim,
                ),
                child: Center(
                  child: Text(
                    _initials(customer.name),
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTextStyles.titleSmall),
                    Text(customer.phone, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (customer.loyaltyPoints > 0)
                Row(
                  children: [
                    Icon(PhosphorIconsFill.star, color: AppColors.statusOrange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${customer.loyaltyPoints} pts',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusOrange),
                    ),
                  ],
                ),
              IconButton(
                onPressed: () {},
                icon: Icon(PhosphorIconsRegular.phone, color: AppColors.primaryOrange, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          // Technician + bay
          if (detail.primaryTechnician != null || detail.serviceBay != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                if (detail.primaryTechnician != null) ...[
                  Icon(PhosphorIconsRegular.userGear, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(detail.primaryTechnician!.name, style: AppTextStyles.bodySmall),
                ],
                const Spacer(),
                if (detail.serviceBay != null) ...[
                  Icon(PhosphorIconsRegular.wrench, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(detail.serviceBay!.name, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? badge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(badge, style: AppTextStyles.labelSmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTasksSection(
    BuildContext context,
    WidgetRef ref,
    JobTasksState tasksState,
    JobTasksNotifier tasksNotifier,
  ) {
    final tasks = tasksState.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('Tasks', style: AppTextStyles.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text('${tasks.length}', style: AppTextStyles.labelSmall),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: tasksState.isMutating ? null : () => _showAddTaskDialog(context, tasksNotifier),
                icon: const Icon(PhosphorIconsRegular.plus, size: 16, color: AppColors.primaryOrange),
                label: Text(
                  'Add',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange),
                ),
              ),
            ],
          ),
        ),
        if (tasksState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(color: AppColors.primaryOrange, minHeight: 2),
          )
        else if (tasksState.error != null && tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(tasksState.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed)),
          )
        else if (tasks.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text('No tasks yet', style: AppTextStyles.bodySmall)),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: tasks.asMap().entries.map((entry) {
                final isLast = entry.key == tasks.length - 1;
                return _TaskRow(
                  task: entry.value,
                  isLast: isLast,
                  onComplete: entry.value.status == 'completed' || tasksState.isMutating
                      ? null
                      : () => tasksNotifier.completeTask(entry.value),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, JobTasksNotifier notifier) async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Add task', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Task name',
            hintStyle: AppTextStyles.bodySmall,
          ),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Add', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryOrange)),
          ),
        ],
      ),
    );
    if (added == true && context.mounted) {
      await notifier.addTask(controller.text);
    }
    controller.dispose();
  }

  Widget _buildBillingCard(BuildContext context) {
    final billing = detail.billingSummary;
    final estimated = (billing['estimated_amount'] as num?)?.toDouble() ?? 0;
    final approval = billing['approval_status'] as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Total', style: AppTextStyles.bodyMedium),
              Text(
                '₹${_formatAmount(estimated)}',
                style: GoogleFonts.dmMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Customer Approval', style: AppTextStyles.bodySmall),
              AppStatusChip(status: approval == 'approved' ? 'completed' : 'estimate_pending'),
            ],
          ),
          if (billing['invoice_uuid'] != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/invoices/${billing['invoice_uuid']}'),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.receipt, color: AppColors.primaryOrange, size: 16),
                  const SizedBox(width: 8),
                  Text('View Invoice', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange)),
                ],
              ),
            ),
          ] else if (detail.status == JobStatus.estimateApproved ||
              detail.status == JobStatus.inProgress ||
              detail.status == JobStatus.readyForDelivery) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.push('/invoices/add', extra: {'jobUuid': jobUuid}),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.plusCircle, color: AppColors.primaryOrange, size: 16),
                  const SizedBox(width: 8),
                  Text('Create invoice', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final tl = detail.timeline;
    final fmt = DateFormat('d MMM, h:mm a');

    DateTime? parse(String? s) => s != null ? DateTime.tryParse(s) : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _TimelineRow(
            icon: PhosphorIconsRegular.clock,
            label: 'Scheduled Start',
            value: parse(tl['scheduled_start_at'] as String?),
            fmt: fmt,
          ),
          _TimelineRow(
            icon: PhosphorIconsRegular.playCircle,
            label: 'Actual Start',
            value: parse(tl['actual_start_at'] as String?),
            fmt: fmt,
          ),
          _TimelineRow(
            icon: PhosphorIconsRegular.timer,
            label: 'Est. Completion',
            value: parse(tl['estimated_completion_at'] as String?),
            fmt: fmt,
          ),
          _TimelineRow(
            icon: PhosphorIconsRegular.checkCircle,
            label: 'Completed',
            value: parse(tl['actual_completion_at'] as String?),
            fmt: fmt,
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  String _formatAmount(double amount) {
    final f = NumberFormat('#,##,##0', 'en_IN');
    return f.format(amount.toInt());
  }
}

// ---------------------------------------------------------------------------
// Task row widget
// ---------------------------------------------------------------------------

class _TaskRow extends StatelessWidget {
  final TaskItem task;
  final bool isLast;
  final VoidCallback? onComplete;

  const _TaskRow({required this.task, required this.isLast, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusIcon) = _statusStyle(task.status);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(task.name, style: AppTextStyles.titleSmall)),
                        if (task.source == 'discovered')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusOrangeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DISCOVERED',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.statusOrange,
                                fontSize: 8,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${task.estimatedPrice.toInt()}',
                          style: AppTextStyles.monoSmall.copyWith(color: AppColors.textPrimary),
                        ),
                        if (task.laborMinutes != null) ...[
                          const SizedBox(width: 10),
                          Icon(PhosphorIconsRegular.clock, color: AppColors.textMuted, size: 11),
                          const SizedBox(width: 3),
                          Text('${task.laborMinutes}m', style: AppTextStyles.labelSmall),
                        ],
                        const Spacer(),
                        if (onComplete != null)
                          TextButton(
                            onPressed: onComplete,
                            child: Text(
                              'Complete',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusGreen),
                            ),
                          ),
                        if (task.requiresCustomerApproval)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusBlueBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AWAITING APPROVAL',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.statusBlue,
                                fontSize: 8,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (task.assignedTechnician != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(PhosphorIconsRegular.userGear, color: AppColors.textMuted, size: 12),
                          const SizedBox(width: 4),
                          Text(task.assignedTechnician!.name, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
      ],
    );
  }

  (Color, PhosphorIconData) _statusStyle(String status) {
    switch (status) {
      case 'completed':
        return (AppColors.statusGreen, PhosphorIconsFill.checkCircle);
      case 'in_progress':
        return (AppColors.primaryOrange, PhosphorIconsFill.playCircle);
      case 'pending_approval':
        return (AppColors.statusOrange, PhosphorIconsRegular.hourglass);
      default:
        return (AppColors.textMuted, PhosphorIconsRegular.circle);
    }
  }
}

// ---------------------------------------------------------------------------
// Timeline row widget
// ---------------------------------------------------------------------------

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? value;
  final DateFormat fmt;
  final bool isLast;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fmt,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: value != null ? AppColors.primaryOrange : AppColors.textMuted, size: 16),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodySmall),
              const Spacer(),
              Text(
                value != null ? fmt.format(value!.toLocal()) : '—',
                style: value != null
                    ? AppTextStyles.monoSmall.copyWith(color: AppColors.textPrimary)
                    : AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading + error views
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ApiErrorView(
      title: 'Could not load job',
      message: 'Check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

