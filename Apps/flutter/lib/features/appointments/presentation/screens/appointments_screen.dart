import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../data/models/appointment_models.dart';
import '../providers/appointments_provider.dart';
import '../widgets/book_appointment_sheet.dart';
import '../widgets/check_in_appointment_sheet.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    final notifier = ref.read(appointmentsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showBookAppointmentSheet(context, ref);
        },
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appointments', style: AppTextStyles.displayMedium),
                        Text(
                          'Book slots and check in customers',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: notifier.refresh,
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _FilterRow(
              selected: state.filter,
              onSelected: notifier.setFilter,
            ),
            Expanded(child: _buildBody(context, ref, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppointmentsState state,
    AppointmentsNotifier notifier,
  ) {
    if (state.isLoading && state.appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }
    if (state.error != null && state.appointments.isEmpty) {
      return ApiErrorView(message: state.error!, onRetry: notifier.refresh);
    }
    if (state.appointments.isEmpty) {
      return GuidedEmptyState(
        icon: PhosphorIconsRegular.calendarBlank,
        title: 'No appointments',
        subtitle: state.filter == AppointmentFilter.today
            ? 'Nothing booked for today. Tap + to schedule one.'
            : 'Tap + to book the first appointment.',
        actionLabel: 'Book appointment',
        onAction: () => showBookAppointmentSheet(context, ref),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        itemCount: state.appointments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.appointments.length) {
            notifier.loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
              ),
            );
          }
          final apt = state.appointments[index];
          return _AppointmentCard(
            appointment: apt,
            onCheckIn: apt.canCheckIn
                ? () => showCheckInAppointmentSheet(context, ref, apt)
                : null,
            onOpenJob: apt.convertedJobUuid != null
                ? () => context.push('/jobs/${apt.convertedJobUuid}')
                : null,
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final AppointmentFilter selected;
  final ValueChanged<AppointmentFilter> onSelected;

  const _FilterRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: AppointmentFilter.values.map((f) {
          final isSelected = f == selected;
          final label = switch (f) {
            AppointmentFilter.today => 'Today',
            AppointmentFilter.upcoming => 'Upcoming',
            AppointmentFilter.all => 'All',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: AppColors.primaryOrangeDim,
              checkmarkColor: AppColors.primaryOrange,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCheckIn;
  final VoidCallback? onOpenJob;

  const _AppointmentCard({
    required this.appointment,
    this.onCheckIn,
    this.onOpenJob,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM');
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(appointment.customer.name, style: AppTextStyles.titleSmall),
                ),
                AppStatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${appointment.vehicle.registrationNumber} · ${appointment.appointmentNumber}',
              style: AppTextStyles.bodySmall,
            ),
            if (appointment.serviceCategory?.name.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(appointment.serviceCategory!.name, style: AppTextStyles.labelSmall),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(PhosphorIconsRegular.clock, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${dateFmt.format(appointment.scheduledDate)} · ${appointment.startTime}–${appointment.endTime}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (onCheckIn != null || onOpenJob != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onCheckIn != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCheckIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: const BorderSide(color: AppColors.primaryOrange),
                        ),
                        child: const Text('Check in'),
                      ),
                    ),
                  if (onCheckIn != null && onOpenJob != null) const SizedBox(width: 8),
                  if (onOpenJob != null)
                    Expanded(
                      child: TextButton(onPressed: onOpenJob, child: const Text('View job')),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
