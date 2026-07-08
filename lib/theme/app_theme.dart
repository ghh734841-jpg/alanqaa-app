import 'package:flutter/material.dart';

/// لوحة الألوان
class AppColors {
  static const bgDeep = Color(0xFF0F1621);
  static const surface = Color(0xFF1B2532);
  static const surfaceAlt = Color(0xFF141C26);
  static const border = Color(0xFF2A3646);
  static const textPrimary = Color(0xFFF4F6F8);
  static const textMuted = Color(0xFF93A1B3);
  static const textFaint = Color(0xFF6C7A8C);

  static const teal = Color(0xFF1FB6A6);
  static const amber = Color(0xFFE0A458);
  static const blue = Color(0xFF4FA8E0);
  static const green = Color(0xFF4CAF7D);
  static const red = Color(0xFFD9534F);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        secondary: AppColors.blue,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      fontFamily: 'Tajawal',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textPrimary,
        hintStyle: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static Color statusColor(String statusName) {
    switch (statusName) {
      case 'pending':
        return AppColors.amber;
      case 'making':
        return AppColors.blue;
      case 'done':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.textMuted;
    }
  }
}
