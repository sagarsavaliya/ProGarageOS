import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/models/job_models.dart';
import '../providers/edit_job_provider.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  final String jobUuid;

  const EditJobScreen({super.key, required this.jobUuid});

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  final _complaintController = TextEditingController();
  bool _bound = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  void _bind(EditJobState state) {
    if (_bound || state.job == null) return;
    _complaintController.text = state.complaint;
    _bound = true;
  }

  Future<void> _pickSchedule(EditJobNotifier notifier, EditJobState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate: state.scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: state.scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) notifier.setSchedule(date, time);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editJobProvider(widget.jobUuid));
    final notifier = ref.read(editJobProvider(widget.jobUuid).notifier);
    _bind(state);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          title: Text('Edit Job', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
      );
    }

    final job = state.job;
    if (job == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgSurface),
        body: Center(
          child: Text(state.errorMessage ?? 'Could not load job', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    final canEditDelivered = ref.watch(canEditDeliveredJobProvider);
    if (job.status == JobStatus.delivered && !canEditDelivered) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textSecondary, size: 20),
          ),
          title: Text('Edit Job', style: AppTextStyles.titleMedium),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.lock, color: AppColors.textMuted, size: 40),
                const SizedBox(height: 16),
                Text('Job is delivered', style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'This job is read-only. Only the owner can edit after delivery.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Go back', onPressed: () => context.pop()),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textSecondary, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Job', style: AppTextStyles.titleMedium),
            Text(job.jobNumber, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _sectionLabel('Customer complaint'),
                TextField(
                  controller: _complaintController,
                  onChanged: notifier.setComplaint,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('Describe the issue…'),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Priority'),
                Wrap(
                  spacing: 8,
                  children: ['normal', 'urgent', 'vip'].map((p) {
                    final selected = state.priority == p;
                    return ChoiceChip(
                      label: Text(p.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => notifier.setPriority(p),
                      selectedColor: AppColors.primaryOrangeDim,
                      side: BorderSide(
                        color: selected ? AppColors.primaryOrange : AppColors.divider,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Service bay'),
                if (state.isLoadingResources)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(color: AppColors.primaryOrange, minHeight: 2),
                  )
                else
                  ...state.bays.map((bay) {
                    final selected = state.selectedBayUuid == bay.uuid;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(bay.name, style: AppTextStyles.bodyMedium),
                      subtitle: Text(bay.type, style: AppTextStyles.labelSmall),
                      trailing: selected
                          ? const Icon(PhosphorIconsRegular.check, color: AppColors.primaryOrange)
                          : null,
                      enabled: bay.isSelectable,
                      onTap: bay.isSelectable
                          ? () {
                              HapticFeedback.selectionClick();
                              notifier.selectBay(bay.uuid);
                            }
                          : null,
                    );
                  }),
                const SizedBox(height: 12),
                _sectionLabel('Technician'),
                ...state.technicians.map((tech) {
                  final selected = state.selectedTechnicianUuid == tech.uuid;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(tech.name, style: AppTextStyles.bodyMedium),
                    subtitle: Text(tech.specialty, style: AppTextStyles.labelSmall),
                    trailing: selected
                        ? const Icon(PhosphorIconsRegular.check, color: AppColors.primaryOrange)
                        : null,
                    enabled: tech.isAvailable,
                    onTap: tech.isAvailable
                        ? () {
                            HapticFeedback.selectionClick();
                            notifier.selectTechnician(tech.uuid);
                          }
                        : null,
                  );
                }),
                const SizedBox(height: 12),
                _sectionLabel('Schedule'),
                OutlinedButton.icon(
                  onPressed: () => _pickSchedule(notifier, state),
                  icon: const Icon(PhosphorIconsRegular.calendar, size: 18),
                  label: Text(
                    state.scheduledDate != null && state.scheduledTime != null
                        ? '${state.scheduledDate!.day}/${state.scheduledDate!.month}/${state.scheduledDate!.year} · ${state.scheduledTime!.format(context)}'
                        : 'Set date & time',
                    style: AppTextStyles.bodySmall,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: const BorderSide(color: AppColors.divider),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: AppButton(
              label: 'Save changes',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final ok = await notifier.submit();
                      if (ok && mounted) context.pop();
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.08),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bgSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryOrange),
      ),
    );
  }
}
