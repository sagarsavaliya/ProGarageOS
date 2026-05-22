import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/inspection_models.dart';

/// Top-down vehicle silhouette with tappable damage zones.
/// Coordinates match `Briefs/Design files/07-Intake-Inspection.html` viewBox 100×190.
class VehicleDamageZone {
  final String name;
  final Rect rect;
  final Offset dotCenter;

  const VehicleDamageZone({
    required this.name,
    required this.rect,
    required this.dotCenter,
  });
}

const vehicleDamageZones = <VehicleDamageZone>[
  VehicleDamageZone(name: 'Front Bumper', rect: Rect.fromLTWH(10, 10, 78, 22), dotCenter: Offset(49, 21)),
  VehicleDamageZone(name: 'Hood', rect: Rect.fromLTWH(14, 20, 70, 34), dotCenter: Offset(49, 37)),
  VehicleDamageZone(name: 'Front Left Fender', rect: Rect.fromLTWH(10, 38, 16, 30), dotCenter: Offset(18, 53)),
  VehicleDamageZone(name: 'Front Right Fender', rect: Rect.fromLTWH(72, 38, 16, 30), dotCenter: Offset(80, 53)),
  VehicleDamageZone(name: 'Left Door', rect: Rect.fromLTWH(10, 66, 16, 50), dotCenter: Offset(18, 91)),
  VehicleDamageZone(name: 'Right Door', rect: Rect.fromLTWH(72, 66, 16, 50), dotCenter: Offset(80, 91)),
  VehicleDamageZone(name: 'Rear Left Fender', rect: Rect.fromLTWH(10, 114, 16, 28), dotCenter: Offset(18, 128)),
  VehicleDamageZone(name: 'Rear Right Fender', rect: Rect.fromLTWH(72, 114, 16, 28), dotCenter: Offset(80, 128)),
  VehicleDamageZone(name: 'Boot/Trunk', rect: Rect.fromLTWH(14, 126, 70, 34), dotCenter: Offset(49, 143)),
  VehicleDamageZone(name: 'Rear Bumper', rect: Rect.fromLTWH(10, 156, 78, 22), dotCenter: Offset(49, 167)),
  VehicleDamageZone(name: 'Roof', rect: Rect.fromLTWH(22, 66, 54, 48), dotCenter: Offset(49, 90)),
];

class VehicleDamageMap extends StatelessWidget {
  final Map<String, DamageSeverity> damageZones;
  final void Function(String zone) onZoneTap;
  final VoidCallback? onClearAll;

  const VehicleDamageMap({
    super.key,
    required this.damageZones,
    required this.onZoneTap,
    this.onClearAll,
  });

  static const _viewBox = Size(100, 190);

  @override
  Widget build(BuildContext context) {
    final marked = damageZones.entries.where((e) => e.value != DamageSeverity.none).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAMAGE MAP', style: _sectionTitleStyle()),
              const Spacer(),
              if (onClearAll != null && marked.isNotEmpty)
                TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: AspectRatio(
                  aspectRatio: _viewBox.width / _viewBox.height,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scaleX = constraints.maxWidth / _viewBox.width;
                      final scaleY = constraints.maxHeight / _viewBox.height;

                      Offset scalePoint(Offset p) => Offset(p.dx * scaleX, p.dy * scaleY);
                      Rect scaleRect(Rect r) => Rect.fromLTWH(
                            r.left * scaleX,
                            r.top * scaleY,
                            r.width * scaleX,
                            r.height * scaleY,
                          );

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _VehicleBodyPainter(),
                          ),
                          ...vehicleDamageZones.map((zone) {
                            final sev = damageZones[zone.name] ?? DamageSeverity.none;
                            if (sev == DamageSeverity.none) return const SizedBox.shrink();
                            final center = scalePoint(zone.dotCenter);
                            final color = sev == DamageSeverity.major
                                ? AppColors.statusRed
                                : AppColors.statusOrange;
                            return Positioned(
                              left: center.dx - 5,
                              top: center.dy - 5,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.45),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          ...vehicleDamageZones.map((zone) {
                            final rect = scaleRect(zone.rect);
                            final sev = damageZones[zone.name] ?? DamageSeverity.none;
                            final highlight = switch (sev) {
                              DamageSeverity.minor => AppColors.statusOrange.withValues(alpha: 0.25),
                              DamageSeverity.major => AppColors.statusRed.withValues(alpha: 0.28),
                              _ => Colors.transparent,
                            };
                            return Positioned(
                              left: rect.left,
                              top: rect.top,
                              width: rect.width,
                              height: rect.height,
                              child: Material(
                                color: highlight,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    onZoneTap(zone.name);
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: AppColors.statusOrange, label: 'Minor'),
                    const SizedBox(height: 4),
                    _LegendRow(color: AppColors.statusRed, label: 'Major'),
                    const SizedBox(height: 8),
                    Text(
                      'Tap car zones to mark damage. Tap again to escalate or clear.',
                      style: AppTextStyles.labelSmall.copyWith(height: 1.4),
                    ),
                    if (marked.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...marked.map((entry) {
                        final color = entry.value == DamageSeverity.major
                            ? AppColors.statusRed
                            : AppColors.statusOrange;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: AppTextStyles.labelSmall.copyWith(color: color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _VehicleBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 190;

    RRect r(double x, double y, double w, double h, double radius) {
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy),
        Radius.circular(radius * sx),
      );
    }

    final shadow = Paint()..color = const Color(0x140A0E14);
    canvas.drawRRect(r(12, 12, 78, 168, 18), shadow);

    final bodyFill = Paint()..color = const Color(0xFFEEF2F6);
    final bodyStroke = Paint()
      ..color = const Color(0xFFDDE5EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final body = r(10, 10, 78, 168, 18);
    canvas.drawRRect(body, bodyFill);
    canvas.drawRRect(body, bodyStroke);

    final wheel = Paint()..color = const Color(0xB38898AA);
    canvas.drawRRect(r(2, 38, 12, 24, 4), wheel);
    canvas.drawRRect(r(86, 38, 12, 24, 4), wheel);
    canvas.drawRRect(r(2, 128, 12, 24, 4), wheel);
    canvas.drawRRect(r(86, 128, 12, 24, 4), wheel);

    canvas.drawRRect(r(14, 14, 70, 40, 14), Paint()..color = const Color(0xFFE0E8F0));
    canvas.drawRRect(r(18, 54, 62, 12, 4), Paint()..color = const Color(0xCCB8C5D0));
    canvas.drawRRect(r(16, 66, 66, 48, 6), Paint()..color = const Color(0xFFD4DCE5));
    canvas.drawRRect(r(18, 114, 62, 12, 4), Paint()..color = const Color(0xCCB8C5D0));
    canvas.drawRRect(r(14, 126, 70, 38, 12), Paint()..color = const Color(0xFFE0E8F0));
    canvas.drawRRect(r(10, 158, 78, 20, 12), Paint()..color = const Color(0xFFD4DCE5));

    final frontLabel = TextPainter(
      text: TextSpan(
        text: '▲ FRONT',
        style: GoogleFonts.dmSans(fontSize: 7 * sx, color: const Color(0xFF8898AA)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    frontLabel.paint(canvas, Offset((49 * sx) - frontLabel.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

TextStyle _sectionTitleStyle() => GoogleFonts.sora(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
    );
