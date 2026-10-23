import 'package:flutter/material.dart';

abstract class AppSize {
  // ─── Icon sizes ───────────────────────────────────────────────────────────
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 40.0;
  static const double icon2x = 48.0;
  static const double icon3x = 64.0;

  // ─── Avatar sizes ─────────────────────────────────────────────────────────
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 56.0;
  static const double avatarXxl = 72.0;

  static const Size avatarMdSize = Size(avatarMd, avatarMd);
  static const Size avatarLgSize = Size(avatarLg, avatarLg);

  // ─── Button sizes ─────────────────────────────────────────────────────────
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;
  static const double buttonMinWidth = 64.0;

  // ─── Input sizes ──────────────────────────────────────────────────────────
  static const double inputHeight = 48.0;
  static const double inputHeightLg = 56.0;

  // ─── Component sizes ──────────────────────────────────────────────────────
  static const double bottomNavHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double dividerThickness = 1.0;
  static const double badgeSize = 18.0;

  // ─── Layout ───────────────────────────────────────────────────────────────
  static const double maxContentWidth = 1200.0;
  static const double maxDialogWidth = 480.0;
  static const double fill = double.infinity;

  // ─── Admin layout breakpoints ─────────────────────────────────────────────
  static const double sidebarWidth = 260.0;
  static const double navRailWidth = 72.0;

  // ─── Gap helpers ──────────────────────────────────────────────────────────
  static SizedBox hGap(double width) => SizedBox(width: width);
  static SizedBox vGap(double height) => SizedBox(height: height);

  static const SizedBox vGapXs = SizedBox(height: 4);
  static const SizedBox vGapSm = SizedBox(height: 8);
  static const SizedBox vGapMd = SizedBox(height: 12);
  static const SizedBox vGapLg = SizedBox(height: 16);
  static const SizedBox vGapXl = SizedBox(height: 20);
  static const SizedBox vGapXl2 = SizedBox(height: 24);
  static const SizedBox vGapXxl = SizedBox(height: 32);

  static const SizedBox hGapXs = SizedBox(width: 4);
  static const SizedBox hGapSm = SizedBox(width: 8);
  static const SizedBox hGapMd = SizedBox(width: 12);
  static const SizedBox hGapLg = SizedBox(width: 16);
  static const SizedBox hGapXl = SizedBox(width: 24);
  static const SizedBox hGapXxl = SizedBox(width: 32);

  // ─── Screen helpers ───────────────────────────────────────────────────────
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }
}
