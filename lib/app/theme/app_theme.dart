import 'package:flutter/material.dart';

/// Shared visual system for Science World. Keep colors and component shapes here.
class AppColors {
  static const navy = Color(0xFF071B35);
  static const navySoft = Color(0xFF102D52);
  static const blue = Color(0xFF1769E8);
  static const blueLight = Color(0xFFEAF2FF);
  static const cyan = Color(0xFF35C4E8);
  static const background = Color(0xFFF4F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF17243A);
  static const muted = Color(0xFF718096);
  static const success = Color(0xFF15966A);
  static const warning = Color(0xFFE39A22);
  static const error = Color(0xFFD9485F);
  static const border = Color(0xFFE5EAF2);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      secondary: AppColors.cyan,
      surface: AppColors.surface,
      error: AppColors.error,
    );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansArabic',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.apply(
      fontFamily: 'NotoSansArabic',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w800, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: 'NotoSansArabic', fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    );
  }
}
