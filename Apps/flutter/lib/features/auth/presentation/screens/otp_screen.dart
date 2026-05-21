import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';
import '../../../../core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// OTP State
// ---------------------------------------------------------------------------

enum OtpStatus { enterPhone, sendingOtp, awaitingOtp, verifying, success, error }

class OtpState {
  final OtpStatus status;
  final String phone;
  final String otp;
  final String? errorMessage;
  final int resendCooldown;

  const OtpState({
    this.status = OtpStatus.enterPhone,
    this.phone = '',
    this.otp = '',
    this.errorMessage,
    this.resendCooldown = 0,
  });

  OtpState copyWith({
    OtpStatus? status,
    String? phone,
    String? otp,
    String? errorMessage,
    bool clearError = false,
    int? resendCooldown,
  }) =>
      OtpState(
        status: status ?? this.status,
        phone: phone ?? this.phone,
        otp: otp ?? this.otp,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        resendCooldown: resendCooldown ?? this.resendCooldown,
      );
}

// ---------------------------------------------------------------------------
// OTP Notifier
// ---------------------------------------------------------------------------

class OtpNotifier extends StateNotifier<OtpState> {
  final AuthRepository _repo;
  final SecureStorageService _storage;
  Timer? _cooldownTimer;

  OtpNotifier(this._repo, this._storage) : super(const OtpState());

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(phone: phone, status: OtpStatus.sendingOtp, clearError: true);
    try {
      final cooldown = await _repo.requestOtp(phone);
      state = state.copyWith(status: OtpStatus.awaitingOtp, resendCooldown: cooldown);
      _startCooldown();
    } catch (_) {
      state = state.copyWith(
        status: OtpStatus.error,
        errorMessage: 'Failed to send OTP. Check the number and retry.',
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: OtpStatus.verifying, otp: otp, clearError: true);
    try {
      final response = await _repo.verifyOtp(OtpVerifyRequest(phone: state.phone, otp: otp));
      await _storage.saveToken(response.token);
      await _storage.saveUserJson(response.user.toJsonString());
      state = state.copyWith(status: OtpStatus.success);
    } catch (_) {
      state = state.copyWith(
        status: OtpStatus.awaitingOtp,
        otp: '',
        errorMessage: 'Invalid OTP. Please try again.',
      );
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.resendCooldown - 1;
      if (remaining <= 0) {
        _cooldownTimer?.cancel();
        state = state.copyWith(resendCooldown: 0);
      } else {
        state = state.copyWith(resendCooldown: remaining);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}

final otpProvider = StateNotifierProvider.autoDispose<OtpNotifier, OtpState>((ref) {
  return OtpNotifier(ref.watch(authRepositoryProvider), ref.watch(secureStorageProvider));
});

// ---------------------------------------------------------------------------
// OTP Screen
// ---------------------------------------------------------------------------

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpProvider);
    final notifier = ref.read(otpProvider.notifier);

    ref.listen<OtpState>(otpProvider, (prev, next) {
      if (next.status == OtpStatus.success) {
        context.go('/dashboard');
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxxl, vertical: AppSizes.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  icon: Icon(PhosphorIconsRegular.caretLeft, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: AppSizes.xxl),
                // Title
                Text(
                  state.status == OtpStatus.enterPhone ? 'Customer Login' : 'Enter OTP',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  state.status == OtpStatus.enterPhone
                      ? 'Enter your registered mobile number to receive a one-time password.'
                      : 'We sent a 6-digit code to ${_maskPhone(state.phone)}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSizes.xxxl),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.status == OtpStatus.enterPhone ||
                          state.status == OtpStatus.sendingOtp ||
                          state.status == OtpStatus.error
                      ? _PhoneInput(
                          controller: _phoneController,
                          isLoading: state.status == OtpStatus.sendingOtp,
                          errorMessage: state.status == OtpStatus.error ? state.errorMessage : null,
                          onSubmit: () {
                            if (_phoneController.text.isNotEmpty) {
                              notifier.requestOtp(_phoneController.text.trim());
                            }
                          },
                        )
                      : _OtpInput(
                          controllers: _otpControllers,
                          focusNodes: _otpFocusNodes,
                          isVerifying: state.status == OtpStatus.verifying,
                          errorMessage: state.errorMessage,
                          resendCooldown: state.resendCooldown,
                          onResend: () => notifier.requestOtp(state.phone),
                          onComplete: (otp) => notifier.verifyOtp(otp),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}';
  }
}

// ---------------------------------------------------------------------------
// Phone input widget
// ---------------------------------------------------------------------------

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _PhoneInput({
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('phone-input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: AppTextStyles.bodyLarge,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: InputDecoration(
            prefixText: '+91  ',
            prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            hintText: '9876543210',
            hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            errorText: errorMessage,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppSizes.lg),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Send OTP', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OTP input widget
// ---------------------------------------------------------------------------

class _OtpInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isVerifying;
  final String? errorMessage;
  final int resendCooldown;
  final VoidCallback onResend;
  final void Function(String) onComplete;

  const _OtpInput({
    required this.controllers,
    required this.focusNodes,
    required this.isVerifying,
    required this.errorMessage,
    required this.resendCooldown,
    required this.onResend,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('otp-input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: AppTextStyles.titleLarge,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  errorText: null,
                  filled: true,
                  fillColor: errorMessage != null ? AppColors.statusRedBg : AppColors.bgElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: errorMessage != null ? AppColors.statusRed : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide(
                      color: errorMessage != null ? AppColors.statusRed : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) {
                  if (v.length == 1) {
                    if (i < 5) {
                      focusNodes[i + 1].requestFocus();
                    } else {
                      focusNodes[i].unfocus();
                      final otp = controllers.map((c) => c.text).join();
                      if (otp.length == 6) onComplete(otp);
                    }
                  } else if (v.isEmpty && i > 0) {
                    focusNodes[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text(errorMessage!, style: AppTextStyles.labelMedium.copyWith(color: AppColors.statusRed)),
        ],
        const SizedBox(height: AppSizes.lg),
        SizedBox(
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: isVerifying
                ? null
                : () {
                    final otp = controllers.map((c) => c.text).join();
                    if (otp.length == 6) onComplete(otp);
                  },
            child: isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Verify OTP', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Center(
          child: resendCooldown > 0
              ? Text(
                  'Resend OTP in ${resendCooldown}s',
                  style: AppTextStyles.bodyMedium,
                )
              : TextButton(
                  onPressed: onResend,
                  child: Text(
                    'Resend OTP',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryOrange),
                  ),
                ),
        ),
      ],
    );
  }
}
