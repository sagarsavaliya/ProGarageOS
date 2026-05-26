import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/staff_pin_pad.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../../../onboarding/presentation/utils/post_login_navigation.dart';
import '../providers/staff_login_provider.dart';

// Accent matches app theme (orange)
const Color _skyBlue = AppColors.accent;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _keyboardFocus = FocusNode();
  bool _usePhone = true;
  String _phoneDigits = '';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final savedDigits = ref.read(staffLoginProvider).savedPhoneDigits;
      if (savedDigits.isNotEmpty && _phoneDigits.isEmpty) {
        setState(() {
          _phoneDigits = savedDigits;
          _syncPhoneLogin(ref.read(staffLoginProvider.notifier));
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _keyboardFocus.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final loginState = ref.read(staffLoginProvider);
    if (loginState.isLocked || loginState.isLoading) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onPadDelete();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _onPadClear();
      return KeyEventResult.handled;
    }

    final label = event.character ?? event.logicalKey.keyLabel;
    if (label.length == 1 && RegExp(r'^\d$').hasMatch(label)) {
      _onPadDigit(label);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool get _phoneComplete => _phoneDigits.length == 10;

  bool _canEnterPin(StaffLoginState loginState) {
    if (loginState.isLocked || loginState.isLoading) return false;
    if (_usePhone) return _phoneComplete;
    return _emailController.text.trim().isNotEmpty;
  }

  void _syncPhoneLogin(StaffLoginNotifier notifier) {
    if (_phoneDigits.length == 10) {
      notifier.setCurrentLogin('+91$_phoneDigits');
    } else {
      notifier.setCurrentLogin('');
    }
  }

  void _onPadDigit(String digit) {
    final notifier = ref.read(staffLoginProvider.notifier);
    final loginState = ref.read(staffLoginProvider);
    if (loginState.isLocked || loginState.isLoading) return;

    if (_usePhone && !_phoneComplete) {
      setState(() {
        _phoneDigits += digit;
        _syncPhoneLogin(notifier);
      });
      return;
    }

    if (!_canEnterPin(loginState)) return;
    notifier.addDigit(digit);
  }

  void _onPadDelete() {
    final notifier = ref.read(staffLoginProvider.notifier);
    final loginState = ref.read(staffLoginProvider);
    if (loginState.isLocked || loginState.isLoading) return;

    if (loginState.pin.isNotEmpty) {
      notifier.deleteDigit();
      return;
    }

    if (_usePhone && _phoneDigits.isNotEmpty) {
      setState(() {
        _phoneDigits = _phoneDigits.substring(0, _phoneDigits.length - 1);
        _syncPhoneLogin(notifier);
      });
    }
  }

  void _onPadClear() {
    final notifier = ref.read(staffLoginProvider.notifier);
    final loginState = ref.read(staffLoginProvider);
    if (loginState.isLocked) return;

    if (loginState.pin.isNotEmpty) {
      notifier.clearPin();
      return;
    }

    if (_usePhone && _phoneDigits.isNotEmpty) {
      setState(() {
        _phoneDigits = '';
        notifier.setCurrentLogin('');
      });
    }
  }

  void _onIdentifierChanged() {
    if (_usePhone) return;
    setState(() {});
    ref.read(staffLoginProvider.notifier).setCurrentLogin(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffLoginProvider);
    final notifier = ref.read(staffLoginProvider.notifier);

    ref.listen<StaffLoginState>(staffLoginProvider, (prev, next) {
      if (_usePhone &&
          _phoneDigits.isEmpty &&
          next.savedPhoneDigits.isNotEmpty &&
          prev?.savedPhoneDigits != next.savedPhoneDigits) {
        setState(() {
          _phoneDigits = next.savedPhoneDigits;
          _syncPhoneLogin(notifier);
        });
      }
      if (next.needsPinSetup && prev?.needsPinSetup != true) {
        final login = next.currentLogin.isNotEmpty
            ? next.currentLogin
            : (_usePhone
                ? (_phoneDigits.length == 10 ? '+91$_phoneDigits' : '')
                : _emailController.text.trim());
        notifier.clearPinSetupRedirect();
        context.push('/auth/staff-pin', extra: {'login': login, 'purpose': 'setup'});
        return;
      }
      if (next.status == StaffLoginStatus.success) {
        ref.read(fcmServiceProvider).initialize().then((_) {
          ref.read(fcmServiceProvider).registerTokenIfAvailable();
        });
        resolvePostLoginRoute(ref).then((route) {
          if (context.mounted) context.go(route);
        });
      }
      if (next.status == StaffLoginStatus.error &&
          prev?.status == StaffLoginStatus.loading) {
        _shakeController
          ..reset()
          ..forward();
      }
    });

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF111420),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(child: _DotGridPainterWidget()),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.32,
              child: const _AmbientGlow(),
            ),
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 32),
                              _buildLogo(),
                              const SizedBox(height: 16),
                              _IdentifierInput(
                                usePhone: _usePhone,
                                phoneDigits: _phoneDigits,
                                emailController: _emailController,
                                onToggle: (usePhone) {
                                  setState(() {
                                    _usePhone = usePhone;
                                    _phoneDigits = '';
                                    _emailController.clear();
                                    notifier.setCurrentLogin('');
                                  });
                                },
                                onEmailChanged: _onIdentifierChanged,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _usePhone
                                    ? (_phoneComplete
                                        ? 'Enter your 6-digit PIN below'
                                        : 'Use the keypad for your 10-digit mobile number')
                                    : 'Enter email, then your 6-digit PIN on the keypad',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PinSection(
                                pin: state.pin,
                                status: state.status,
                                errorMessage: state.errorMessage,
                                shakeAnimation: _shakeAnimation,
                              ),
                              const SizedBox(height: 20),
                              StaffPinPad(
                                enabled: !state.isLocked &&
                                    !state.isLoading &&
                                    (_usePhone ? true : _emailController.text.trim().isNotEmpty || state.pin.isNotEmpty),
                                headerText: _usePhone && !_phoneComplete
                                    ? 'KEYPAD · MOBILE NUMBER'
                                    : null,
                                headerColor: _skyBlue,
                                onDigit: _onPadDigit,
                                onDelete: _onPadDelete,
                                onClear: _onPadClear,
                                onBiometric: () {
                                  if (_canEnterPin(state)) notifier.triggerBiometric();
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildForgotPin(state),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.push('/auth/signup'),
                                child: Text(
                                  'New garage? Create your account',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _skyBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLocked)
              Positioned.fill(
                child: _LockedOverlay(secondsRemaining: state.lockSecondsRemaining),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Pro',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.90),
                  letterSpacing: -0.022 * 26,
                ),
              ),
              TextSpan(
                text: 'Garage',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: _skyBlue,
                  letterSpacing: -0.022 * 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'STAFF PORTAL',
          style: AppTextStyles.labelSmall.copyWith(
            letterSpacing: 0.13 * 10,
            color: Colors.white.withOpacity(0.22),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPin(StaffLoginState state) {
    return TextButton(
      onPressed: () {
        final login = state.currentLogin.isNotEmpty
            ? state.currentLogin
            : (_usePhone
                ? (_phoneDigits.length == 10 ? '+91$_phoneDigits' : '')
                : _emailController.text.trim());
        if (login.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enter your phone or email first.',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withOpacity(0.70)),
              ),
              backgroundColor: const Color(0xFF161E2E).withOpacity(0.96),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        context.push('/auth/staff-pin', extra: {'login': login, 'purpose': 'reset'});
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.28),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Forgot PIN?',
        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Identifier input — phone/email toggle
// ---------------------------------------------------------------------------

class _IdentifierInput extends StatelessWidget {
  final bool usePhone;
  final String phoneDigits;
  final TextEditingController emailController;
  final void Function(bool) onToggle;
  final VoidCallback onEmailChanged;

  const _IdentifierInput({
    required this.usePhone,
    required this.phoneDigits,
    required this.emailController,
    required this.onToggle,
    required this.onEmailChanged,
  });

  static const _fieldHeight = 52.0;
  static const _toggleHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _toggleHeight,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentTab(
                      label: 'Phone',
                      icon: PhosphorIconsRegular.phone,
                      selected: usePhone,
                      onTap: () => onToggle(true),
                    ),
                  ),
                  Container(width: 0.5, color: Colors.white.withOpacity(0.10)),
                  Expanded(
                    child: _SegmentTab(
                      label: 'Email',
                      icon: PhosphorIconsRegular.envelope,
                      selected: !usePhone,
                      onTap: () => onToggle(false),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _fieldHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: usePhone
                  ? _PhoneField(
                      key: const ValueKey('phone'),
                      digits: phoneDigits,
                    )
                  : _EmailField(
                      key: const ValueKey('email'),
                      controller: emailController,
                      onChanged: onEmailChanged,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _skyBlue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? _skyBlue : Colors.white.withOpacity(0.35),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? _skyBlue : Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final String digits;

  const _PhoneField({super.key, required this.digits});

  String _formatDigits(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 5) return value;
    return '${value.substring(0, 5)} ${value.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final display = _formatDigits(digits);
    final hasDigits = digits.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDigits ? _skyBlue : Colors.white.withOpacity(0.10),
          width: hasDigits ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '+91',
            style: GoogleFonts.dmMono(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _skyBlue,
              height: 1,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white.withOpacity(0.12),
          ),
          Expanded(
            child: Text(
              hasDigits ? display : '00000 00000',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: GoogleFonts.dmMono(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: hasDigits
                    ? Colors.white.withOpacity(0.90)
                    : Colors.white.withOpacity(0.20),
                letterSpacing: 2,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _EmailField({super.key, required this.controller, required this.onChanged});

  @override
  State<_EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<_EmailField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_focus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? _skyBlue : Colors.white.withOpacity(0.10),
          width: _focused ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.envelope,
            size: 18,
            color: _focused ? _skyBlue : Colors.white.withOpacity(0.35),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.dark,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.2,
                color: Colors.white.withValues(alpha: 0.90),
              ),
              onChanged: (_) => widget.onChanged(),
              decoration: InputDecoration(
                hintText: 'you@garage.com',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.2,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PIN dots + message
// ---------------------------------------------------------------------------

class _PinSection extends StatelessWidget {
  final String pin;
  final StaffLoginStatus status;
  final String? errorMessage;
  final Animation<double> shakeAnimation;

  const _PinSection({
    required this.pin,
    required this.status,
    required this.errorMessage,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ENTER PIN',
          style: AppTextStyles.labelSmall.copyWith(
            letterSpacing: 0.13 * 9,
            color: Colors.white.withOpacity(0.22),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: shakeAnimation,
          builder: (_, child) {
            final dx = math.sin(shakeAnimation.value * math.pi * 6) *
                8 *
                (1 - shakeAnimation.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (i) {
              final isFilled = i < pin.length;
              final isError = status == StaffLoginStatus.error;
              Color dotColor;
              Color borderColor;
              if (isError) {
                dotColor = AppColors.statusRed;
                borderColor = AppColors.statusRed;
              } else if (isFilled) {
                dotColor = _skyBlue;
                borderColor = _skyBlue;
              } else {
                dotColor = Colors.transparent;
                borderColor = Colors.white.withOpacity(0.22);
              }
              return Container(
                margin: EdgeInsets.symmetric(horizontal: i == 0 || i == 5 ? 0 : 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.elasticOut,
                  width: isFilled ? 15 : 13,
                  height: isFilled ? 15 : 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isFilled && !isError
                        ? [
                            BoxShadow(
                                color: _skyBlue.withOpacity(0.38),
                                blurRadius: 7)
                          ]
                        : isError
                            ? [
                                BoxShadow(
                                    color: AppColors.statusRed.withOpacity(0.40),
                                    blurRadius: 8)
                              ]
                            : null,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: errorMessage != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            errorMessage ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.statusRed,
              letterSpacing: 0.02 * 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Locked overlay
// ---------------------------------------------------------------------------

class _LockedOverlay extends StatelessWidget {
  final int secondsRemaining;

  const _LockedOverlay({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final mins = secondsRemaining ~/ 60;
    final secs = secondsRemaining % 60;
    final timerStr = '$mins:${secs.toString().padLeft(2, '0')}';

    return Container(
      color: AppColors.bgPrimary,
      child: Stack(
        children: [
          const Positioned.fill(child: _DotGridPainterWidget()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC01E1E).withOpacity(0.10),
                  border: Border.all(
                      color: const Color(0xFFC01E1E).withOpacity(0.22),
                      width: 0.5),
                ),
                child: Icon(PhosphorIconsRegular.lock,
                    color: const Color(0xFFC01E1E), size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                'Account locked',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.015 * 20,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Too many incorrect attempts',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.white.withOpacity(0.28)),
              ),
              const SizedBox(height: 10),
              Text(
                timerStr,
                style: GoogleFonts.dmMono(
                  fontSize: 44,
                  fontWeight: FontWeight.w400,
                  color: _skyBlue,
                  letterSpacing: -0.02 * 44,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'seconds remaining',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: Colors.white.withOpacity(0.28)),
              ),
              const SizedBox(height: 8),
              Text(
                "You'll be able to try again shortly",
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: Colors.white.withOpacity(0.20)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot grid background
// ---------------------------------------------------------------------------

class _DotGridPainterWidget extends StatelessWidget {
  const _DotGridPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.028)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const dotRadius = 1.2;
    for (double x = 14; x < size.width; x += spacing) {
      for (double y = 14; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Ambient glow
// ---------------------------------------------------------------------------

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 360,
          height: 360,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppColors.accent.withValues(alpha: 0.09), Colors.transparent],
              stops: const [0.0, 0.68],
            ),
          ),
        ),
      ),
    );
  }
}
