import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Lightweight signature canvas — no external package required.
class AppSignaturePad extends StatefulWidget {
  final ValueChanged<bool>? onHasSignatureChanged;
  final ValueChanged<bool>? onSigningActiveChanged;

  const AppSignaturePad({
    super.key,
    this.onHasSignatureChanged,
    this.onSigningActiveChanged,
  });

  @override
  State<AppSignaturePad> createState() => AppSignaturePadState();
}

class AppSignaturePadState extends State<AppSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  bool get hasSignature =>
      _strokes.any((stroke) => stroke.length > 1) ||
      _currentStroke.length > 1;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
    widget.onHasSignatureChanged?.call(false);
  }

  void _notify() {
    widget.onHasSignatureChanged?.call(hasSignature);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (!hasSignature)
              Center(
                child: Text(
                  'Sign here with your finger',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                HapticFeedback.selectionClick();
                widget.onSigningActiveChanged?.call(true);
                setState(() => _currentStroke = [e.localPosition]);
              },
              onPointerMove: (e) {
                setState(() => _currentStroke = [..._currentStroke, e.localPosition]);
                _notify();
              },
              onPointerUp: (_) {
                widget.onSigningActiveChanged?.call(false);
                if (_currentStroke.isNotEmpty) {
                  setState(() {
                    _strokes.add(_currentStroke);
                    _currentStroke = [];
                  });
                  _notify();
                }
              },
              onPointerCancel: (_) => widget.onSigningActiveChanged?.call(false),
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in [...strokes, if (currentStroke.isNotEmpty) currentStroke]) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke;
}
