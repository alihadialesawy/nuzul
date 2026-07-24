import 'package:flutter/material.dart';

/// ألوان التطبيق الموحدة — نزل
class AppColors {
  AppColors._();

  // اللون الأساسي (يمكن تغييره حسب هوية نزل البصرية)
  static const Color primary = Color(0xFF0B6E4F);
  static const Color primaryDark = Color(0xFF084D38);
  static const Color primaryLight = Color(0xFF4C9B7F);

  static const Color secondary = Color(0xFFD4AF37); // ذهبي - لمسة فخامة الحجوزات

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}