import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Vehicles tab — currently a pass-through.
/// Vehicle detail is accessed from the Customer detail screen.
/// This screen will be built in a future sprint with fleet overview.
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehicles', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Browse vehicles from the Customers tab.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              Center(
                child: Icon(
                  PhosphorIconsRegular.car,
                  size: 72,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
