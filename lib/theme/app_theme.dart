import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

/// Extra Creak brand colors that don't fit [ColorScheme].
///
/// Read via `Theme.of(context).extension<CreakColors>()!`. Feature code must
/// pull every color from the theme (scheme or this extension), never from
/// literals.
class CreakColors extends ThemeExtension<CreakColors> {
  const CreakColors({
    required this.backgroundGradient,
    required this.success,
    required this.streakFlame,
  });

  /// Full-screen warm gradient painted behind every [Scaffold].
  final List<Color> backgroundGradient;

  /// Positive states: completed exercises, finished sessions.
  final Color success;

  /// The streak flame accent.
  final Color streakFlame;

  @override
  CreakColors copyWith({
    List<Color>? backgroundGradient,
    Color? success,
    Color? streakFlame,
  }) {
    return CreakColors(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      success: success ?? this.success,
      streakFlame: streakFlame ?? this.streakFlame,
    );
  }

  @override
  CreakColors lerp(CreakColors? other, double t) {
    if (other == null) return this;
    return CreakColors(
      backgroundGradient: [
        for (var i = 0; i < backgroundGradient.length; i++)
          Color.lerp(backgroundGradient[i], other.backgroundGradient[i], t)!,
      ],
      success: Color.lerp(success, other.success, t)!,
      streakFlame: Color.lerp(streakFlame, other.streakFlame, t)!,
    );
  }
}

/// Creak's Material 3 peach-coral theme, light and dark.
///
/// Both variants seed a [ColorScheme] from the coral brand color and apply
/// Space Grotesk across the whole text theme. Use [light]/[dark] in
/// `MaterialApp(theme:, darkTheme:)`; `ThemeMode.system` then follows the
/// platform brightness automatically.
abstract final class AppTheme {
  static const _coral = Color(0xFFFF7A59);
  static const _cream = Color(0xFFFAF7EF);

  /// Light theme: cream surfaces on a warm peach canvas.
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _coral,
      primary: _coral,
      surface: _cream,
    );
    return _base(scheme).copyWith(
      extensions: const [
        CreakColors(
          // Fades from a soft cream at the top (so the peach mascot stands
          // out against it) down to a warm peach.
          backgroundGradient: [Color(0xFFFFF1E6), Color(0xFFFFC7A3)],
          success: Color(0xFF3E8E5A),
          streakFlame: Color(0xFFFF6B35),
        ),
      ],
    );
  }

  /// Dark theme: deep warm browns with the same coral accents.
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _coral,
      brightness: Brightness.dark,
    );
    return _base(scheme).copyWith(
      extensions: const [
        CreakColors(
          backgroundGradient: [Color(0xFF2A1B14), Color(0xFF40241A)],
          success: Color(0xFF7BC896),
          streakFlame: Color(0xFFFF8F5E),
        ),
      ],
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        backgroundColor: scheme.secondaryContainer,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
