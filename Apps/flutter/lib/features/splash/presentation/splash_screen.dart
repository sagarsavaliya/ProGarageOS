import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/storage/secure_storage.dart';

// Sky blue accent used only in the splash wordmark
const Color _skyBlue = Color(0xFF2BB0ED);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _showCta = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Start animation after 320ms delay (matches HTML: 320ms both)
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _ctrl.forward();
    });

    // Show CTA button after 3s
    Future.delayed(const Duration(milliseconds: 3050), () {
      if (mounted) setState(() => _showCta = true);
    });

    // Auto-navigate after 5s if user doesn't tap
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_navigating) _navigate();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (_navigating) return;
    _navigating = true;
    if (!mounted) return;
    final hasToken = await ref.read(secureStorageProvider).hasToken();
    if (!mounted) return;
    context.go(hasToken ? '/dashboard' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Dot grid texture
            const _DotGridPainterWidget(),

            // Ambient sky glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x1A0A7DBF), Colors.transparent],
                      radius: 0.7,
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -40, 0),
                ),
              ),
            ),

            // Centered wordmark
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: const _WordmarkGroup(),
                ),
              ),
            ),

            // Continue button
            Positioned(
              bottom: 76,
              left: 32,
              right: 32,
              child: AnimatedOpacity(
                opacity: _showCta ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 380),
                child: Center(
                  child: GestureDetector(
                    onTap: _navigate,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _skyBlue.withOpacity(0.36),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue to Login',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: _skyBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Icon(PhosphorIconsRegular.arrowRight, color: _skyBlue, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wordmark group
// ---------------------------------------------------------------------------

class _WordmarkGroup extends StatelessWidget {
  const _WordmarkGroup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accent bar: ──● ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 22, height: 0.5, color: _skyBlue.withOpacity(0.45)),
            const SizedBox(width: 6),
            const _PulsingDot(),
            const SizedBox(width: 6),
            Container(width: 22, height: 0.5, color: _skyBlue.withOpacity(0.45)),
          ],
        ),
        const SizedBox(height: 14),
        // Wordmark
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Pro',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.92),
                  letterSpacing: -1.0,
                ),
              ),
              TextSpan(
                text: 'Garage',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: _skyBlue,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Tagline
        Text(
          'PRO GARAGE OS',
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.22),
            letterSpacing: 0.14 * 10,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing dot
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(color: _skyBlue, shape: BoxShape.circle),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot grid painter
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
    const gridSize = 28.0;
    const offset = 14.0;
    final paint = Paint()..color = Colors.white.withOpacity(0.028);

    for (double x = offset; x < size.width; x += gridSize) {
      for (double y = offset; y < size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

