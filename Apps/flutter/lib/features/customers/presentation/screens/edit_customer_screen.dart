import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/customer_models.dart';
import '../providers/customers_provider.dart';
import '../providers/edit_customer_provider.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerUuid;

  const EditCustomerScreen({super.key, required this.customerUuid});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _marketingOptIn = true;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _bindDetail(CustomerDetail detail) {
    if (_initialized) return;
    _firstNameController.text = detail.firstName;
    _lastNameController.text = detail.lastName;
    _emailController.text = detail.email ?? '';
    _notesController.text = detail.garageProfile.internalNotes ?? '';
    _marketingOptIn = detail.marketingOptIn;
    _initialized = true;
  }

  Future<void> _submit() async {
    final updated = await ref.read(editCustomerProvider(widget.customerUuid).notifier).submit(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          marketingOptIn: _marketingOptIn,
          internalNotes: _notesController.text,
        );
    if (updated != null && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(customerDetailProvider(widget.customerUuid));
    final editState = ref.watch(editCustomerProvider(widget.customerUuid));

    return detailState.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          title: Text('Edit Customer', style: AppTextStyles.titleMedium),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgSurface),
        body: Center(child: Text('Could not load customer', style: AppTextStyles.bodyMedium)),
      ),
      data: (detail) {
        _bindDetail(detail);
        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.bgSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(PhosphorIconsRegular.x, color: AppColors.textSecondary, size: 20),
            ),
            title: Text('Edit Customer', style: AppTextStyles.titleMedium),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _SectionLabel('Contact'),
                    _TextField(
                      controller: _firstNameController,
                      hint: 'First name *',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    _TextField(
                      controller: _lastNameController,
                      hint: 'Last name',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    _ReadOnlyPhone(phone: detail.phonePrimary),
                    const SizedBox(height: 10),
                    _TextField(
                      controller: _emailController,
                      hint: 'Email (optional)',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Garage notes'),
                    _TextField(
                      controller: _notesController,
                      hint: 'Internal notes — preferences, VIP, etc.',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _marketingOptIn,
                      onChanged: (v) => setState(() => _marketingOptIn = v),
                      title: Text('WhatsApp updates', style: AppTextStyles.bodySmall),
                      subtitle: Text('Service reminders & offers', style: AppTextStyles.labelSmall),
                      activeThumbColor: AppColors.primaryOrange,
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
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

class _ReadOnlyPhone extends StatelessWidget {
  final String phone;

  const _ReadOnlyPhone({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOBILE',
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.08),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(phone, style: AppTextStyles.monoSmall),
        ),
        const SizedBox(height: 4),
        Text('Phone cannot be changed here', style: AppTextStyles.labelSmall),
      ],
    );
  }
}
