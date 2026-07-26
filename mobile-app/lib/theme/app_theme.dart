import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light theme
  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3EDE3);
  static const Color primary = Color(0xFF2D1B0E);
  static const Color primaryLight = Color(0xFF8B4513);
  static const Color accent = Color(0xFFC8864A);
  static const Color accentSoft = Color(0xFFE8C49A);
  // Darkened variant of `accent` for solid-fill buttons/pills with white
  // text — `accent` itself is ~3:1 against white and fails WCAG AA (4.5:1)
  // for normal-size text. Use this instead of `accent` whenever accent is a
  // solid background color behind white text/icons.
  static const Color accentOnFill = Color(0xFF9C6330);
  static const Color textPrimary = Color(0xFF1A1008);
  static const Color textSecondary = Color(0xFF6B5744);
  static const Color textMuted = Color(0xFFA8957F);
  static const Color divider = Color(0xFFE8DDD0);
  static const Color cardBorder = Color(0xFFEDE4D8);
  static const Color like = Color(0xFFE05252);
  static const Color bookmark = Color(0xFFC8864A);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F0A06);
  static const Color darkSurface = Color(0xFF1A1208);
  static const Color darkSurfaceVariant = Color(0xFF261C10);
  static const Color darkPrimary = Color(0xFFE8C49A);
  static const Color darkAccent = Color(0xFFC8864A);
  // Same rationale as [accentOnFill]: the tip/underlying accent hue is
  // identical in dark mode, so solid-fill + white-text contexts need the
  // same darkened value regardless of theme.
  static const Color darkAccentOnFill = Color(0xFF9C6330);
  static const Color darkTextPrimary = Color(0xFFF5EDE0);
  static const Color darkTextSecondary = Color(0xFFB8A08A);
  static const Color darkTextMuted = Color(0xFF7A6855);
  static const Color darkDivider = Color(0xFF2E2018);
  static const Color darkCardBorder = Color(0xFF2E2018);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.lato(color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkAccent,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkBackground,
        onSecondary: AppColors.darkBackground,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(AppColors.darkTextPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.darkDivider,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.darkPrimary,
        labelStyle: GoogleFonts.lato(fontSize: 13, color: AppColors.darkTextSecondary),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkCardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.lato(color: AppColors.darkTextMuted),
      ),
    );
  }

  static TextTheme _textTheme(Color base) => TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: base),
    displayMedium: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w600, color: base),
    displaySmall: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: base),
    headlineLarge: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: base),
    headlineMedium: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: base),
    headlineSmall: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: base),
    titleLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: base),
    titleMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: base),
    titleSmall: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: base),
    bodyLarge: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w400, color: base, height: 1.7),
    bodyMedium: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w400, color: base, height: 1.6),
    bodySmall: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w400, color: base),
    labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: base),
    labelMedium: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500, color: base),
    labelSmall: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w500, color: base),
  );
}
