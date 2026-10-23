import 'package:flutter/material.dart';

// ── Theme-aware color accessor ────────────────────────────────────────────

class AppColorScheme {
  final bool _isDark;
  const AppColorScheme._(this._isDark);
  factory AppColorScheme.of(BuildContext context) =>
      AppColorScheme._(Theme.of(context).brightness == Brightness.dark);

  Color get background =>
      _isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get surface =>
      _isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get textPrimary =>
      _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary =>
      _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get divider =>
      _isDark ? AppColors.dividerDark : AppColors.dividerLight;
  Color get icon =>
      _isDark ? AppColors.iconDark : AppColors.iconLight;
  Color get inputFill =>
      _isDark ? AppColors.inputFillDark : AppColors.inputFillLight;
}

extension AppColorSchemeExtension on BuildContext {
  AppColorScheme get colors => AppColorScheme.of(this);
}

abstract class AppColors {
  // ─── Brand Blues ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1877F2);
  static const Color primaryDark = Color(0xFF166FE5);
  static const Color primaryDarker = Color(0xFF0E5FC0);
  static const Color primaryLight = Color(0xFF4599FF);
  static const Color primaryLighter = Color(0xFFE7F3FF);

  // ─── Neutrals — Light Mode ────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F2F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF050505);
  static const Color textSecondaryLight = Color(0xFF65676B);
  static const Color textDisabledLight = Color(0xFFBCC0C4);
  static const Color textPlaceholderLight = Color(0xFF8A8D91);
  static const Color dividerLight = Color(0xFFE4E6EB);
  static const Color sectionDividerLight = Color(0xFFF0F2F5);
  static const Color iconLight = Color(0xFF65676B);
  static const Color navIconLight = Color(0xFFBCC0C4);

  // ─── Neutrals — Dark Mode ─────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF18191A);
  static const Color surfaceDark = Color(0xFF242526);
  static const Color surfaceElevatedDark = Color(0xFF3A3B3C);
  static const Color textPrimaryDark = Color(0xFFE4E6EB);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);
  static const Color textDisabledDark = Color(0xFF4E4F50);
  static const Color textPlaceholderDark = Color(0xFF6A6B6C);
  static const Color dividerDark = Color(0xFF3E4042);
  static const Color sectionDividerDark = Color(0xFF18191A);
  static const Color iconDark = Color(0xFFB0B3B8);
  static const Color navIconDark = Color(0xFF4E4F50);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF42B72A);
  static const Color successLight = Color(0xFFE6F4E3);
  static const Color error = Color(0xFFF02849);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF7B928);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF1877F2);
  static const Color infoLight = Color(0xFFE7F3FF);

  // ─── Utility ──────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x1A000000);

  // ─── Shimmer / Skeleton ───────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE4E6EB);
  static const Color shimmerHighlight = Color(0xFFF0F2F5);
  static const Color shimmerBaseDark = Color(0xFF3A3B3C);
  static const Color shimmerHighlightDark = Color(0xFF4E4F50);

  // ─── Tag / Badge ──────────────────────────────────────────────────────────
  static const Color tagBackground = Color(0xFFE7F3FF);
  static const Color tagText = Color(0xFF1877F2);
  static const Color tagBackgroundDark = Color(0xFF263951);
  static const Color tagTextDark = Color(0xFF4599FF);

  // ─── Input ────────────────────────────────────────────────────────────────
  static const Color inputFillLight = Color(0xFFF0F2F5);
  static const Color inputFillDark = Color(0xFF3A3B3C);

  // ─── Semantic accent colors ───────────────────────────────────────────────
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color red = Color(0xFFF44336);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color purple = Color(0xFF673AB7);
  static const Color purpleLight = Color(0xFFEDE7F6);
  static const Color teal = Color(0xFF009688);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color pink = Color(0xFFE91E63);
  static const Color pinkLight = Color(0xFFFCE4EC);
  static const Color yellowLight = Color(0xFFFFFDE7);
  static const Color yellowBorder = Color(0xFFFFD54F);

  // ─── Card gradient ────────────────────────────────────────────────────────
  static const Color cardGradientStart = Color(0xFF1E74EA);
  static const Color cardGradientEnd = Color(0xFF396AC0);
  static const Color cardGradientMid = Color(0xFF2A6FD6);
  static const Color cardGradientHighlight = Color(0x331E74EA);
  static const Color cardOnGradient = Color(0xFFFFFFFF);
  static const Color cardOnGradientMuted = Color(0xCCFFFFFF);
  static const Color cardChipBackground = Color(0x331E74EA);
}
