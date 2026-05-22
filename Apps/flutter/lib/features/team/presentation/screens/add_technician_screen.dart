import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../providers/create_staff_provider.dart';
import '../providers/staff_provider.dart';

class AddTechnicianScreen extends ConsumerStatefulWidget {
  const AddTechnicianScreen({super.key});

  @override
  ConsumerState<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends ConsumerState<AddTechnicianScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  String _role = 'technician';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final member = await ref.read(createStaffProvider.notifier).submit(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          role: _role,
          pin: _pin.text.trim(),
        );
    if (member != null && mounted) {
      ref.invalidate(staffListProvider);
      context.pop();
      context.push('/team/${member.uuid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createStaffProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Add team member', style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTextField(controller: _firstName, label: 'First name', hint: 'Amit'),
          const SizedBox(height: 12),
          AppTextField(controller: _lastName, label: 'Last name', hint: 'Kamble'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _phone,
            label: 'Phone',
            hint: '9876543210',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _email,
            label: 'Email (optional)',
            hint: 'amit@garage.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          Text('Role', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              AppFilterChip(
                label: 'Technician',
                isSelected: _role == 'technician',
                onTap: () => setState(() => _role = 'technician'),
              ),
              AppFilterChip(
                label: 'Advisor',
                isSelected: _role == 'service_advisor',
                onTap: () => setState(() => _role = 'service_advisor'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _pin,
            label: '6-digit PIN',
            hint: '••••••',
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
            ),
          ],
          const SizedBox(height: 24),
          AppButton(
            label: state.isSubmitting ? 'Creating…' : 'Create member',
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
