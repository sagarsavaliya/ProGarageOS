import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Status string → display config mapping.
typedef _StatusConfig = ({Color textColor, Color bgColor, String label, Color dotColor});

class AppStatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const AppStatusChip({super.key, required this.status, this.fontSize = 10});

  static const Map<String, _StatusConfig> _config = {
    // Job workflow statuses (full API set)
    'draft': (
      textColor: AppColors.textMuted,
      bgColor: AppColors.bgElevated,
      label: 'Draft',
      dotColor: AppColors.textMuted,
    ),
    'intake_inspection': (
      textColor: AppColors.statusBlue,
      bgColor: AppColors.statusBlueBg,
      label: 'Intake',
      dotColor: AppColors.statusBlue,
    ),
    'estimate_pending': (
      textColor: Color(0xFFF0A018),
      bgColor: Color(0xFF1A1200),
      label: 'Est. Pending',
      dotColor: Color(0xFFF0A018),
    ),
    'estimate_approved': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'Est. Approved',
      dotColor: AppColors.statusGreen,
    ),
    'estimate_rejected': (
      textColor: AppColors.statusRed,
      bgColor: AppColors.statusRedBg,
      label: 'Est. Rejected',
      dotColor: AppColors.statusRed,
    ),
    'in_progress': (
      textColor: AppColors.statusBlue,
      bgColor: AppColors.statusBlueBg,
      label: 'In Progress',
      dotColor: AppColors.statusBlue,
    ),
    'qc_pending': (
      textColor: AppColors.statusTeal,
      bgColor: AppColors.statusTealBg,
      label: 'QC Pending',
      dotColor: AppColors.statusTeal,
    ),
    'ready_for_delivery': (
      textColor: AppColors.statusTeal,
      bgColor: AppColors.statusTealBg,
      label: 'Ready',
      dotColor: AppColors.statusTeal,
    ),
    'ready_for_collection': (
      textColor: AppColors.statusTeal,
      bgColor: AppColors.statusTealBg,
      label: 'Ready',
      dotColor: AppColors.statusTeal,
    ),
    'delivered': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'Delivered',
      dotColor: AppColors.statusGreen,
    ),
    'completed': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'Completed',
      dotColor: AppColors.statusGreen,
    ),
    'cancelled': (
      textColor: AppColors.statusRed,
      bgColor: AppColors.statusRedBg,
      label: 'Cancelled',
      dotColor: AppColors.statusRed,
    ),
    'on_hold': (
      textColor: AppColors.statusOrange,
      bgColor: AppColors.statusOrangeBg,
      label: 'On Hold',
      dotColor: AppColors.statusOrange,
    ),
    // Legacy / misc
    'awaiting_parts': (
      textColor: AppColors.statusBlue,
      bgColor: AppColors.statusBlueBg,
      label: 'Awaiting Parts',
      dotColor: AppColors.statusBlue,
    ),
    'overdue': (
      textColor: AppColors.statusRed,
      bgColor: AppColors.statusRedBg,
      label: 'Overdue',
      dotColor: AppColors.statusRed,
    ),
    'created': (
      textColor: AppColors.textMuted,
      bgColor: AppColors.bgElevated,
      label: 'New',
      dotColor: AppColors.textMuted,
    ),
    // Billing / approval statuses
    'pending': (
      textColor: Color(0xFFF0A018),
      bgColor: Color(0xFF1A1200),
      label: 'Pending',
      dotColor: Color(0xFFF0A018),
    ),
    'approved': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'Approved',
      dotColor: AppColors.statusGreen,
    ),
    // Invoice statuses
    'sent': (
      textColor: AppColors.statusBlue,
      bgColor: AppColors.statusBlueBg,
      label: 'Sent',
      dotColor: AppColors.statusBlue,
    ),
    'paid': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'Paid',
      dotColor: AppColors.statusGreen,
    ),
    'partially_paid': (
      textColor: AppColors.statusOrange,
      bgColor: AppColors.statusOrangeBg,
      label: 'Partial',
      dotColor: AppColors.statusOrange,
    ),
    'void': (
      textColor: AppColors.textMuted,
      bgColor: AppColors.bgElevated,
      label: 'Void',
      dotColor: AppColors.textMuted,
    ),
    // Inventory stock statuses
    'out_of_stock': (
      textColor: AppColors.statusRed,
      bgColor: AppColors.statusRedBg,
      label: 'Out of Stock',
      dotColor: AppColors.statusRed,
    ),
    'low_stock': (
      textColor: AppColors.statusOrange,
      bgColor: AppColors.statusOrangeBg,
      label: 'Low Stock',
      dotColor: AppColors.statusOrange,
    ),
    'in_stock': (
      textColor: AppColors.statusGreen,
      bgColor: AppColors.statusGreenBg,
      label: 'In Stock',
      dotColor: AppColors.statusGreen,
    ),
    'inactive': (
      textColor: AppColors.textMuted,
      bgColor: AppColors.bgElevated,
      label: 'Inactive',
      dotColor: AppColors.textMuted,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ??
        (
          textColor: AppColors.textSecondary,
          bgColor: AppColors.bgElevated,
          label: status.replaceAll('_', ' '),
          dotColor: AppColors.textSecondary,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cfg.dotColor),
          ),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: cfg.textColor,
              letterSpacing: 0.02 * fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
