import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Inter is bundled in assets/fonts (see pubspec.yaml).
const String _fontFamily = 'Inter';

/// Dashboard type scale (CSS-pixel guideline): size / weight / line height.
///
/// | Element            | Size  | Weight | Line height |
/// |--------------------|-------|--------|-------------|
/// | Page title         | 28    | 600    | 36          |
/// | Section heading    | 20    | 600    | 28          |
/// | Card heading       | 16    | 600    | 24          |
/// | Body / table cell  | 14    | 400    | 20          |
/// | Table header       | 12    | 600    | 16          |
/// | Form label / button| 14    | 500    | 20          |
/// | Input text         | 14-16 | 400    | 22          |
/// | Helper text        | 12    | 400    | 16          |
/// | Badge / status     | 12    | 500    | 16          |
/// | KPI value          | 28-36 | 600    | 36-44       |
/// | Sidebar menu       | 14    | 500    | 20          |
abstract class AppType {
  static TextStyle _s(double size, FontWeight w, double lineHeight, [Color? color]) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: w,
        height: lineHeight / size,
        color: color,
      );

  static TextStyle pageTitle([Color? c]) => _s(28, FontWeight.w600, 36, c);
  static TextStyle sectionHeading([Color? c]) => _s(20, FontWeight.w600, 28, c);
  static TextStyle cardHeading([Color? c]) => _s(16, FontWeight.w600, 24, c);
  static TextStyle body([Color? c]) => _s(14, FontWeight.w400, 20, c);
  static TextStyle bodyLarge([Color? c]) => _s(16, FontWeight.w400, 24, c);
  static TextStyle tableHeader([Color? c]) => _s(12, FontWeight.w600, 16, c);
  static TextStyle tableCell([Color? c]) => _s(14, FontWeight.w400, 20, c);
  static TextStyle formLabel([Color? c]) => _s(14, FontWeight.w500, 20, c);
  static TextStyle input([Color? c]) => _s(14, FontWeight.w400, 22, c);
  static TextStyle button([Color? c]) => _s(14, FontWeight.w500, 20, c);
  static TextStyle helper([Color? c]) => _s(12, FontWeight.w400, 16, c);
  static TextStyle badge([Color? c]) => _s(12, FontWeight.w500, 16, c);
  static TextStyle kpi([Color? c]) => _s(32, FontWeight.w600, 40, c);
  static TextStyle sidebar([Color? c]) => _s(14, FontWeight.w500, 20, c);
}

abstract class AppTextTheme {
  static TextTheme get light => _build(
        primary: AppColors.textPrimaryLight,
        secondary: AppColors.textSecondaryLight,
        disabled: AppColors.textDisabledLight,
      );

  static TextTheme get dark => _build(
        primary: AppColors.textPrimaryDark,
        secondary: AppColors.textSecondaryDark,
        disabled: AppColors.textDisabledDark,
      );

  static TextTheme _build({
    required Color primary,
    required Color secondary,
    required Color disabled,
  }) {
    return TextTheme(
      displayLarge: AppType.kpi(primary).copyWith(fontSize: 36, height: 44 / 36),
      displayMedium: AppType.kpi(primary),
      displaySmall: AppType.kpi(primary).copyWith(fontSize: 28, height: 36 / 28),
      headlineLarge: AppType.pageTitle(primary),
      headlineMedium: AppType.sectionHeading(primary),
      headlineSmall: AppType.sectionHeading(primary),
      titleLarge: AppType.sectionHeading(primary),
      titleMedium: AppType.cardHeading(primary),
      titleSmall: AppType.formLabel(primary),
      bodyLarge: AppType.bodyLarge(primary),
      bodyMedium: AppType.body(primary),
      bodySmall: AppType.helper(secondary),
      labelLarge: AppType.button(primary),
      labelMedium: AppType.badge(secondary),
      labelSmall: AppType.tableHeader(disabled),
    );
  }
}

class AppTextStyles {
  final bool _isDark;
  const AppTextStyles._(this._isDark);
  factory AppTextStyles.of(BuildContext context) =>
      AppTextStyles._(Theme.of(context).brightness == Brightness.dark);

  Color get _primary =>
      _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get _secondary =>
      _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get _placeholder =>
      _isDark ? AppColors.textPlaceholderDark : AppColors.textPlaceholderLight;

  // Guideline styles
  TextStyle get pageTitle => AppType.pageTitle(_primary);
  TextStyle get sectionHeading => AppType.sectionHeading(_primary);
  TextStyle get cardHeading => AppType.cardHeading(_primary);
  TextStyle get body => AppType.body(_secondary);
  TextStyle get tableHeader => AppType.tableHeader(_secondary);
  TextStyle get tableCell => AppType.tableCell(_primary);
  TextStyle get formLabel => AppType.formLabel(_primary);
  TextStyle get helper => AppType.helper(_secondary);
  TextStyle get kpiValue => AppType.kpi(_primary);
  TextStyle get sidebarItem => AppType.sidebar(_primary);

  // Existing names, mapped onto the scale
  TextStyle get appBarTitle => AppType.sectionHeading(AppColors.primary);
  TextStyle get sectionHeader => AppType.cardHeading(_primary);
  TextStyle get userName => AppType.formLabel(_primary);
  TextStyle get postBody => AppType.body(_secondary);
  TextStyle get actionLabel => AppType.button(_primary);
  TextStyle get inputHint => AppType.input(_placeholder);
  TextStyle get inputText => AppType.input(_primary);
  TextStyle get timestamp => AppType.helper(_secondary);

  static TextStyle get buttonLabel => AppType.button(AppColors.white);
  static TextStyle get badge => AppType.badge(AppColors.white);
  static TextStyle get cardLabel => AppType.cardHeading(AppColors.cardOnGradient);
}

extension AppTextThemeExtension on BuildContext {
  AppTextStyles get appText => AppTextStyles.of(this);
}
