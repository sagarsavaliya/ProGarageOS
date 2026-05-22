import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/appointment_models.dart';
import '../../data/appointments_repository.dart';
import '../providers/appointments_provider.dart';

Future<void> showCheckInAppointmentSheet(
  BuildContext context,
  WidgetRef ref,
  Appointment appointment,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CheckInSheet(ref: ref, appointment: appointment),
    ),
  );
}

class _CheckInSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Appointment appointment;

  const _CheckInSheet({required this.ref, required this.appointment});

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  final _odometerController = TextEditingController();
  String? _fuelLevel;
  bool _loading = false;
  String? _error;

  static const _fuelLevels = ['empty', 'quarter', 'half', 'three_quarter', 'full'];

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final odo = int.tryParse(_odometerController.text.replaceAll(',', ''));
      final result = await ref.read(appointmentsRepositoryProvider).checkIn(
            appointmentUuid: widget.appointment.uuid,
            odometerAtIntake: odo,
            fuelLevel: _fuelLevel,
          );
      ref.read(appointmentsProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/jobs/${result.jobUuid}');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = failureMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Check in customer', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${apt.customer.name} · ${apt.vehicle.registrationNumber}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Odometer km (optional)'),
            ),
            const SizedBox(height: 12),
            Text('Fuel level (optional)', style: AppTextStyles.labelSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _fuelLevels.map((f) {
                final selected = _fuelLevel == f;
                return ChoiceChip(
                  label: Text(f.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (_) => setState(() => _fuelLevel = f),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: AppColors.statusRed)),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: _loading ? 'Creating job…' : 'Check in & start job',
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
