import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/staff_pin_pad.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/auth_models.dart';

enum StaffPinOtpStep { request, verify, setPin, done }

class StaffPinOtpScreen extends ConsumerStatefulWidget {
  final String login;
  final String purpose; // setup | reset

  const StaffPinOtpScreen({
    super.key,
    required this.login,
    this.purpose = 'reset',
  });

  @override
  ConsumerState<StaffPinOtpScreen> createState() => _StaffPinOtpScreenState();
}

class _StaffPinOtpScreenState extends ConsumerState<StaffPinOtpScreen> {
  StaffPinOtpStep _step = StaffPinOtpStep.request;
  bool _loading = false;
  String? _error;
  String? _phoneMasked;
  final _otpController = TextEditingController();
  String _newPin = '';
  String _confirmPin = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final masked = await ref.read(authRepositoryProvider).requestStaffPinOtp(
            StaffPinOtpRequest(login: widget.login, purpose: widget.purpose),
          );
      setState(() {
        _phoneMasked = masked;
        _step = StaffPinOtpStep.verify;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = failureMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtpAndProceed() async {
    if (_otpController.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from WhatsApp.');
      return;
    }
    setState(() {
      _error = null;
      _step = StaffPinOtpStep.setPin;
      _newPin = '';
      _confirmPin = '';
    });
  }

  Future<void> _submitNewPin() async {
    if (_newPin.length != 6 || _confirmPin.length != 6) {
      setState(() => _error = 'PIN must be 6 digits.');
      return;
    }
    if (_newPin != _confirmPin) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetStaffPin(
            StaffPinResetRequest(
              login: widget.login,
              otp: _otpController.text.trim(),
              pin: _newPin,
            ),
          );
      setState(() {
        _step = StaffPinOtpStep.done;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = failureMessage(e);
        _loading = false;
      });
    }
  }

  void _addPinDigit(String digit, {required bool confirm}) {
    setState(() {
      _error = null;
      if (confirm) {
        if (_confirmPin.length < 6) _confirmPin += digit;
      } else {
        if (_newPin.length < 6) _newPin += digit;
      }
    });
    if (confirm && _confirmPin.length == 6) {
      _submitNewPin();
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
    final title = widget.purpose == 'setup' ? 'Set up your PIN' : 'Reset PIN';
    final subtitle = switch (_step) {
      StaffPinOtpStep.request => 'We will send a verification code to your registered WhatsApp number.',
      StaffPinOtpStep.verify => 'Enter the code sent to ${_phoneMasked ?? 'your phone'}.',
      StaffPinOtpStep.setPin => 'Choose a new 6-digit PIN.',
      StaffPinOtpStep.done => 'Your PIN is ready. Sign in with your new PIN.',
    };

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
        ),
        title: Text(title, style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          if (_error != null) ...[
            ApiErrorView(message: _error!),
            const SizedBox(height: 16),
          ],
          if (_step == StaffPinOtpStep.request)
            FilledButton(
              onPressed: _loading ? null : _requestOtp,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send WhatsApp code'),
            ),
          if (_step == StaffPinOtpStep.verify) ...[
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
            FilledButton(
              onPressed: _verifyOtpAndProceed,
              child: const Text('Continue'),
            ),
          ],
          if (_step == StaffPinOtpStep.setPin) ...[
            _SetPinPanel(
              newPin: _newPin,
              confirmPin: _confirmPin,
              hasError: _error != null,
              onDigit: _addPinDigit,
              onDelete: _deletePinDigit,
              onClear: _clearPinDigit,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submitNewPin,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save PIN'),
            ),
          ],
          if (_step == StaffPinOtpStep.done)
            FilledButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Back to sign in'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Set PIN — aligned labels + dots + keypad (matches login screen language)
// ---------------------------------------------------------------------------

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
    final pinsMismatch = newPin.length == 6 &&
        confirmPin.length == 6 &&
        newPin != confirmPin;

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
          color: active
              ? AppColors.primaryOrangeDim
              : AppColors.bgSurface,
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
                color: active
                    ? AppColors.primaryOrange
                    : AppColors.textMuted,
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
