import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

abstract class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.accentLight,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.primaryLight,
        onTertiary: AppColors.primaryDark,
        tertiaryContainer: AppColors.primaryContainer,
        onTertiaryContainer: AppColors.primaryDark,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.divider,
        outlineVariant: AppColors.divider,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AppColors.primaryDark,
        onInverseSurface: AppColors.textOnPrimary,
        inversePrimary: AppColors.primaryLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final textTheme = GoogleFonts.ibmPlexSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.ibmPlexSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium: GoogleFonts.ibmPlexSans(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displaySmall: GoogleFonts.ibmPlexSans(
          fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineLarge: GoogleFonts.ibmPlexSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineMedium: GoogleFonts.ibmPlexSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.ibmPlexSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: GoogleFonts.ibmPlexSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: GoogleFonts.ibmPlexSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      titleSmall: GoogleFonts.ibmPlexSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      bodyLarge: GoogleFonts.ibmPlexSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.ibmPlexSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: GoogleFonts.ibmPlexSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: GoogleFonts.ibmPlexSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary),
      labelMedium: GoogleFonts.ibmPlexSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelSmall: GoogleFonts.ibmPlexSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.ibmPlexSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.ibmPlexSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.ibmPlexSans(color: AppColors.textHint, fontSize: 14),
        labelStyle:
            GoogleFonts.ibmPlexSans(color: AppColors.textSecondary, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      // Material 3 NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary);
          }
          return GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textHint, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            GoogleFonts.ibmPlexSans(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
