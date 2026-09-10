import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { light, dark, highContrast }

/// Section 32: one centralized theme system that every screen pulls from.
/// Font scale is applied on top of this via a `MediaQuery` `TextScaler`
/// override in `app.dart` rather than baked into the theme, since it
/// must change live from Settings without an app restart.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF3B5BFE); // calm, premium indigo-blue
  static const Color _successGreen = Color(0xFF1FB871);
  static const Color _emergencyRed = Color(0xFFE0303B);

  static const double baseRadius = 20;
  static const double largeButtonHeight = 88;

  static ThemeData get light => _build(
        brightness: Brightness.light,
        surface: const Color(0xFFF7F8FC),
        onSurface: const Color(0xFF15171F),
        card: Colors.white,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        surface: const Color(0xFF101218),
        onSurface: const Color(0xFFF2F3F7),
        card: const Color(0xFF1B1E27),
      );

  /// High contrast: pure black/white/yellow accents, no mid-grays, thick
  /// borders — built specifically for low-vision users, not just a
  /// darker dark mode.
  static ThemeData get highContrast => _build(
        brightness: Brightness.dark,
        surface: Colors.black,
        onSurface: Colors.white,
        card: Colors.black,
        isHighContrast: true,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
    required Color card,
    bool isHighContrast = false,
  }) {
    final seed = isHighContrast ? const Color(0xFFFFD400) : _seed;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
      error: _emergencyRed,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      // Plus Jakarta Sans: a clean, geometric, highly legible sans-serif
      // — reads as "premium" without sacrificing accessibility legibility
      // at large sizes. Previously the theme referenced a font family
      // ('Inter') that was never actually bundled as an asset, so it was
      // silently falling back to the platform default; GoogleFonts
      // fetches/caches the real thing at runtime instead.
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      visualDensity: VisualDensity.comfortable,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isHighContrast ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          side: isHighContrast
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(largeButtonHeight),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(baseRadius),
          ),
          elevation: isHighContrast ? 0 : 1,
        ),
      ),
      iconTheme: IconThemeData(color: onSurface, size: 28),
      dividerColor: isHighContrast ? Colors.white : null,
      extensions: [
        AppSemanticColors(
          success: _successGreen,
          emergency: _emergencyRed,
          isHighContrast: isHighContrast,
        ),
      ],
    );
  }

  static ThemeData resolve(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.highContrast:
        return highContrast;
    }
  }
}

/// Extra semantic colors not covered by [ColorScheme] (success/emergency),
/// exposed as a ThemeExtension so widgets fetch them the same way they'd
/// fetch any other theme color: `Theme.of(context).extension<...>()`.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color emergency;
  final bool isHighContrast;

  const AppSemanticColors({
    required this.success,
    required this.emergency,
    required this.isHighContrast,
  });

  @override
  AppSemanticColors copyWith({Color? success, Color? emergency, bool? isHighContrast}) {
    return AppSemanticColors(
      success: success ?? this.success,
      emergency: emergency ?? this.emergency,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      emergency: Color.lerp(emergency, other.emergency, t)!,
      isHighContrast: t < 0.5 ? isHighContrast : other.isHighContrast,
    );
  }
}
