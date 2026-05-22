import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_colors.dart';

/// Unified staff auth PIN keypad — used on login and reset/setup PIN flows.
class StaffPinPad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onClear;
  final VoidCallback? onBiometric;
  final String? headerText;
  final Color headerColor;

  const StaffPinPad({
    super.key,
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    this.onClear,
    this.onBiometric,
    this.headerText,
    this.headerColor = AppColors.accent,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  static const _subLabels = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              headerText!,
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 0.12 * 9,
                color: headerColor.withValues(alpha: 0.75),
              ),
            ),
          ),
        ..._rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: StaffPinKey(
                        label: d,
                        subLabel: _subLabels[d],
                        enabled: enabled,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onDigit(d);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: onBiometric != null
                  ? StaffPinKey(
                      icon: Icon(
                        PhosphorIconsRegular.fingerprint,
                        size: 24,
                        color: const Color(0xA6FFFFFF),
                      ),
                      enabled: enabled,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onBiometric!();
                      },
                      opacity: 0.7,
                    )
                  : const SizedBox(width: 64, height: 64),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: StaffPinKey(
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
              child: StaffPinKey(
                icon: Icon(
                  PhosphorIconsRegular.backspace,
                  size: 20,
                  color: const Color(0x99FFFFFF),
                ),
                enabled: enabled,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDelete();
                },
                onLongPress: onClear == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onClear!();
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

class StaffPinKey extends StatefulWidget {
  final String? label;
  final String? subLabel;
  final Widget? icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double opacity;

  const StaffPinKey({
    super.key,
    this.label,
    this.subLabel,
    this.icon,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
    this.opacity = 1.0,
  });

  @override
  State<StaffPinKey> createState() => _StaffPinKeyState();
}

class _StaffPinKeyState extends State<StaffPinKey> with SingleTickerProviderStateMixin {
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
              color: Colors.white.withValues(alpha: 0.048),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.11),
                width: 0.5,
              ),
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
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                      if (widget.subLabel != null)
                        Text(
                          widget.subLabel!,
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.30),
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
