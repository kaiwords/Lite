import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'paper.dart';

export 'book_pager.dart';
export 'paper.dart';

/// "Real book" palette: aged paper, printed ink, fountain-pen blue for the
/// one accent (actions, active states, focus) and a red ribbon bookmark.
/// Dark mode is the same book read by lamplight. Every text/background pair
/// below is at least 4.5:1.
class AppColors {
  // Light theme
  static const Color background = Color(0xFFEFE6D2); // the desk / book block
  static const Color surface = Color(0xFFF8F2E4); // a single page
  static const Color surfaceVariant = Color(0xFFE7DCC4); // page edges, chips
  static const Color primary = Color(0xFF2A231C); // ink
  static const Color primaryLight = Color(0xFF4F4436);
  static const Color accent = Color(0xFF2D4A6B); // fountain-pen blue-black
  static const Color accentSoft = Color(0xFFD5DDE6);
  // Solid-fill backgrounds behind white text/icons (9:1 against white).
  static const Color accentOnFill = Color(0xFF2D4A6B);
  static const Color textPrimary = Color(0xFF2A231C);
  static const Color textSecondary = Color(0xFF4F4436);
  static const Color textMuted = Color(0xFF6B5E4C);
  static const Color divider = Color(0xFFD8CBB0);
  static const Color cardBorder = Color(0xFFD2C3A6);
  static const Color like = Color(0xFFA8322A);
  static const Color bookmark = Color(0xFF9B2F26); // ribbon red

  // Dark theme: reading by lamplight, never pure black.
  static const Color darkBackground = Color(0xFF1B1712);
  static const Color darkSurface = Color(0xFF24201A);
  static const Color darkSurfaceVariant = Color(0xFF2F2921);
  static const Color darkPrimary = Color(0xFFEDE3CF);
  static const Color darkAccent = Color(0xFFA9C1DD);
  // White text needs a deeper fill than the light accent used for text.
  static const Color darkAccentOnFill = Color(0xFF3A5A80);
  static const Color darkTextPrimary = Color(0xFFEDE3CF);
  static const Color darkTextSecondary = Color(0xFFC9BBA2);
  static const Color darkTextMuted = Color(0xFFA29479);
  static const Color darkDivider = Color(0xFF3B3329);
  static const Color darkCardBorder = Color(0xFF3B3329);
  static const Color darkBookmark = Color(0xFFC2493E);
}

/// The app's book faces. Screens call these instead of `GoogleFonts.*` so
/// the faces are chosen in one place. EB Garamond sets titles like a book's
/// title page; Crimson Pro carries reading text and interface labels.
class AppFonts {
  // Crimson Pro has a small x-height, so interface sizes written for a sans
  // are scaled up to read at the same visual size.
  static const _uiScale = 1.08;

  /// Headings, titles, and brand text.
  static TextStyle display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) => GoogleFonts.ebGaramond(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );

  /// Interface text: labels, buttons, metadata, captions.
  static TextStyle ui({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) => GoogleFonts.crimsonPro(
    fontSize: fontSize == null ? null : fontSize * _uiScale,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );

  /// Long-form reading text (post bodies, the book reader).
  static TextStyle reading({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) => GoogleFonts.crimsonPro(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}

class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    ink: AppColors.textPrimary,
    secondaryText: AppColors.textSecondary,
    muted: AppColors.textMuted,
    divider: AppColors.divider,
    cardBorder: AppColors.cardBorder,
    chipSelected: AppColors.primary,
    accent: AppColors.accent,
    accentFill: AppColors.accentOnFill,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    ink: AppColors.darkTextPrimary,
    secondaryText: AppColors.darkTextSecondary,
    muted: AppColors.darkTextMuted,
    divider: AppColors.darkDivider,
    cardBorder: AppColors.darkCardBorder,
    chipSelected: AppColors.darkPrimary,
    accent: AppColors.darkAccent,
    accentFill: AppColors.darkAccentOnFill,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color ink,
    required Color secondaryText,
    required Color muted,
    required Color divider,
    required Color cardBorder,
    required Color chipSelected,
    required Color accent,
    required Color accentFill,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    // Book-like corners: pages and bookplates are nearly square.
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );
    final buttonText = AppFonts.ui(fontSize: 15, fontWeight: FontWeight.w600);
    // 48px minimum keeps every themed button a comfortable touch target.
    const buttonMinSize = Size(48, 48);

    return base.copyWith(
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accentFill,
              onPrimary: Colors.white,
              secondary: accent,
              onSecondary: background,
              surface: surface,
              onSurface: ink,
            )
          : ColorScheme.light(
              primary: accentFill,
              onPrimary: Colors.white,
              secondary: accent,
              onSecondary: Colors.white,
              surface: surface,
              onSurface: ink,
            ),
      scaffoldBackgroundColor: background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // iOS keeps its native slide so the swipe-back gesture still works.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: BookPageTransitionsBuilder(),
          TargetPlatform.windows: BookPageTransitionsBuilder(),
          TargetPlatform.linux: BookPageTransitionsBuilder(),
          TargetPlatform.fuchsia: BookPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(ink),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: divider,
        titleTextStyle: AppFonts.display(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: chipSelected,
        labelStyle: AppFonts.ui(fontSize: 13, color: secondaryText),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(color: cardBorder, width: 0.6),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentFill,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentFill,
          foregroundColor: Colors.white,
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          // Muted ink, not the hairline card border: interactive borders
          // need 3:1 against the page to read as a button.
          side: BorderSide(color: muted),
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: AppFonts.ui(color: muted),
      ),
    );
  }

  static TextTheme _textTheme(Color base) => TextTheme(
    displayLarge: AppFonts.display(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: base,
    ),
    displayMedium: AppFonts.display(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    displaySmall: AppFonts.display(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    headlineLarge: AppFonts.display(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: base,
    ),
    headlineMedium: AppFonts.display(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    headlineSmall: AppFonts.display(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    titleLarge: AppFonts.ui(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: base,
    ),
    titleMedium: AppFonts.ui(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    titleSmall: AppFonts.ui(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    bodyLarge: AppFonts.reading(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: base,
      height: 1.7,
    ),
    bodyMedium: AppFonts.reading(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: base,
      height: 1.6,
    ),
    bodySmall: AppFonts.ui(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: base,
    ),
    labelLarge: AppFonts.ui(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: base,
    ),
    labelMedium: AppFonts.ui(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: base,
    ),
    labelSmall: AppFonts.ui(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: base,
    ),
  );
}
