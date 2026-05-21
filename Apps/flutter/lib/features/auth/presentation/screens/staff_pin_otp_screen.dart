import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
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
            Text('New PIN', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            _PinDots(value: _newPin),
            const SizedBox(height: 8),
            Text('Confirm PIN', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            _PinDots(value: _confirmPin),
            const SizedBox(height: 16),
            _PinPad(
              onDigit: (d) => _addPinDigit(d, confirm: _newPin.length >= 6),
              onDelete: () => _deletePinDigit(confirm: _newPin.length >= 6),
            ),
            const SizedBox(height: 16),
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

class _PinDots extends StatelessWidget {
  final String value;
  const _PinDots({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < value.length;
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primaryOrange : AppColors.divider,
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _PinPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return Material(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (key == '⌫') {
                onDelete();
              } else {
                onDigit(key);
              }
            },
            child: Center(
              child: Text(
                key,
                style: GoogleFonts.dmSans(fontSize: 22, color: AppColors.textPrimary),
              ),
            ),
          ),
        );
      },
    );
  }
}
