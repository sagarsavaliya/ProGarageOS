import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/staff_pin_pad.dart';
import '../../../onboarding/presentation/utils/post_login_navigation.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';
import '../providers/owner_signup_provider.dart';

enum _SignupStep { form, verify, setPin, loginMethod }

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
  final _otpController = TextEditingController();
  final _localAuth = LocalAuthentication();

  _SignupStep _step = _SignupStep.form;
  String _login = '';
  String? _infoMessage;
  String? _stepError;
  bool _stepLoading = false;
  String? _phoneMasked;
  String _newPin = '';
  String _confirmPin = '';

  String get _phoneDigits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final ok = await ref.read(ownerSignupProvider.notifier).submit(
          phoneDigits: _phoneDigits,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          businessName: _businessController.text,
          email: _emailController.text,
        );
    if (!ok || !mounted) return;

    final result = ref.read(ownerSignupProvider).result!;
    setState(() {
      _login = result.login;
      _infoMessage = result.resume
          ? 'Welcome back — verify your WhatsApp number to finish setup.'
          : 'Garage created. Verify your WhatsApp number to set your PIN.';
      _step = _SignupStep.verify;
      _stepError = null;
    });
    await _sendOtp();
  }

  Future<void> _sendOtp() async {
    if (_login.isEmpty) return;
    setState(() {
      _stepLoading = true;
      _stepError = null;
    });
    try {
      final masked = await ref.read(authRepositoryProvider).requestStaffPinOtp(
            StaffPinOtpRequest(login: _login, purpose: 'setup'),
          );
      if (!mounted) return;
      setState(() {
        _phoneMasked = masked;
        _stepLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = failureMessage(e);
        _stepLoading = false;
      });
    }
  }

  void _proceedToPinSetup() {
    if (_otpController.text.trim().length != 6) {
      setState(() => _stepError = 'Enter the 6-digit code from WhatsApp.');
      return;
    }
    setState(() {
      _step = _SignupStep.setPin;
      _stepError = null;
      _newPin = '';
      _confirmPin = '';
    });
  }

  Future<void> _savePin() async {
    if (_newPin.length != 6 || _confirmPin.length != 6) {
      setState(() => _stepError = 'PIN must be 6 digits.');
      return;
    }
    if (_newPin != _confirmPin) {
      setState(() => _stepError = 'PINs do not match.');
      return;
    }

    setState(() {
      _stepLoading = true;
      _stepError = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetStaffPin(
            StaffPinResetRequest(
              login: _login,
              otp: _otpController.text.trim(),
              pin: _newPin,
            ),
          );
      await ref.read(secureStorageProvider).saveSavedLogin(_login);
      if (!mounted) return;
      setState(() {
        _step = _SignupStep.loginMethod;
        _stepLoading = false;
        _infoMessage = 'PIN saved. Choose how you want to sign in next time.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = failureMessage(e);
        _stepLoading = false;
      });
    }
  }

  Future<void> _finish({required bool enableBiometric}) async {
    setState(() {
      _stepLoading = true;
      _stepError = null;
    });

    try {
      if (enableBiometric && !kIsWeb) {
        final canCheck = await _localAuth.canCheckBiometrics;
        if (canCheck) {
          final ok = await _localAuth.authenticate(
            localizedReason: 'Enable quick sign-in for Pro Garage OS',
            options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
          );
          await ref.read(secureStorageProvider).setBiometricEnabled(ok);
        } else {
          await ref.read(secureStorageProvider).setBiometricEnabled(false);
        }
      } else {
        await ref.read(secureStorageProvider).setBiometricEnabled(false);
      }

      final response = await ref.read(authRepositoryProvider).loginStaff(
            StaffLoginRequest(login: _login, pin: _newPin),
          );
      await ref.read(secureStorageProvider).saveToken(response.token);
      await ref.read(secureStorageProvider).saveUserJson(response.user.toJsonString());

      if (!mounted) return;
      final route = await resolvePostLoginRoute(ref);
      if (mounted) context.go(route);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stepError = failureMessage(e);
        _stepLoading = false;
      });
    }
  }

  void _addPinDigit(String digit, {required bool confirm}) {
    setState(() {
      _stepError = null;
      if (confirm) {
        if (_confirmPin.length < 6) _confirmPin += digit;
      } else {
        if (_newPin.length < 6) _newPin += digit;
      }
    });
    if (confirm && _confirmPin.length == 6) {
      _savePin();
    }
  }

  void _deletePinDigit({required bool confirm}) {
    setState(() {
      if (confirm) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else if (_newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      }
    });
  }

  void _clearPinDigit({required bool confirm}) {
    setState(() {
      if (confirm) {
        _confirmPin = '';
      } else {
        _newPin = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerSignupProvider);
    final title = switch (_step) {
      _SignupStep.form => 'Create your garage',
      _SignupStep.verify => 'Verify WhatsApp',
      _SignupStep.setPin => 'Set your PIN',
      _SignupStep.loginMethod => 'Sign-in method',
    };

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textSecondary),
          onPressed: _step == _SignupStep.form
              ? () => context.pop()
              : () => setState(() {
                    if (_step == _SignupStep.verify) {
                      _step = _SignupStep.form;
                    } else if (_step == _SignupStep.setPin) {
                      _step = _SignupStep.verify;
                    } else if (_step == _SignupStep.loginMethod) {
                      _step = _SignupStep.setPin;
                    }
                    _stepError = null;
                  }),
        ),
        title: Text(title, style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_infoMessage != null && _step != _SignupStep.form) ...[
            Text(
              _infoMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
          ],
          if (_step == _SignupStep.form) ...[
            Text(
              'Start your 14-day trial. Verify your WhatsApp number on this screen to set your PIN.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            _label('Garage name'),
            _field(_businessController, 'Patel Auto Works'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Your first name'),
                      _field(_firstNameController, 'Sagar'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Last name'),
                      _field(_lastNameController, 'Patel'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _label('Mobile (WhatsApp)'),
            _field(_phoneController, '9876543210', keyboard: TextInputType.phone),
            if (_phoneDigits.length == 10) ...[
              const SizedBox(height: 8),
              Text(
                'We will send a verification code to this WhatsApp number after you create your account.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange),
              ),
            ],
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
              onPressed: state.isLoading ? null : _submitForm,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.go('/auth/login'),
                child: Text('Already have an account? Sign in', style: AppTextStyles.bodySmall),
              ),
            ),
          ],
          if (_step == _SignupStep.verify) ...[
            Text(
              _phoneMasked != null
                  ? 'Enter the code sent to $_phoneMasked.'
                  : 'Tap below to send a verification code to your WhatsApp number.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_stepError != null) ...[
              ApiErrorView(message: _stepError!),
              const SizedBox(height: 16),
            ],
            if (_phoneMasked == null)
              AppButton(
                label: 'Send WhatsApp code',
                isLoading: _stepLoading,
                onPressed: _stepLoading ? null : _sendOtp,
              )
            else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Verify code',
                isLoading: _stepLoading,
                onPressed: _stepLoading ? null : _proceedToPinSetup,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _stepLoading ? null : _sendOtp,
                child: const Text('Resend code'),
              ),
            ],
          ],
          if (_step == _SignupStep.setPin) ...[
            Text(
              'Choose a 6-digit PIN for staff sign-in.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_stepError != null) ...[
              ApiErrorView(message: _stepError!),
              const SizedBox(height: 16),
            ],
            _SetPinPanel(
              newPin: _newPin,
              confirmPin: _confirmPin,
              hasError: _stepError != null,
              onDigit: _addPinDigit,
              onDelete: _deletePinDigit,
              onClear: _clearPinDigit,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save PIN',
              isLoading: _stepLoading,
              onPressed: _stepLoading ? null : _savePin,
            ),
          ],
          if (_step == _SignupStep.loginMethod) ...[
            Text(
              'You can use your PIN every time, or enable fingerprint / Face ID for quick sign-in on this device.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (_stepError != null) ...[
              ApiErrorView(message: _stepError!),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: kIsWeb ? 'Continue with PIN' : 'Enable biometrics & continue',
              isLoading: _stepLoading,
              onPressed: _stepLoading ? null : () => _finish(enableBiometric: !kIsWeb),
            ),
            const SizedBox(height: 8),
            if (!kIsWeb)
              TextButton(
                onPressed: _stepLoading ? null : () => _finish(enableBiometric: false),
                child: const Text('Use PIN only'),
              ),
          ],
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

class _SetPinPanel extends StatelessWidget {
  final String newPin;
  final String confirmPin;
  final bool hasError;
  final void Function(String digit, {required bool confirm}) onDigit;
  final void Function({required bool confirm}) onDelete;
  final void Function({required bool confirm}) onClear;

  const _SetPinPanel({
    required this.newPin,
    required this.confirmPin,
    required this.hasError,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  bool get _confirming => newPin.length >= 6;

  @override
  Widget build(BuildContext context) {
    final pinsMismatch =
        newPin.length == 6 && confirmPin.length == 6 && newPin != confirmPin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PinFieldBlock(
          label: 'NEW PIN',
          value: newPin,
          active: !_confirming,
          complete: newPin.length == 6,
          hasError: hasError && pinsMismatch,
        ),
        const SizedBox(height: 12),
        _PinFieldBlock(
          label: 'CONFIRM PIN',
          value: confirmPin,
          active: _confirming && confirmPin.length < 6,
          complete: confirmPin.length == 6 && !pinsMismatch,
          hasError: hasError && pinsMismatch,
          dimmed: !_confirming,
        ),
        const SizedBox(height: 20),
        StaffPinPad(
          enabled: true,
          headerText: _confirming ? 'KEYPAD · CONFIRM PIN' : 'KEYPAD · NEW PIN',
          headerColor: AppColors.primaryOrange,
          onDigit: (d) => onDigit(d, confirm: _confirming),
          onDelete: () => onDelete(confirm: _confirming),
          onClear: () => onClear(confirm: _confirming),
        ),
      ],
    );
  }
}

class _PinFieldBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final bool complete;
  final bool hasError;
  final bool dimmed;

  const _PinFieldBlock({
    required this.label,
    required this.value,
    required this.active,
    this.complete = false,
    this.hasError = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.statusRed
        : active
            ? AppColors.primaryOrange
            : complete
                ? AppColors.statusGreen
                : AppColors.divider;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryOrangeDim : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: active || hasError ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 0.13 * 9,
                color: active ? AppColors.primaryOrange : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            _PinDotsRow(value: value, hasError: hasError),
          ],
        ),
      ),
    );
  }
}

class _PinDotsRow extends StatelessWidget {
  final String value;
  final bool hasError;

  const _PinDotsRow({required this.value, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final filled = i < value.length;
        Color dotColor;
        Color borderColor;
        if (hasError) {
          dotColor = AppColors.statusRed;
          borderColor = AppColors.statusRed;
        } else if (filled) {
          dotColor = AppColors.primaryOrange;
          borderColor = AppColors.primaryOrange;
        } else {
          dotColor = Colors.transparent;
          borderColor = AppColors.textMuted.withValues(alpha: 0.35);
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: i == 0 || i == 5 ? 0 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.elasticOut,
            width: filled ? 15 : 13,
            height: filled ? 15 : 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: filled && !hasError
                  ? [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 7,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
