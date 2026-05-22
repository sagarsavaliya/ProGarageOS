import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../settings/presentation/widgets/gps_tracking_info_sheet.dart';
import '../providers/create_vehicle_provider.dart';
import '../providers/customers_provider.dart' show customerDetailProvider, customersProvider;

class AddVehicleScreen extends ConsumerStatefulWidget {
  final String customerUuid;
  final String customerName;

  const AddVehicleScreen({
    super.key,
    required this.customerUuid,
    required this.customerName,
  });

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _plateController = TextEditingController();
  final _makerController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _odometerController = TextEditingController();
  String _fuelType = 'petrol';
  bool _gpsConsent = false;

  static const _fuelTypes = ['petrol', 'diesel', 'cng', 'electric', 'hybrid'];

  @override
  void initState() {
    super.initState();
    _loadGpsDefault();
  }

  Future<void> _loadGpsDefault() async {
    final enabled = await ref.read(secureStorageProvider).isGpsDefaultConsentEnabled();
    if (mounted) setState(() => _gpsConsent = enabled);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _makerController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final year = int.tryParse(_yearController.text.trim());
    final odo = int.tryParse(_odometerController.text.replaceAll(',', ''));

    final vehicle = await ref.read(createVehicleProvider.notifier).submit(
          customerUuid: widget.customerUuid,
          registrationNumber: _plateController.text,
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
      ref.invalidate(customerDetailProvider(widget.customerUuid));
      ref.read(customersProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vehicle.registrationNumber} added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
      context.push('/customers/${widget.customerUuid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createVehicleProvider);

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
            Text('Add Vehicle', style: AppTextStyles.titleMedium),
            Text(
              widget.customerName,
              style: AppTextStyles.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _label('Registration'),
                _field(_plateController, 'MH12AB1234', mono: true),
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
                const SizedBox(height: 14),
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
              label: 'Save vehicle',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
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
    bool mono = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: mono ? TextCapitalization.characters : TextCapitalization.words,
      style: mono ? AppTextStyles.monoSmall : AppTextStyles.bodyMedium,
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
