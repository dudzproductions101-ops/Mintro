import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        surface: AppColors.surface,
        background: AppColors.background,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyMedium: AppTextStyles.body,
        bodyLarge: AppTextStyles.bodyStrong,
        labelSmall: AppTextStyles.label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearTrackColor: AppColors.progressTrack,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
    );
  }
}
