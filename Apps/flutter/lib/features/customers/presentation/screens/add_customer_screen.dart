import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/create_customer_provider.dart';
import '../providers/customers_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _marketingOptIn = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final customer = await ref.read(createCustomerProvider.notifier).submit(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phonePrimary: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
          email: _emailController.text,
          marketingOptIn: _marketingOptIn,
          internalNotes: _notesController.text,
        );
    if (customer != null && mounted) {
      ref.read(customersProvider.notifier).refresh();
      _showSuccessSheet(customer.uuid, customer.fullName);
    }
  }

  void _showSuccessSheet(String uuid, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.statusGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.check, color: AppColors.statusGreen),
              ),
              const SizedBox(height: 16),
              Text('Customer added', style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(name, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add vehicle',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pushReplacement(
                    '/customers/vehicle/add',
                    extra: {'customerUuid': uuid, 'customerName': name},
                  );
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'View profile',
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                  context.push('/customers/$uuid');
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createCustomerProvider);

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
        title: Text('Add Customer', style: AppTextStyles.titleMedium),
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
                _PhoneField(controller: _phoneController),
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
                  subtitle: Text(
                    'Service reminders & offers',
                    style: AppTextStyles.labelSmall,
                  ),
                  activeThumbColor: AppColors.primaryOrange,
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
              label: 'Save customer',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
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

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text('+91', style: AppTextStyles.monoSmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.monoSmall,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Mobile number *',
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
          ),
        ),
      ],
    );
  }
}
