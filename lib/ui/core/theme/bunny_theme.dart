import 'package:flutter/material.dart';

class BunnyColors {
  BunnyColors._();

  static const Color bg = Color(0xFF06080D);
  static const Color bgElevated = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF101624);
  static const Color surfaceHighlight = Color(0xFF172033);
  static const Color border = Color(0xFF212D44);
  static const Color borderSubtle = Color(0xFF182235);

  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9AA7BD);
  static const Color textMuted = Color(0xFF64728A);

  // Pillar accent colors matching original Assets.car banners
  static const Color electricBlue = Color(0xFF2288FF);
  static const Color electricBlueBright = Color(0xFF38BDF8);
  static const Color crimson = Color(0xFFFF2A3B);
  static const Color crimsonDeep = Color(0xFFE11D48);
  static const Color gold = Color(0xFFF5B800);
  static const Color goldBright = Color(0xFFFFD54F);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetBright = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF00D4FF);
  static const Color emerald = Color(0xFF22C55E);
  static const Color amber = Color(0xFFF59E0B);
}

class BunnyTheme {
  BunnyTheme._();

  static ThemeData buildDarkTheme() {
    const baseTextTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.6,
        color: BunnyColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.4,
        color: BunnyColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: BunnyColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BunnyColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: BunnyColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: BunnyColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: BunnyColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: BunnyColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: BunnyColors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: BunnyColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: BunnyColors.electricBlue,
        secondary: BunnyColors.crimson,
        tertiary: BunnyColors.gold,
        surface: BunnyColors.surface,
        error: BunnyColors.crimson,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BunnyColors.textPrimary,
      ),
      textTheme: baseTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: BunnyColors.bg,
        foregroundColor: BunnyColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BunnyColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: BunnyColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: BunnyColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BunnyColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: BunnyColors.violet,
        inactiveTrackColor: BunnyColors.border,
        thumbColor: Colors.white,
        overlayColor: BunnyColors.violet.withValues(alpha: 0.2),
        trackHeight: 5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return BunnyColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BunnyColors.electricBlue;
          }
          return BunnyColors.surfaceHighlight;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BunnyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: BunnyColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BunnyColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
