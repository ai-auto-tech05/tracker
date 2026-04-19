import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // Secondary / accent
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentSurface = Color(0xFFFFFBEB);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successSurface = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF97316);
  static const Color warningSurface = Color(0xFFFFF7ED);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorSurface = Color(0xFFFEF2F2);

  // Neutrals
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Priority colors
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF6B7280);

  // Habit palette
  static const List<Color> habitColors = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFF059669),
    Color(0xFF0284C7),
    Color(0xFF0891B2),
  ];

  // Chart colors
  static const Color chartPrimary = Color(0xFF4F46E5);
  static const Color chartSecondary = Color(0xFF818CF8);
  static const Color chartAccent = Color(0xFFF59E0B);
  static const Color chartSuccess = Color(0xFF10B981);
}
