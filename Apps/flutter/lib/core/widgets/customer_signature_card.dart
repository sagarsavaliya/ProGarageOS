import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'app_signature_pad.dart';

class CustomerSignatureCard extends StatefulWidget {
  final bool isDelivery;
  final bool signed;
  final ValueChanged<bool> onSignedChanged;
  final ValueChanged<bool>? onSigningActiveChanged;

  const CustomerSignatureCard({
    super.key,
    required this.isDelivery,
    required this.signed,
    required this.onSignedChanged,
    this.onSigningActiveChanged,
  });

  @override
  State<CustomerSignatureCard> createState() => _CustomerSignatureCardState();
}

class _CustomerSignatureCardState extends State<CustomerSignatureCard> {
  final _padKey = GlobalKey<AppSignaturePadState>();
  bool _hasInk = false;

  void _confirmSignature() {
    if (!_hasInk) return;
    HapticFeedback.mediumImpact();
    widget.onSignedChanged(true);
  }

  void _clear() {
    _padKey.currentState?.clear();
    widget.onSignedChanged(false);
    setState(() => _hasInk = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.signed ? AppColors.accent : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CUSTOMER ACKNOWLEDGMENT', style: _sectionTitleStyle()),
          const SizedBox(height: 6),
          Text(
            widget.isDelivery
                ? 'Customer signs to confirm vehicle condition at delivery'
                : 'Customer signs to acknowledge vehicle condition at intake',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          if (widget.signed)
            Row(
              children: [
                const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.statusGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signature captured',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusGreen),
                  ),
                ),
                TextButton(onPressed: _clear, child: const Text('Clear')),
              ],
            )
          else ...[
            AppSignaturePad(
              key: _padKey,
              onHasSignatureChanged: (v) => setState(() => _hasInk = v),
              onSigningActiveChanged: widget.onSigningActiveChanged,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _hasInk ? _confirmSignature : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(PhosphorIconsRegular.penNib, size: 18),
              label: Text(
                'Confirm signature',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _sectionTitleStyle() => GoogleFonts.sora(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
    );
