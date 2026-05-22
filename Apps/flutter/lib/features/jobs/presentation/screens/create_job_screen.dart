import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../customers/data/models/customer_models.dart';
import '../providers/create_job_provider.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _searchController = TextEditingController();
  final _complaintController = TextEditingController();
  final _odometerController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _complaintController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createJobProvider);
    final notifier = ref.read(createJobProvider.notifier);

    if (state.isSuccess && state.createdJob != null) {
      return _SuccessView(
        jobNumber: state.createdJob!.jobNumber,
        jobUuid: state.createdJob!.uuid,
        onViewJob: () => context.go('/jobs/${state.createdJob!.uuid}'),
        onStartInspection: () =>
            context.push('/jobs/${state.createdJob!.uuid}/inspection'),
        onDone: () => context.pop(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(
              step: state.step,
              onClose: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
            _StepIndicator(currentStep: state.step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: switch (state.step) {
                  0 => _Step1CustomerVehicle(
                      key: const ValueKey('step1'),
                      state: state,
                      searchController: _searchController,
                      complaintController: _complaintController,
                      odometerController: _odometerController,
                      onSearch: notifier.searchCustomers,
                      onSelectCustomer: notifier.selectCustomer,
                      onClearCustomer: notifier.clearCustomer,
                      onSelectVehicle: notifier.selectVehicle,
                      onComplaint: notifier.setComplaint,
                      onOdometer: notifier.setOdometer,
                      onFuel: notifier.setFuelLevel,
                    ),
                  1 => _Step2Services(
                      key: const ValueKey('step2'),
                      categories: state.serviceCategories,
                      isLoadingCategories: state.isLoadingCategories,
                      selectedIds: state.selectedCategoryIds,
                      fuelLevel: state.fuelLevel,
                      showInsuranceFields: state.isInsuranceJobSelected,
                      insuranceCompany: state.insuranceCompany,
                      claimNumber: state.claimNumber,
                      onToggle: notifier.toggleCategory,
                      onFuel: notifier.setFuelLevel,
                      onInsuranceCompany: notifier.setInsuranceCompany,
                      onClaimNumber: notifier.setClaimNumber,
                    ),
                  _ => _Step3Assign(
                      key: const ValueKey('step3'),
                      state: state,
                      onPriority: notifier.setPriority,
                      onBay: notifier.selectBay,
                      onTech: notifier.selectTechnician,
                      onSchedule: () => _pickSchedule(context, notifier),
                    ),
                },
              ),
            ),
            _WizardFooter(
              step: state.step,
              isSubmitting: state.isSubmitting,
              canNext: switch (state.step) {
                0 => state.step1Valid,
                1 => state.step2Valid,
                _ => state.step3Valid,
              },
              onBack: () {
                HapticFeedback.selectionClick();
                notifier.prevStep();
              },
              onNext: () async {
                HapticFeedback.mediumImpact();
                if (state.step < 2) {
                  notifier.nextStep();
                } else {
                  await notifier.submit();
                }
              },
              errorMessage: state.errorMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSchedule(BuildContext context, CreateJobNotifier notifier) async {
    final state = ref.read(createJobProvider);
    final date = await showDatePicker(
      context: context,
      initialDate: state.scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: state.scheduledTime ?? TimeOfDay.now(),
    );
    if (time != null) notifier.setSchedule(date, time);
  }
}

// ---------------------------------------------------------------------------
// Header + step indicator
// ---------------------------------------------------------------------------

class _WizardHeader extends StatelessWidget {
  final int step;
  final VoidCallback onClose;

  const _WizardHeader({required this.step, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(PhosphorIconsRegular.x, color: AppColors.textSecondary, size: 20),
          ),
          Expanded(
            child: Text('New Job', style: AppTextStyles.titleMedium),
          ),
          Text(
            'Step ${step + 1} of 3',
            style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.04),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  static const _labels = ['Customer', 'Services', 'Assign'];

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSurface,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final color = i < currentStep
                  ? AppColors.statusTeal
                  : i == currentStep
                      ? AppColors.primaryOrange
                      : AppColors.divider;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(3, (i) {
              final isActive = i == currentStep;
              final isDone = i < currentStep;
              return Expanded(
                child: Text(
                  _labels[i].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.04,
                    color: isActive
                        ? AppColors.primaryOrange
                        : isDone
                            ? AppColors.statusTeal
                            : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Customer & vehicle
// ---------------------------------------------------------------------------

class _Step1CustomerVehicle extends ConsumerWidget {
  final CreateJobState state;
  final TextEditingController searchController;
  final TextEditingController complaintController;
  final TextEditingController odometerController;
  final void Function(String) onSearch;
  final Future<void> Function(Customer) onSelectCustomer;
  final VoidCallback onClearCustomer;
  final void Function(CustomerVehicleSummary) onSelectVehicle;
  final void Function(String) onComplaint;
  final void Function(String) onOdometer;
  final void Function(String?) onFuel;

  const _Step1CustomerVehicle({
    super.key,
    required this.state,
    required this.searchController,
    required this.complaintController,
    required this.odometerController,
    required this.onSearch,
    required this.onSelectCustomer,
    required this.onClearCustomer,
    required this.onSelectVehicle,
    required this.onComplaint,
    required this.onOdometer,
    required this.onFuel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _FieldLabel('Customer'),
        if (state.selectedCustomer == null) ...[
          _SearchField(
            controller: searchController,
            hint: 'Name, phone, or vehicle plate…',
            onChanged: onSearch,
          ),
          if (state.isSearching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (state.searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: state.searchResults.map((c) {
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelectCustomer(c);
                      searchController.clear();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          _AvatarInitials(c.initials),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.fullName, style: AppTextStyles.titleSmall),
                                Text(c.phonePrimary, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '${c.vehiclesCount} veh',
                              style: AppTextStyles.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ] else ...[
          _SelectedCustomerCard(
            customer: state.selectedCustomer!,
            onChange: onClearCustomer,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Vehicle'),
          if (state.isLoadingVehicles)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...state.vehicles.map((v) {
                  final selected = state.selectedVehicle?.uuid == v.uuid;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelectVehicle(v);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primaryOrange : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            v.registrationNumber,
                            style: AppTextStyles.monoSmall.copyWith(
                              color: selected ? AppColors.primaryOrange : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(v.makeModel, style: AppTextStyles.labelSmall),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            const Icon(PhosphorIconsRegular.check, size: 14, color: AppColors.primaryOrange),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 18),
          _FieldLabel('Customer complaint'),
          _TextArea(
            controller: complaintController,
            hint: 'Describe the issue reported by customer…',
            onChanged: onComplaint,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Odometer (km)'),
                    _TextField(
                      controller: odometerController,
                      hint: '42500',
                      keyboardType: TextInputType.number,
                      mono: true,
                      onChanged: onOdometer,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Fuel level'),
                    _FuelRow(selected: state.fuelLevel, onSelect: onFuel),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Service categories
// ---------------------------------------------------------------------------

class _Step2Services extends StatelessWidget {
  final List<ServiceCategoryOption> categories;
  final bool isLoadingCategories;
  final Set<String> selectedIds;
  final String? fuelLevel;
  final bool showInsuranceFields;
  final String insuranceCompany;
  final String claimNumber;
  final void Function(String) onToggle;
  final void Function(String?) onFuel;
  final void Function(String) onInsuranceCompany;
  final void Function(String) onClaimNumber;

  const _Step2Services({
    super.key,
    required this.categories,
    required this.isLoadingCategories,
    required this.selectedIds,
    required this.fuelLevel,
    required this.showInsuranceFields,
    required this.insuranceCompany,
    required this.claimNumber,
    required this.onToggle,
    required this.onFuel,
    required this.onInsuranceCompany,
    required this.onClaimNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _FieldLabel('Service categories'),
        const SizedBox(height: 4),
        Text(
          'Select all that apply for this visit',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        if (isLoadingCategories)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
            ),
          )
        else if (categories.isEmpty)
          Text('No service categories configured', style: AppTextStyles.bodySmall)
        else
          GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: categories.map((cat) {
            final selected = selectedIds.contains(cat.uuid);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(cat.uuid);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primaryOrange : AppColors.divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(cat.iconLabel, style: AppTextStyles.labelSmall),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(PhosphorIconsRegular.checkCircle, size: 18, color: AppColors.primaryOrange),
                      ],
                    ),
                    const Spacer(),
                    Text(cat.name, style: AppTextStyles.titleSmall, maxLines: 2),
                    Text(cat.durationLabel, style: AppTextStyles.labelSmall),
                    if (cat.requiresInspection || cat.requiresApproval) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (cat.requiresInspection)
                            _MiniFlag('INSP', AppColors.statusOrangeBg, AppColors.statusOrange),
                          if (cat.requiresApproval)
                            _MiniFlag('APPR', AppColors.statusPurpleBg, AppColors.statusPurple),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (showInsuranceFields) ...[
          const SizedBox(height: 20),
          _FieldLabel('Insurance claim'),
          const SizedBox(height: 4),
          Text(
            'Accident / body work — add insurer details for claim tracking',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: insuranceCompany,
            onChanged: onInsuranceCompany,
            decoration: InputDecoration(
              hintText: 'Insurance company',
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: claimNumber,
            onChanged: onClaimNumber,
            decoration: InputDecoration(
              hintText: 'Claim / policy number',
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Bay, technician, priority, schedule
// ---------------------------------------------------------------------------

class _Step3Assign extends StatelessWidget {
  final CreateJobState state;
  final void Function(String) onPriority;
  final void Function(String) onBay;
  final void Function(String) onTech;
  final VoidCallback onSchedule;

  const _Step3Assign({
    super.key,
    required this.state,
    required this.onPriority,
    required this.onBay,
    required this.onTech,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleLabel = state.scheduledDate != null && state.scheduledTime != null
        ? '${state.scheduledDate!.day}/${state.scheduledDate!.month}/${state.scheduledDate!.year} · ${state.scheduledTime!.format(context)}'
        : 'Tap to set date & time';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _FieldLabel('Priority'),
        _PriorityRow(selected: state.priority, onSelect: onPriority),
        const SizedBox(height: 18),
        _FieldLabel('Service bay'),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.bays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final bay = state.bays[i];
              final selected = state.selectedBayUuid == bay.uuid;
              final (chipColor, chipBg, chipLabel) = switch (bay.status) {
                'available' => (AppColors.statusGreen, AppColors.statusGreenBg, 'Available'),
                'occupied' => (AppColors.statusBlue, AppColors.statusBlueBg, 'Occupied'),
                _ => (AppColors.statusOrange, AppColors.statusOrangeBg, 'Maint.'),
              };
              return GestureDetector(
                onTap: bay.isSelectable
                    ? () {
                        HapticFeedback.selectionClick();
                        onBay(bay.uuid);
                      }
                    : null,
                child: Opacity(
                  opacity: bay.isSelectable ? 1 : 0.45,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primaryOrange : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bay.name, style: AppTextStyles.titleSmall),
                        Text(bay.type, style: AppTextStyles.labelSmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(chipLabel, style: AppTextStyles.labelSmall.copyWith(color: chipColor)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel('Primary technician'),
        ...state.technicians.map((t) {
          final selected = state.selectedTechnicianUuid == t.uuid;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: t.isAvailable
                  ? () {
                      HapticFeedback.selectionClick();
                      onTech(t.uuid);
                    }
                  : null,
              child: Opacity(
                opacity: t.isAvailable ? 1 : 0.5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primaryOrange : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      _AvatarInitials(t.name.split(' ').map((p) => p[0]).take(2).join()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: AppTextStyles.titleSmall),
                            Text(t.specialty, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.isAvailable ? AppColors.statusGreenBg : AppColors.statusOrangeBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          t.isAvailable ? 'Free' : 'Busy',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: t.isAvailable ? AppColors.statusGreen : AppColors.statusOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        _FieldLabel('Scheduled start'),
        GestureDetector(
          onTap: onSchedule,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.calendarBlank, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(scheduleLabel, style: AppTextStyles.bodySmall)),
                Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success + footer
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final String jobNumber;
  final String jobUuid;
  final VoidCallback onViewJob;
  final VoidCallback onStartInspection;
  final VoidCallback onDone;

  const _SuccessView({
    required this.jobNumber,
    required this.jobUuid,
    required this.onViewJob,
    required this.onStartInspection,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.statusGreenBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.statusGreen.withOpacity(0.3)),
                ),
                child: const Icon(PhosphorIconsRegular.check, color: AppColors.statusGreen, size: 32),
              ),
              const SizedBox(height: 20),
              Text(jobNumber, style: AppTextStyles.monoLarge.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(
                'Job created successfully',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Start intake inspection to continue the workflow',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: onStartInspection,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Start Intake Inspection'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: onViewJob,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View Job'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: onDone, child: const Text('Back to Jobs')),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  final int step;
  final bool isSubmitting;
  final bool canNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String? errorMessage;

  const _WizardFooter({
    required this.step,
    required this.isSubmitting,
    required this.canNext,
    required this.onBack,
    required this.onNext,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null) ...[
            Text(errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed)),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (step > 0)
                OutlinedButton(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(88, 44),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back'),
                ),
              if (step > 0) const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: (canNext && !isSubmitting) ? onNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: step == 2 ? AppColors.statusTeal : AppColors.primaryOrange,
                      disabledBackgroundColor: AppColors.bgElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(step == 2 ? 'Create Job' : 'Continue'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.08,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;

  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool mono;
  final void Function(String) onChanged;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.mono = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: mono ? AppTextStyles.monoSmall : AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String) onChanged;

  const _TextArea({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

class _FuelRow extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelect;
  static const _levels = ['empty', 'quarter', 'half', 'three_quarter', 'full'];
  static const _labels = ['E', '¼', '½', '¾', 'F'];

  const _FuelRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_levels.length, (i) {
        final active = selected == _levels[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(active ? null : _levels[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? AppColors.primaryOrange : AppColors.divider,
                  ),
                ),
                child: Text(
                  _labels[i],
                  style: AppTextStyles.labelSmall.copyWith(
                    color: active ? AppColors.primaryOrange : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  static const _options = [
    ('low', 'Low'),
    ('normal', 'Normal'),
    ('urgent', 'Urgent'),
    ('critical', 'Critical'),
  ];

  const _PriorityRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((o) {
        final active = selected == o.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: o != _options.first ? 6 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(o.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? AppColors.primaryOrange : AppColors.divider,
                  ),
                ),
                child: Text(
                  o.$2,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: active ? AppColors.primaryOrange : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectedCustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onChange;

  const _SelectedCustomerCard({required this.customer, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrangeDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          _AvatarInitials(customer.initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName, style: AppTextStyles.titleSmall),
                Text(customer.phonePrimary, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;
  const _AvatarInitials(this.initials);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.statusTealBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.statusTeal.withOpacity(0.22)),
      ),
      child: Text(initials, style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusTeal)),
    );
  }
}

class _MiniFlag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniFlag(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: fg, fontSize: 9)),
    );
  }
}
