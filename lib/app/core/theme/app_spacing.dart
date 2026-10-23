import 'package:flutter/material.dart';

abstract class AppSpacing {
  // ─── Base scale (4px grid) ────────────────────────────────────────────────
  static const double xs2 = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 56.0;
  static const double xl7 = 64.0;
  static const double xl8 = 80.0;
  static const double xl9 = 96.0;
  static const double xl10 = 120.0;

  // ─── Semantic — horizontal ────────────────────────────────────────────────
  static const double screenPaddingH = 16.0;
  static const double cardPaddingH = 16.0;
  static const double listItemPaddingH = 16.0;
  static const double chipPaddingH = 12.0;
  static const double buttonPaddingH = 16.0;
  static const double badgePaddingH = 6.0;
  static const double inputPaddingH = 16.0;

  // ─── Semantic — vertical ──────────────────────────────────────────────────
  static const double screenPaddingV = 12.0;
  static const double cardPaddingV = 12.0;
  static const double listItemPaddingV = 12.0;
  static const double chipPaddingV = 6.0;
  static const double buttonPaddingV = 10.0;
  static const double badgePaddingV = 2.0;
  static const double inputPaddingV = 14.0;
  static const double sectionGap = 8.0;
  static const double sectionGapLg = 16.0;

  // ─── EdgeInsets presets ───────────────────────────────────────────────────
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );
  static const EdgeInsets screenPaddingHOnly = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
  );
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: cardPaddingH,
    vertical: cardPaddingV,
  );
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: listItemPaddingH,
    vertical: listItemPaddingV,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: buttonPaddingH,
    vertical: buttonPaddingV,
  );
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: chipPaddingH,
    vertical: chipPaddingV,
  );
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: inputPaddingH,
    vertical: inputPaddingV,
  );

  static const EdgeInsets allXs2 = EdgeInsets.all(xs2);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXl2 = EdgeInsets.all(xl2);
  static const EdgeInsets allXl3 = EdgeInsets.all(xl3);

  static const EdgeInsets hXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets hSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets hXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets hXl2 = EdgeInsets.symmetric(horizontal: xl2);
  static const EdgeInsets hXl3 = EdgeInsets.symmetric(horizontal: xl3);

  static const EdgeInsets vXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets vSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets vMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets vLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets vXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets vXl2 = EdgeInsets.symmetric(vertical: xl2);
  static const EdgeInsets vXl3 = EdgeInsets.symmetric(vertical: xl3);

  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets hOnly(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vOnly(double value) =>
      EdgeInsets.symmetric(vertical: value);
  static EdgeInsets onlyTop(double value) => EdgeInsets.only(top: value);
  static EdgeInsets onlyBottom(double value) => EdgeInsets.only(bottom: value);
  static EdgeInsets onlyLeft(double value) => EdgeInsets.only(left: value);
  static EdgeInsets onlyRight(double value) => EdgeInsets.only(right: value);
  static EdgeInsets only({
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) =>
      EdgeInsets.only(top: top, bottom: bottom, left: left, right: right);
}
