import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? prefixIcon;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = enabled ? AppColors.primaryOrange : AppColors.primaryOrange.withOpacity(0.5);
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.bgElevated;
        fg = AppColors.textPrimary;
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = AppColors.primaryOrange;
        border = Border.all(color: AppColors.primaryOrange, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.textSecondary;
        break;
    }

    final button = GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: height ?? AppSizes.buttonHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: border,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: fg, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixIcon != null) ...[
                      prefixIcon!,
                      const SizedBox(width: AppSizes.sm),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.labelLarge.copyWith(color: fg),
                    ),
                  ],
                ),
        ),
      ),
    );

    return isFullWidth ? button : IntrinsicWidth(child: button);
  }
}
