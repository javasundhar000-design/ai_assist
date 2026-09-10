import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the AURA STYLIST AI design system.
/// Every screen pulls colors, spacing, radii and text styles from here
/// so the app stays visually consistent end to end.
class AppColors {
  AppColors._();

  // Core surfaces
  static const Color background = Color(0xFF0A0A14); // deep navy/black
  static const Color surface = Color(0xFF13131F); // card surface
  static const Color surfaceElevated = Color(0xFF1B1B2C);
  static const Color surfaceGlass = Color(0x1AFFFFFF); // glassmorphism fill

  // Accents
  static const Color violet = Color(0xFF8B5CF6);
  static const Color purple = Color(0xFF7C3AED);
  static const Color magenta = Color(0xFFEC4899);
  static const Color pink = Color(0xFFF472B6);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, magenta],
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFFEC4899)],
  );

  // Text
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA1A1B5);
  static const Color textMuted = Color(0xFF6B6B80);

  // Status
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color border = Color(0x1FFFFFFF);
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double pill = 100;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.plusJakartaSans();

  static TextStyle get display => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodyStrong => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get button => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.violet,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.violet,
      secondary: AppColors.magenta,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: AppColors.border,
  );
}
