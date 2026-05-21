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
import '../../../../core/widgets/app_button.dart';
import '../../data/models/estimate_models.dart';
import '../providers/estimate_provider.dart';
import '../providers/jobs_provider.dart';

class EstimateScreen extends ConsumerWidget {
  final String jobUuid;

  const EstimateScreen({super.key, required this.jobUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(estimateProvider(jobUuid));
    final notifier = ref.read(estimateProvider(jobUuid).notifier);
    final detail = ref.watch(jobDetailProvider(jobUuid)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimate', style: AppTextStyles.titleMedium),
            if (detail != null)
              Text(detail.jobNumber, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
      body: _buildBody(context, ref, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    EstimateState state,
    EstimateNotifier notifier,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
      );
    }

    if (state.errorMessage != null) {
      return ApiErrorView(message: state.errorMessage!, onRetry: notifier.load);
    }

    final estimate = state.estimate;
    if (estimate == null || estimate.lines.isEmpty) {
      return ApiErrorView(
        title: 'No estimate lines',
        message: 'Add tasks on the job before building an estimate.',
        icon: PhosphorIconsRegular.clipboardText,
      );
    }

    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _ApprovalBanner(approvalStatus: estimate.approvalStatus, jobStatus: estimate.status),
              if (state.actionError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.actionError!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
                ),
              ],
              const SizedBox(height: 12),
              ...estimate.lines.map((line) => _LineCard(
                    line: line,
                    price: state.linePrice(line),
                    onPriceChanged: (v) => notifier.setLinePrice(line.id, v),
                    enabled: !state.isSaving && !state.isSending,
                  )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: AppTextStyles.titleSmall),
                    Text(
                      '₹${fmt.format(state.subtotal.toInt())}',
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.hasChanges)
                  AppButton(
                    label: state.isSaving ? 'Saving…' : 'Save changes',
                    onPressed: state.isSaving ? null : () => notifier.save(),
                  ),
                if (estimate.approvalStatus != 'approved') ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label: state.isSending ? 'Sending…' : 'Send to customer',
                    onPressed: state.isSending
                        ? null
                        : () async {
                            final ok = await notifier.send();
                            if (ok && context.mounted) {
                              ref.invalidate(jobDetailProvider(jobUuid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estimate sent for approval')),
                              );
                            }
                          },
                  ),
                ],
                if (estimate.approvalStatus == 'pending' &&
                    estimate.status == 'estimate_pending') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Approve',
                          variant: AppButtonVariant.outlined,
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                  final ok = await notifier.approve();
                                  if (ok && context.mounted) {
                                    ref.invalidate(jobDetailProvider(jobUuid));
                                    context.pop();
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Reject',
                          variant: AppButtonVariant.outlined,
                          onPressed: state.isSaving
                              ? null
                              : () => _showRejectDialog(context, ref, notifier),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    EstimateNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Reject estimate', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reject', style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await notifier.reject(controller.text.trim());
      if (ok && context.mounted) {
        ref.invalidate(jobDetailProvider(jobUuid));
        context.pop();
      }
    }
    controller.dispose();
  }
}

class _ApprovalBanner extends StatelessWidget {
  final String approvalStatus;
  final String jobStatus;

  const _ApprovalBanner({required this.approvalStatus, required this.jobStatus});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (approvalStatus) {
      'approved' => (AppColors.statusGreen, 'Approved by customer'),
      'rejected' => (AppColors.statusRed, 'Rejected'),
      _ => (AppColors.statusOrange, 'Awaiting customer approval'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.receipt, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color))),
        ],
      ),
    );
  }
}

class _LineCard extends StatefulWidget {
  final EstimateLine line;
  final double price;
  final ValueChanged<double> onPriceChanged;
  final bool enabled;

  const _LineCard({
    required this.line,
    required this.price,
    required this.onPriceChanged,
    required this.enabled,
  });

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.price.toInt().toString());
  }

  @override
  void didUpdateWidget(covariant _LineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price && _controller.text != widget.price.toInt().toString()) {
      _controller.text = widget.price.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.line.name, style: AppTextStyles.titleSmall),
          if (widget.line.requiresCustomerApproval) ...[
            const SizedBox(height: 4),
            Text(
              'Requires customer approval',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusBlue),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            enabled: widget.enabled && widget.line.isBillable,
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Price (₹)',
              prefixText: '₹ ',
              filled: true,
              fillColor: AppColors.bgElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
              widget.onPriceChanged(parsed);
            },
          ),
        ],
      ),
    );
  }
}
