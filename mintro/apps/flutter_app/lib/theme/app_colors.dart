import 'package:flutter/material.dart';

/// Colors extracted from the Mintro UI mockups: a warm sage background,
/// white surfaces, forest-green primary accents, and a distinct color per
/// learning path / stat type (streak orange, coin gold, etc.).
abstract class AppColors {
  // Backgrounds & surfaces
  static const Color background = Color(0xFFF3F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F8F4);

  // Text
  static const Color textPrimary = Color(0xFF1A1F1B);
  static const Color textSecondary = Color(0xFF8A938C);
  static const Color textTertiary = Color(0xFFB7BFB6);

  // Primary brand green
  static const Color primaryGreen = Color(0xFF1F7A3D);
  static const Color primaryGreenDark = Color(0xFF155429);
  static const Color primaryGreenLight = Color(0xFFE3F1E6);
  static const Color progressTrack = Color(0xFFE6E9E2);

  // Streak
  static const Color streak = Color(0xFFE8552E);
  static const Color streakBg = Color(0xFFFCE6DF);

  // Coins
  static const Color coin = Color(0xFFD9A100);
  static const Color coinBg = Color(0xFFFCF3D6);

  // Learning paths
  static const Color pathFoundations = Color(0xFF1F7A3D);
  static const Color pathCreditDebt = Color(0xFFE8A100);
  static const Color pathInvesting = Color(0xFF3B6FE0);
  static const Color pathTaxStrategy = Color(0xFF8B5CF6);
  static const Color pathTrustFunds = Color(0xFF0E9488);

  // Quests
  static const Color questFeaturedBg = Color(0xFF1F7A3D);
  static const Color questCardBg = Color(0xFFFFFFFF);

  // Leagues
  static const Color leagueEmerald = Color(0xFF0E9488);
  static const Color leagueEmeraldBg = Color(0xFFE3F1EE);
  static const Color podiumGold = Color(0xFFF4E3B2);
  static const Color podiumSilver = Color(0xFFE3DAF7);
  static const Color podiumBronze = Color(0xFFDDE6FB);
  static const Color rank1Text = Color(0xFF8B5A00);
  static const Color rank2Text = Color(0xFF6D28D9);
  static const Color rank3Text = Color(0xFF1D4ED8);
  static const Color highlightRow = Color(0xFFFDF6DD);

  // Goals / achievements
  static const Color goalRing = Color(0xFF1F7A3D);
  static const Color achievementLocked = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF1F7A3D);
  static const Color warning = Color(0xFFE8A100);
  static const Color danger = Color(0xFFE8552E);

  // Divider
  static const Color divider = Color(0xFFE6E9E2);
}
