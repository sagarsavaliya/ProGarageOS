import 'package:flutter/material.dart';

/// ProGarage design system colour palette — dark-first industrial aesthetic.
class AppColors {
  AppColors._();

  // Brand — single accent used app-wide (login, PIN, chips, CTAs)
  static const Color primaryOrange = Color(0xFFFF6B2B);
  static const Color accent = primaryOrange;
  static const Color primaryOrangeDim = Color(0x26FF6B2B); // 15% opacity

  // Backgrounds (dark-first)
  static const Color bgPrimary = Color(0xFF0F1117);
  static const Color bgSurface = Color(0xFF1A1D27);
  static const Color bgElevated = Color(0xFF222536);
  static const Color bgOverlay = Color(0xFF2A2D3E);

  // Text
  static const Color textPrimary = Color(0xFFF0F2FF);
  static const Color textSecondary = Color(0xFF8B90A7);
  static const Color textMuted = Color(0xFF4A4F6A);

  // Status (semantic)
  static const Color statusGreen = Color(0xFF22C55E);
  static const Color statusOrange = Color(0xFFFF9500);
  static const Color statusBlue = Color(0xFF3B82F6);
  static const Color statusRed = Color(0xFFEF4444);
  static const Color statusPurple = Color(0xFFA855F7);
  static const Color statusTeal = Color(0xFF26B8A8);

  // Utility
  static const Color divider = Color(0xFF2A2D3E);
  static const Color shimmerBase = Color(0xFF1A1D27);
  static const Color shimmerHigh = Color(0xFF2A2D3E);

  // Tinted status backgrounds (for chips/badges)
  static const Color statusGreenBg = Color(0xFF0A2A1A);
  static const Color statusOrangeBg = Color(0xFF2A1F0A);
  static const Color statusBlueBg = Color(0xFF0A1A2A);
  static const Color statusRedBg = Color(0xFF2A0A0A);
  static const Color statusPurpleBg = Color(0xFF1A0A2A);
  static const Color statusTealBg = Color(0xFF0A2220);
}
