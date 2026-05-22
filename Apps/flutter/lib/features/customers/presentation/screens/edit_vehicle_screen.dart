import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/presentation/widgets/gps_tracking_info_sheet.dart';
import '../../data/models/customer_models.dart';
import '../providers/customers_provider.dart';
import '../providers/edit_vehicle_provider.dart';

class EditVehicleScreen extends ConsumerStatefulWidget {
  final String vehicleUuid;
  final String customerUuid;

  const EditVehicleScreen({
    super.key,
    required this.vehicleUuid,
    required this.customerUuid,
  });

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _makerController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _odometerController = TextEditingController();
  String _fuelType = 'petrol';
  String _registration = '';
  bool _initialized = false;
  bool _gpsConsent = false;

  static const _fuelTypes = ['petrol', 'diesel', 'cng', 'electric', 'hybrid'];

  ({String vehicleUuid, String customerUuid}) get _params =>
      (vehicleUuid: widget.vehicleUuid, customerUuid: widget.customerUuid);

  @override
  void dispose() {
    _makerController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _bindVehicle(Vehicle vehicle) {
    if (_initialized) return;
    _registration = vehicle.registrationNumber;
    _makerController.text = vehicle.maker;
    _modelController.text = vehicle.model;
    _variantController.text = vehicle.variant ?? '';
    _yearController.text = vehicle.year > 0 ? '${vehicle.year}' : '';
    _colorController.text = vehicle.color ?? '';
    _odometerController.text =
        vehicle.odometerReading != null ? '${vehicle.odometerReading}' : '';
    _fuelType = vehicle.fuelType.isNotEmpty ? vehicle.fuelType : 'petrol';
    _gpsConsent = vehicle.gpsTrackingConsent;
    _initialized = true;
  }

  Vehicle? _findVehicle(List<Vehicle> vehicles) {
    for (final v in vehicles) {
      if (v.uuid == widget.vehicleUuid) return v;
    }
    return vehicles.isNotEmpty ? vehicles.first : null;
  }

  Future<void> _submit() async {
    final year = int.tryParse(_yearController.text.trim());
    final odo = int.tryParse(_odometerController.text.replaceAll(',', ''));

    final vehicle = await ref.read(editVehicleProvider(_params).notifier).submit(
          maker: _makerController.text,
          model: _modelController.text,
          variant: _variantController.text,
          year: year,
          color: _colorController.text,
          fuelType: _fuelType,
          odometerReading: odo,
          gpsTrackingConsent: _gpsConsent,
        );

    if (vehicle != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesState = ref.watch(customerVehiclesProvider(widget.customerUuid));
    final editState = ref.watch(editVehicleProvider(_params));

    return vehiclesState.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          title: Text('Edit Vehicle', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgSurface),
        body: Center(child: Text('Could not load vehicle', style: AppTextStyles.bodyMedium)),
      ),
      data: (vehicles) {
        final vehicle = _findVehicle(vehicles);
        if (vehicle == null) {
          return Scaffold(
            backgroundColor: AppColors.bgPrimary,
            appBar: AppBar(backgroundColor: AppColors.bgSurface),
            body: Center(child: Text('Vehicle not found', style: AppTextStyles.bodyMedium)),
          );
        }
        _bindVehicle(vehicle);

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
            title: Text('Edit Vehicle', style: AppTextStyles.titleMedium),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _label('Registration'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        _registration,
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.primaryOrange),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Make & model'),
                    Row(
                      children: [
                        Expanded(child: _field(_makerController, 'Maruti Suzuki')),
                        const SizedBox(width: 8),
                        Expanded(child: _field(_modelController, 'Swift')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(_variantController, 'Variant (optional)'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Year'),
                              _field(_yearController, '2020', keyboard: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Color'),
                              _field(_colorController, 'White'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Fuel type'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _fuelTypes.map((f) {
                        final selected = _fuelType == f;
                        return ChoiceChip(
                          label: Text(f.toUpperCase()),
                          selected: selected,
                          onSelected: (_) => setState(() => _fuelType = f),
                          selectedColor: AppColors.primaryOrangeDim,
                          backgroundColor: AppColors.bgSurface,
                          side: BorderSide(
                            color: selected ? AppColors.primaryOrange : AppColors.divider,
                          ),
                          labelStyle: AppTextStyles.labelSmall.copyWith(
                            color: selected ? AppColors.primaryOrange : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _label('Odometer (km)'),
                    _field(_odometerController, '42500', keyboard: TextInputType.number),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('GPS odometer tracking', style: AppTextStyles.bodyMedium),
                      subtitle: Text(
                        'Customer consent to estimate km driven',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      secondary: IconButton(
                        icon: const Icon(PhosphorIconsRegular.info, size: 18, color: AppColors.textMuted),
                        onPressed: () => GpsTrackingInfoSheet.show(context),
                      ),
                      value: _gpsConsent,
                      activeThumbColor: AppColors.primaryOrange,
                      onChanged: (v) => setState(() => _gpsConsent = v),
                    ),
                    if (editState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        editState.errorMessage!,
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
                  isLoading: editState.isSubmitting,
                  onPressed: editState.isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.08),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
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
      ),
    );
  }
}
