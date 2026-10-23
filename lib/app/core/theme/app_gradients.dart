import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppGradients {
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
  );

  static const LinearGradient cardRich = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.cardGradientStart,
      AppColors.cardGradientMid,
      AppColors.cardGradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryLight,
      AppColors.primary,
      AppColors.primaryDark,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryLight, AppColors.primaryDark],
  );

  static const LinearGradient shimmerLight = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(2.0, 0.3),
    colors: [
      AppColors.shimmerBase,
      AppColors.shimmerHighlight,
      AppColors.shimmerBase,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient shimmerDark = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(2.0, 0.3),
    colors: [
      AppColors.shimmerBaseDark,
      AppColors.shimmerHighlightDark,
      AppColors.shimmerBaseDark,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF42B72A), Color(0xFF2D9E1A)],
  );

  static const LinearGradient error = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF02849), Color(0xFFBF1232)],
  );

  static LinearGradient linear({
    required Color from,
    required Color to,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) =>
      LinearGradient(begin: begin, end: end, colors: [from, to]);
}
