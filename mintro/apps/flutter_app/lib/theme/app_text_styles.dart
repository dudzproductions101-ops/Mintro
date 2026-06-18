import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles. Uses Inter for a clean, modern, slightly
/// rounded sans-serif that reads as friendly rather than corporate —
/// matching the "game that teaches money" tone (not a banking app).
abstract class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  static TextStyle get headline => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLarge => _base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyStrong => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      );

  static TextStyle get statValue => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get navLabel => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
}
