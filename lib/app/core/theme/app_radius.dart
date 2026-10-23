import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xl2 = 20.0;
  static const double xl3 = 24.0;
  static const double full = 999.0;

  static BorderRadius get noneAll => BorderRadius.circular(none);
  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xl2All => BorderRadius.circular(xl2);
  static BorderRadius get xl3All => BorderRadius.circular(xl3);
  static BorderRadius get fullAll => BorderRadius.circular(full);

  static BorderRadius get pill => BorderRadius.circular(full);
  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get input => BorderRadius.circular(xl2);
  static BorderRadius get commentBubble => BorderRadius.circular(lg);
  static BorderRadius get bottomSheet => const BorderRadius.vertical(
        top: Radius.circular(xl),
      );
  static BorderRadius get topOnly => const BorderRadius.vertical(
        top: Radius.circular(md),
      );
  static BorderRadius get bottomOnly => const BorderRadius.vertical(
        bottom: Radius.circular(md),
      );

  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: card);
  static RoundedRectangleBorder get pillShape =>
      RoundedRectangleBorder(borderRadius: pill);
  static RoundedRectangleBorder get inputShape =>
      RoundedRectangleBorder(borderRadius: input);
  static RoundedRectangleBorder get bottomSheetShape =>
      RoundedRectangleBorder(borderRadius: bottomSheet);
}
