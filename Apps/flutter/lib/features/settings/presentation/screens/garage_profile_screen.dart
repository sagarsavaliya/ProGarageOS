import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/tenant_repository.dart';

class GarageProfileScreen extends ConsumerStatefulWidget {
  const GarageProfileScreen({super.key});

  @override
  ConsumerState<GarageProfileScreen> createState() => _GarageProfileScreenState();
}

class _GarageProfileScreenState extends ConsumerState<GarageProfileScreen> {
  final _businessNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  void _bind(TenantProfile profile) {
    if (_initialized) return;
    _businessNameController.text = profile.businessName;
    _gstinController.text = profile.gstNumber ?? '';
    _addressController.text = profile.address ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _pincodeController.text = profile.pincode ?? '';
    _phoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(tenantRepositoryProvider).updateProfile(
            businessName: _businessNameController.text.trim(),
            gstNumber: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
            pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          );
      ref.invalidate(tenantProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Garage profile updated')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = failureMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(tenantProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Garage profile', style: AppTextStyles.titleMedium),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
        error: (e, _) => Center(child: Text(failureMessage(e))),
        data: (profile) {
          _bind(profile);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Invoice header & business details',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              _field('Business name', _businessNameController),
              const SizedBox(height: 12),
              _field('GSTIN', _gstinController),
              const SizedBox(height: 12),
              _field('Address line', _addressController, maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('City', _cityController)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('State', _stateController)),
                ],
              ),
              const SizedBox(height: 12),
              _field('PIN code', _pincodeController, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field('Phone', _phoneController, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _field('Email', _emailController, keyboard: TextInputType.emailAddress),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.statusRed)),
              ],
              const SizedBox(height: 24),
              AppButton(label: _saving ? 'Saving…' : 'Save changes', onPressed: _saving ? null : _save),
            ],
          );
        },
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
