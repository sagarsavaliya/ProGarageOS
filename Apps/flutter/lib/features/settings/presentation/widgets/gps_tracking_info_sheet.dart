import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class GpsTrackingInfoSheet extends StatelessWidget {
  const GpsTrackingInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const GpsTrackingInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(PhosphorIconsRegular.mapPinLine, color: AppColors.primaryOrange, size: 22),
                const SizedBox(width: 10),
                Text('GPS & odometer tracking', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _bullet(
              'When enabled for a vehicle, distance is estimated from GPS while the customer app is open — not continuous background tracking.',
            ),
            _bullet(
              'Staff see odometer prompts at job intake when readings look outdated.',
            ),
            _bullet(
              'Customers can confirm or correct readings. Consent is per vehicle and can be turned off anytime.',
            ),
            const SizedBox(height: 12),
            Text(
              'Km-based push reminders (e.g. every 500 km) will come in the customer app in a later release.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
