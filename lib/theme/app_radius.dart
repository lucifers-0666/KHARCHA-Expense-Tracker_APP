import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double x2l  = 24.0;
  static const double full = 999.0;

  static BorderRadius circular(double r) => BorderRadius.circular(r);

  static const BorderRadius cardRadius   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius   = BorderRadius.all(Radius.circular(full));
  static const BorderRadius inputRadius  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetRadius  = BorderRadius.vertical(top: Radius.circular(x2l));
}
