import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs   = 8.0;
  static const double sm   = 12.0;
  static const double md   = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double xxl  = 28.0;
  static const double full = 999.0;

  static BorderRadius get cardRadius    => BorderRadius.circular(xl);
  static BorderRadius get buttonRadius  => BorderRadius.circular(lg);
  static BorderRadius get inputRadius   => BorderRadius.circular(md);
  static BorderRadius get chipRadius    => BorderRadius.circular(full);
  static BorderRadius get sheetRadius   =>
      const BorderRadius.vertical(top: Radius.circular(xxl));
  static BorderRadius get tileRadius    => BorderRadius.circular(md);
}
