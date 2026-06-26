import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary brand — DMC coral-orange
  static const Color primary          = Color(0xFFE64B2E); // brand #E64B2E
  static const Color primaryDark      = Color(0xFFC73E22); // brand-deep: hover/emphasis
  static const Color brandBrown       = Color(0xFF9C3219); // brand-brown: gravitas/headings
  static const Color primaryMid       = Color(0xFFC73E22); // alias for brand-deep
  static const Color primaryLight     = Color(0xFFF07256); // brand-light: softer accent
  static const Color primaryContainer = Color(0x17E64B2E); // brand-tint: rgba(230,75,46,0.09)

  // Accent
  static const Color accent      = Color(0xFFF07256);
  static const Color accentLight = Color(0x17E64B2E);

  // Backgrounds
  static const Color background     = Color(0xFFFAFAFA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9F9F9);
  static const Color divider        = Color(0xFFECECEC);

  // Text
  static const Color textPrimary   = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Risk levels
  static const Color riskLow        = Color(0xFF2E7D32);
  static const Color riskLowBg      = Color(0xFFE8F5E9);
  static const Color riskModerate   = Color(0xFFB26A00); // warning #B26A00
  static const Color riskModerateBg = Color(0xFFFFF3CD);
  static const Color riskHigh       = Color(0xFFE67E22);
  static const Color riskHighBg     = Color(0xFFFDF0E3);
  static const Color riskCritical   = Color(0xFFC0392B); // danger #C0392B
  static const Color riskCriticalBg = Color(0xFFFFEBEE);

  // Priority groups
  static const Color visitToday = Color(0xFFC0392B); // danger
  static const Color callToday  = Color(0xFFB26A00); // warning
  static const Color stable     = Color(0xFF2E7D32); // success

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00); // #B26A00 (not amber #F59E0B)
  static const Color error   = Color(0xFFC0392B); // #C0392B (not #D32F2F)
  static const Color info    = Color(0xFF1565C0);

  // Stock alert
  static const Color stockOk       = Color(0xFF2E7D32);
  static const Color stockWarning  = Color(0xFFB26A00);
  static const Color stockCritical = Color(0xFFC0392B);

  // Gradient stops — brand orange → brand-brown
  static const Color gradientStart  = Color(0xFFE64B2E);
  static const Color gradientEnd    = Color(0xFF9C3219);
  static const Color gradientAccent = Color(0xFFF07256);
}
