import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/presentation/widgets/gps_tracking_info_sheet.dart';
import '../../../vehicles/data/vehicle_catalog_repository.dart';
import '../../../vehicles/presentation/widgets/catalog_search_field.dart';
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
  String? _makeUuid;
  String? _modelUuid;
  String? _variantUuid;
  String? _colorUuid;
  int _catalogReset = 0;

  static const _fuelTypes = ['petrol', 'diesel', 'cng', 'electric', 'hybrid'];

  int? get _yearFilter => int.tryParse(_yearController.text.trim());

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
          vehicleMakeUuid: _makeUuid,
          vehicleModelUuid: _modelUuid,
          vehicleVariantUuid: _variantUuid,
          vehicleColorUuid: _colorUuid,
        );

    if (vehicle != null && mounted) {
      ref.invalidate(vehicleByUuidProvider(widget.vehicleUuid));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleByUuidProvider(widget.vehicleUuid));
    final editState = ref.watch(editVehicleProvider(_params));
    final catalog = ref.watch(vehicleCatalogRepositoryProvider);

    return vehicleState.when(
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
      data: (vehicle) {
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
                    _label('Year'),
                    _field(
                      _yearController,
                      '2020',
                      keyboard: TextInputType.number,
                      onChanged: () => setState(() {
                        _makeUuid = null;
                        _modelUuid = null;
                        _variantUuid = null;
                        _colorUuid = null;
                        _catalogReset++;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _label('Make'),
                    CatalogSearchField(
                      key: ValueKey('edit-make-$_catalogReset'),
                      hint: 'Start typing make…',
                      initialValue: _makerController.text,
                      onSearch: (q) => catalog.searchMakes(query: q, year: _yearFilter),
                      onSelected: (option) => setState(() {
                        if (option == null) {
                          _makeUuid = null;
                          return;
                        }
                        _makeUuid = option.uuid;
                        _makerController.text = option.name;
                        _modelController.clear();
                        _modelUuid = null;
                        _variantController.clear();
                        _variantUuid = null;
                        _colorController.clear();
                        _colorUuid = null;
                        _catalogReset++;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _label('Model'),
                    CatalogSearchField(
                      key: ValueKey('edit-model-$_catalogReset-${_makeUuid ?? 'none'}'),
                      hint: _makeUuid == null ? 'Select make first' : 'Start typing model…',
                      enabled: _makeUuid != null,
                      initialValue: _modelController.text,
                      onSearch: (q) => catalog.searchModels(
                        makeUuid: _makeUuid!,
                        query: q,
                        year: _yearFilter,
                      ),
                      onSelected: (option) => setState(() {
                        if (option == null) {
                          _modelUuid = null;
                          return;
                        }
                        _modelUuid = option.uuid;
                        _modelController.text = option.name;
                        _variantController.clear();
                        _variantUuid = null;
                        _colorController.clear();
                        _colorUuid = null;
                        _catalogReset++;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _label('Variant (optional)'),
                    CatalogSearchField(
                      key: ValueKey('edit-variant-$_catalogReset-${_modelUuid ?? 'none'}'),
                      hint: _modelUuid == null ? 'Select model first' : 'Start typing variant…',
                      enabled: _modelUuid != null,
                      initialValue: _variantController.text,
                      onSearch: (q) => catalog.searchVariants(
                        modelUuid: _modelUuid!,
                        query: q,
                        year: _yearFilter,
                      ),
                      onSelected: (option) => setState(() {
                        if (option == null) {
                          _variantUuid = null;
                          return;
                        }
                        _variantUuid = option.uuid;
                        _variantController.text = option.name;
                        if (option.fuelType != null && option.fuelType!.isNotEmpty) {
                          _fuelType = option.fuelType!;
                        }
                        _colorController.clear();
                        _colorUuid = null;
                        _catalogReset++;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _label('Color (optional)'),
                    CatalogSearchField(
                      key: ValueKey('edit-color-$_catalogReset-${_variantUuid ?? 'none'}'),
                      hint: 'Start typing color…',
                      initialValue: _colorController.text,
                      onSearch: (q) => catalog.searchColors(query: q, variantUuid: _variantUuid),
                      onSelected: (option) => setState(() {
                        if (option == null) {
                          _colorUuid = null;
                          return;
                        }
                        _colorUuid = option.uuid;
                        _colorController.text = option.name;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _label('Fuel type'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _fuelTypes.map((f) {
                        final selected = _fuelType == f;
                        return _FuelTypeChip(
                          label: f.toUpperCase(),
                          selected: selected,
                          onTap: () => setState(() => _fuelType = f),
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
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: AppTextStyles.bodyMedium,
      onChanged: onChanged == null ? null : (_) => onChanged(),
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

class _FuelTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FuelTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primaryOrange.withValues(alpha: 0.12),
        highlightColor: AppColors.primaryOrange.withValues(alpha: 0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryOrange : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(PhosphorIconsRegular.check, size: 14, color: AppColors.primaryOrange),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.primaryOrange : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
