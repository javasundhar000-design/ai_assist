import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AI Assist design system.
///
/// Design intent (see design notes in project README for the full brief):
/// this app serves two very different audiences in the same session — a
/// blind, non-speaking, or motor-impaired person who needs maximum clarity
/// and huge touch targets, and a caregiver who wants a calm, trustworthy
/// monitoring tool. The palette stays deliberately restrained so role
/// colors (set per person) carry real meaning instead of competing with
/// decoration, and amber/red are reserved for "needs attention" and
/// "emergency" respectively — never used decoratively elsewhere.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B2333); // primary text
  static const canvas = Color(0xFFF5F6FA); // app background
  static const surface = Color(0xFFFFFFFF); // cards / sheets
  static const signal = Color(0xFF3454D1); // brand primary — trust, calm
  static const sun = Color(0xFFF5A623); // attention / positive highlight
  static const alert = Color(0xFFE14B4B); // emergency only — never decorative
  static const mist = Color(0xFFE4E8F5); // subtle borders / dividers

  // Role accents — functional, not decorative. Each role keeps the same
  // color everywhere it appears (avatar, badge, tile) so it becomes a
  // learned visual shortcut for "whose data is this."
  static const roleBlind = Color(0xFF3454D1);
  static const roleNonSpeaking = Color(0xFF1D9A8C);
  static const roleMotor = Color(0xFFE07A2C);
  static const roleAdmin = Color(0xFF7C4DFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.signal,
        brightness: Brightness.light,
        primary: AppColors.signal,
        surface: AppColors.surface,
        error: AppColors.alert,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
    );

    final headlineFont = GoogleFonts.manropeTextTheme();
    final bodyFont = GoogleFonts.interTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: headlineFont.displayLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: headlineFont.headlineLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 30,
      ),
      headlineMedium: headlineFont.headlineMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: headlineFont.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      bodyLarge: bodyFont.bodyLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 18,
        height: 1.4,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        color: AppColors.ink.withValues(alpha: 0.75),
        fontSize: 15,
        height: 1.4,
      ),
      labelLarge: headlineFont.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headlineFont.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.mist, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          textStyle: headlineFont.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(58),
          side: const BorderSide(color: AppColors.mist, width: 1.4),
          textStyle: headlineFont.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.signal,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.signal, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.mist, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.alert,
        foregroundColor: Colors.white,
      ),
    );
  }
}
