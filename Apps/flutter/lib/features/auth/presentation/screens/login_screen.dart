import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../../../onboarding/presentation/utils/post_login_navigation.dart';
import '../providers/staff_login_provider.dart';

const Color _skyBlue = Color(0xFF2BB0ED);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _usePhone = true;

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onIdentifierChanged() {
    final notifier = ref.read(staffLoginProvider.notifier);
    if (_usePhone) {
      final digits = _phoneController.text.trim();
      if (digits.length == 10) {
        notifier.setCurrentLogin('+91$digits');
      } else {
        notifier.setCurrentLogin('');
      }
    } else {
      notifier.setCurrentLogin(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffLoginProvider);
    final notifier = ref.read(staffLoginProvider.notifier);

    ref.listen<StaffLoginState>(staffLoginProvider, (prev, next) {
      if (next.needsPinSetup && prev?.needsPinSetup != true) {
        final login = next.currentLogin.isNotEmpty
            ? next.currentLogin
            : (_usePhone ? _phoneController.text.trim() : _emailController.text.trim());
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF111420),
        resizeToAvoidBottomInset: true,
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
                                phoneController: _phoneController,
                                emailController: _emailController,
                                onToggle: (usePhone) {
                                  setState(() {
                                    _usePhone = usePhone;
                                    _phoneController.clear();
                                    _emailController.clear();
                                    notifier.setCurrentLogin('');
                                  });
                                },
                                onChanged: _onIdentifierChanged,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _usePhone
                                    ? 'Enter 10-digit mobile number, then your 6-digit PIN'
                                    : 'Enter email, then your 6-digit PIN',
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
                              _PinPad(
                                enabled: !state.isLocked && !state.isLoading,
                                onDigit: notifier.addDigit,
                                onDelete: notifier.deleteDigit,
                                onClear: notifier.clearPin,
                                onBiometric: notifier.triggerBiometric,
                              ),
                              const SizedBox(height: 8),
                              _buildForgotPin(state),
                              const SizedBox(height: 24),
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
              _LockedOverlay(secondsRemaining: state.lockSecondsRemaining),
          ],
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
            : (_usePhone ? _phoneController.text.trim() : _emailController.text.trim());
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
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final void Function(bool) onToggle;
  final VoidCallback onChanged;

  const _IdentifierInput({
    required this.usePhone,
    required this.phoneController,
    required this.emailController,
    required this.onToggle,
    required this.onChanged,
  });

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
          // Full-width segmented toggle
          Container(
            height: 40,
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
                    isLeft: true,
                    onTap: () => onToggle(true),
                  ),
                ),
                Container(width: 0.5, height: 20, color: Colors.white.withOpacity(0.10)),
                Expanded(
                  child: _SegmentTab(
                    label: 'Email',
                    icon: PhosphorIconsRegular.envelope,
                    selected: !usePhone,
                    isLeft: false,
                    onTap: () => onToggle(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Input field — same width as toggle, no layout jump
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: usePhone
                ? _PhoneField(
                    key: const ValueKey('phone'),
                    controller: phoneController,
                    onChanged: onChanged,
                  )
                : _EmailField(
                    key: const ValueKey('email'),
                    controller: emailController,
                    onChanged: onChanged,
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
  final bool isLeft;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? _skyBlue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(9) : Radius.zero,
            right: !isLeft ? const Radius.circular(9) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}

class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _PhoneField({super.key, required this.controller, required this.onChanged});

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? _skyBlue : Colors.white.withOpacity(0.10),
          width: _focused ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // +91 prefix — fixed, never moves
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Text(
              '+91',
              style: GoogleFonts.dmMono(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _skyBlue,
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.12),
          ),
          // Number input
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              keyboardAppearance: Brightness.dark,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.dmMono(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.90),
                letterSpacing: 2,
              ),
              onChanged: (_) => widget.onChanged(),
              decoration: InputDecoration(
                hintText: '00000 00000',
                hintStyle: GoogleFonts.dmMono(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.20),
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 12, right: 16),
                isDense: true,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? _skyBlue : Colors.white.withOpacity(0.10),
          width: _focused ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              PhosphorIconsRegular.envelope,
              size: 18,
              color: _focused ? _skyBlue : Colors.white.withOpacity(0.35),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.dark,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: Colors.white.withOpacity(0.90),
              ),
              onChanged: (_) => widget.onChanged(),
              decoration: InputDecoration(
                hintText: 'you@garage.com',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.20),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(right: 16),
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
// PIN pad
// ---------------------------------------------------------------------------

class _PinPad extends StatelessWidget {
  final bool enabled;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onBiometric;

  const _PinPad({
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
    required this.onBiometric,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  static const _subLabels = {
    '2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL',
    '6': 'MNO', '7': 'PQRS', '8': 'TUV', '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map((d) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _PinKey(
                          label: d,
                          subLabel: _subLabels[d],
                          enabled: enabled,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onDigit(d);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _PinKey(
                icon: Icon(PhosphorIconsRegular.fingerprint,
                    size: 24, color: const Color(0xA6FFFFFF)),
                enabled: enabled,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBiometric();
                },
                opacity: 0.7,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _PinKey(
                label: '0',
                enabled: enabled,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDigit('0');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _PinKey(
                icon: Icon(PhosphorIconsRegular.backspace,
                    size: 20, color: const Color(0x99FFFFFF)),
                enabled: enabled,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDelete();
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  onClear();
                },
                opacity: 0.7,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatefulWidget {
  final String? label;
  final String? subLabel;
  final Widget? icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double opacity;

  const _PinKey({
    this.label,
    this.subLabel,
    this.icon,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
    this.opacity = 1.0,
  });

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _pressController.forward() : null,
      onTapUp: widget.enabled ? (_) => _pressController.reverse() : null,
      onTapCancel: () => _pressController.reverse(),
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Opacity(
          opacity: widget.enabled ? widget.opacity : 0.30,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.048),
              border:
                  Border.all(color: Colors.white.withOpacity(0.11), width: 0.5),
            ),
            child: widget.icon != null
                ? Center(child: widget.icon)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.90),
                        ),
                      ),
                      if (widget.subLabel != null)
                        Text(
                          widget.subLabel!,
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.30),
                            letterSpacing: 0.08 * 8,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
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
      color: const Color(0xFF102A43),
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x170A7DBF), Colors.transparent],
              stops: [0.0, 0.68],
            ),
          ),
        ),
      ),
    );
  }
}
