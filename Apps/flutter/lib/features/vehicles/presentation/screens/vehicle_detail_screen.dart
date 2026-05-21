import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../../customers/presentation/providers/customers_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleUuid;
  final String customerUuid;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleUuid,
    required this.customerUuid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(customerVehiclesProvider(customerUuid));
    final docsState = ref.watch(vehicleDocumentsProvider(vehicleUuid));
    final docsNotifier = ref.read(vehicleDocumentsProvider(vehicleUuid).notifier);

    return vehiclesState.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgSurface),
        body: Center(child: Text('Could not load vehicle', style: AppTextStyles.bodyMedium)),
      ),
      data: (vehicles) {
        final vehicle = vehicles.firstWhere(
          (v) => v.uuid == vehicleUuid,
          orElse: () => vehicles.isNotEmpty ? vehicles.first : _emptyVehicle,
        );
        return _VehicleBody(
          vehicle: vehicle,
          customerUuid: customerUuid,
          docsState: docsState,
          onDocsRefresh: docsNotifier.refresh,
        );
      },
    );
  }

  static final _emptyVehicle = Vehicle(
    uuid: '',
    registrationNumber: '—',
    maker: '',
    model: '',
    year: 0,
    fuelType: '',
    gpsTrackingConsent: false,
    isActive: true,
    complianceAlerts: [],
  );
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _VehicleBody extends StatelessWidget {
  final Vehicle vehicle;
  final String customerUuid;
  final AsyncValue<List<VehicleDocument>> docsState;
  final Future<void> Function() onDocsRefresh;

  const _VehicleBody({
    required this.vehicle,
    required this.customerUuid,
    required this.docsState,
    required this.onDocsRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicle.complianceAlerts.isNotEmpty) _buildAlertBanner(),
                _buildIdentityCard(),
                const SizedBox(height: 16),
                _buildSpecsGrid(),
                const SizedBox(height: 16),
                _buildSectionHeader('Compliance Documents'),
                _buildDocsList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          Text(vehicle.makeModel, style: AppTextStyles.titleMedium),
          Text(
            vehicle.registrationNumber,
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(
              '/vehicles/${vehicle.uuid}/edit',
              extra: {'customerUuid': customerUuid},
            );
          },
          icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.textSecondary, size: 20),
          tooltip: 'Edit vehicle',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusRedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.warning, color: AppColors.statusRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${vehicle.complianceAlerts.map((a) => a.typeLabel).join(', ')} — ${vehicle.complianceAlerts.any((a) => a.isExpired) ? 'Expired' : 'Expiring Soon'}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIconsRegular.car,
                    color: AppColors.textMuted, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.makeModel, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.registrationNumber,
                      style: GoogleFonts.dmMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(
                    label: vehicle.fuelType.toUpperCase(),
                    color: vehicle.fuelType == 'electric'
                        ? AppColors.statusGreen
                        : AppColors.textSecondary,
                  ),
                  if (vehicle.emissionNorms != null) ...[
                    const SizedBox(height: 4),
                    _Badge(label: vehicle.emissionNorms!, color: AppColors.textMuted),
                  ],
                ],
              ),
            ],
          ),
          if (vehicle.chassisNumber != null || vehicle.engineNumber != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            if (vehicle.chassisNumber != null)
              _InfoRow(label: 'Chassis No.', value: vehicle.chassisNumber!),
            if (vehicle.engineNumber != null)
              _InfoRow(label: 'Engine No.', value: vehicle.engineNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecsGrid() {
    final specs = <(String, String, PhosphorIconData)>[
      if (vehicle.color != null) ('Color', vehicle.color!, PhosphorIconsRegular.palette),
      if (vehicle.transmission != null)
        ('Transmission', vehicle.transmission!.toUpperCase(), PhosphorIconsRegular.gear),
      if (vehicle.bodyType != null)
        ('Body Type', _capitalize(vehicle.bodyType!), PhosphorIconsRegular.car),
      if (vehicle.odometerReading != null)
        ('Odometer', '${vehicle.odometerReading} km', PhosphorIconsRegular.gauge),
      if (vehicle.registrationDate != null)
        ('Registered', _formatDate(vehicle.registrationDate!), PhosphorIconsRegular.calendar),
      if (vehicle.registrationValidity != null)
        ('RC Valid Until', _formatDate(vehicle.registrationValidity!), PhosphorIconsRegular.sealCheck),
      if (vehicle.insuranceExpiry != null)
        ('Insurance Expiry', _formatDate(vehicle.insuranceExpiry!), PhosphorIconsRegular.shield),
      (
        'GPS Tracking',
        vehicle.gpsTrackingConsent ? 'Consented' : 'Not consented',
        PhosphorIconsRegular.navigationArrow,
      ),
    ];

    if (specs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Specifications', style: AppTextStyles.titleMedium),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: specs.asMap().entries.map((entry) {
                final isLast = entry.key == specs.length - 1;
                final (label, value, icon) = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.textMuted, size: 15),
                          const SizedBox(width: 10),
                          Text(label, style: AppTextStyles.bodySmall),
                          const Spacer(),
                          Text(value, style: AppTextStyles.labelLarge),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(title, style: AppTextStyles.titleMedium),
    );
  }

  Widget _buildDocsList() {
    return docsState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(child: Text('Could not load documents', style: AppTextStyles.bodySmall)),
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text('No documents uploaded', style: AppTextStyles.bodySmall)),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: docs.asMap().entries.map((entry) {
              final doc = entry.value;
              final isLast = entry.key == docs.length - 1;
              return Column(
                children: [
                  _DocumentRow(doc: doc),
                  if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormat('d MMM yyyy').format(dt);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------
// Document row
// ---------------------------------------------------------------------------

class _DocumentRow extends StatelessWidget {
  final VehicleDocument doc;

  const _DocumentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isExpired = doc.isExpired;
    final statusColor = isExpired ? AppColors.statusRed : AppColors.statusGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_docIcon(doc.documentType), color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.typeLabel, style: AppTextStyles.titleSmall),
                if (doc.documentNumber != null)
                  Text(doc.documentNumber!, style: AppTextStyles.monoSmall),
                if (doc.issuingAuthority != null)
                  Text(doc.issuingAuthority!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (doc.expiryDate != null) ...[
                Text(
                  isExpired ? 'EXPIRED' : 'Valid till',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  _formatDate(doc.expiryDate!),
                  style: AppTextStyles.monoSmall.copyWith(
                    color: isExpired ? AppColors.statusRed : AppColors.textPrimary,
                  ),
                ),
              ],
              if (doc.isVerified)
                Row(
                  children: [
                    Icon(PhosphorIconsFill.sealCheck, color: AppColors.statusGreen, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusGreen),
                    ),
                  ],
                ),
            ],
          ),
          if (doc.fileUrl != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => HapticFeedback.lightImpact(),
              icon: Icon(PhosphorIconsRegular.download, color: AppColors.textMuted, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ],
      ),
    );
  }

  PhosphorIconData _docIcon(String type) {
    switch (type) {
      case 'insurance':
        return PhosphorIconsFill.shield;
      case 'puc':
        return PhosphorIconsRegular.leaf;
      case 'fitness':
        return PhosphorIconsRegular.firstAid;
      case 'permit':
        return PhosphorIconsRegular.article;
      case 'rc':
        return PhosphorIconsRegular.certificate;
      default:
        return PhosphorIconsRegular.file;
    }
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormat('d MMM yyyy').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 9, letterSpacing: 0.6),
      ),
    );
  }
}

