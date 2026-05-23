import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/owner_signup_provider.dart';

class OwnerSignupScreen extends ConsumerStatefulWidget {
  const OwnerSignupScreen({super.key});

  @override
  ConsumerState<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends ConsumerState<OwnerSignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(ownerSignupProvider.notifier).submit(
          phoneDigits: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          businessName: _businessController.text,
          email: _emailController.text,
        );
    if (!ok || !mounted) return;

    final result = ref.read(ownerSignupProvider).result!;
    context.push('/auth/staff-pin', extra: {
      'login': result.login,
      'purpose': 'setup',
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerSignupProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create your garage', style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Start your 14-day trial. Set up your PIN via WhatsApp after signup.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _label('Garage name'),
          _field(_businessController, 'Patel Auto Works'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Your first name'),
                  _field(_firstNameController, 'Sagar'),
                ],
              )),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Last name'),
                  _field(_lastNameController, 'Patel'),
                ],
              )),
            ],
          ),
          const SizedBox(height: 12),
          _label('Mobile (WhatsApp)'),
          _field(_phoneController, '9876543210', keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _label('Email (optional)'),
          _field(_emailController, 'owner@garage.com', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('Choose a plan'),
          if (state.isLoadingPlans)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
            )
          else
            ...state.plans.map((plan) {
              final selected = state.selectedPlanSlug == plan.slug;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ref.read(ownerSignupProvider.notifier).selectPlan(plan.slug),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryOrangeDim : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primaryOrange : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: AppTextStyles.titleSmall),
                                Text(
                                  '₹${plan.price.toInt()}/${plan.billingCycle} · ${plan.trialDays} day trial',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.primaryOrange),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(state.errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed)),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: 'Create garage account',
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : _submit,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/auth/login'),
              child: Text('Already have an account? Sign in', style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.08),
        ),
      );

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) => TextField(
        controller: c,
        keyboardType: keyboard,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
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
