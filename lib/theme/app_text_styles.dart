import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'PlusJakartaSans';

  // Display
  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
    color: AppColors.textPrimaryLight,
  );

  // Headline
  static const TextStyle headline = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimaryLight,
  );

  // Title
  static const TextStyle title = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimaryLight,
  );

  // Subtitle
  static const TextStyle subtitle = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textPrimaryLight,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimaryLight,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textMutedLight,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.2,
    color: AppColors.textMutedLight,
  );

  // Amount large
  static const TextStyle amountLarge = TextStyle(
    fontFamily: _font,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.0,
    color: AppColors.textPrimaryLight,
  );

  // Amount medium
  static const TextStyle amountMedium = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.textPrimaryLight,
  );
}
