import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary brand — Deep Teal
  static const Color primary = Color(0xFF006D77);
  static const Color primaryDark = Color(0xFF004E57);
  static const Color primaryLight = Color(0xFF83C5BE);
  static const Color primaryContainer = Color(0xFFCCEEF1);

  // Accent — Warm Coral
  static const Color accent = Color(0xFFE29578);
  static const Color accentLight = Color(0xFFFFDDD2);

  // Backgrounds
  static const Color background = Color(0xFFEDF6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5FAFB);
  static const Color divider = Color(0xFFDCECF0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6474);
  static const Color textHint = Color(0xFFAAB4BC);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Risk levels
  static const Color riskLow = Color(0xFF27AE60);
  static const Color riskLowBg = Color(0xFFEAF7EF);
  static const Color riskModerate = Color(0xFFF39C12);
  static const Color riskModerateBg = Color(0xFFFEF9EC);
  static const Color riskHigh = Color(0xFFE67E22);
  static const Color riskHighBg = Color(0xFFFDF0E3);
  static const Color riskCritical = Color(0xFFC0392B);
  static const Color riskCriticalBg = Color(0xFFFAEAE8);

  // Priority groups
  static const Color visitToday = Color(0xFFC0392B);
  static const Color callToday = Color(0xFFF39C12);
  static const Color stable = Color(0xFF27AE60);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF2980B9);

  // Stock alert
  static const Color stockOk = Color(0xFF27AE60);
  static const Color stockWarning = Color(0xFFF39C12);
  static const Color stockCritical = Color(0xFFC0392B);

  // Gradient stops
  static const Color gradientStart = Color(0xFF006D77);
  static const Color gradientEnd = Color(0xFF004E57);
  static const Color gradientAccent = Color(0xFF83C5BE);
}
