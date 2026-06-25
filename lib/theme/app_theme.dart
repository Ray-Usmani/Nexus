import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// COLOR PALETTE — Obsidian Amber
/// Deep obsidian black base with vibrant amber-orange accent.
/// Inspired by a premium fintech glassmorphism aesthetic.
/// ─────────────────────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds / Surfaces
  static const bg0         = Color(0xFF131313); // background (deepest)
  static const bg1         = Color(0xFF0E0E0E); // surface-container-lowest
  static const bg2         = Color(0xFF1C1B1B); // surface-container-low (cards)
  static const bg3         = Color(0xFF201F1F); // surface-container
  static const bg4         = Color(0xFF2A2A2A); // surface-container-high
  static const bg5         = Color(0xFF353534); // surface-container-highest

  // Borders / dividers
  static const line        = Color(0xFF584238); // outline-variant
  static const lineHi      = Color(0xFF2A2A2A); // surface-container-high

  // Accent — amber/orange
  static const amber       = Color(0xFFFFB693); // primary
  static const amberBright = Color(0xFFFF7A2F); // primary-container (CTA buttons)
  static const amberDim    = Color(0xFFFFDBCC); // primary-fixed (very soft)

  // Text
  static const t1 = Color(0xFFE5E2E1); // on-surface (primary text)
  static const t2 = Color(0xFFDFC0B2); // on-surface-variant (secondary)
  static const t3 = Color(0xFFA78B7F); // outline (tertiary / disabled)

  // On-accent
  static const onAmber     = Color(0xFF561F00); // on-primary
  static const onAmberBright = Color(0xFF612400); // on-primary-container

  // Semantic
  static const positive    = Color(0xFFC8C6C5); // secondary (neutral positive)
  static const negative    = Color(0xFFFFB4AB); // error
  static const negativeContainer = Color(0xFF93000A); // error-container
  static const warn        = Color(0xFFFFD166);

  // Secondary
  static const secondary   = Color(0xFFC8C6C5);
  static const secondaryContainer = Color(0xFF474746);
  static const onSecondaryContainer = Color(0xFFB7B5B4);

  // Tertiary
  static const tertiary    = Color(0xFFC7C6C6);

  // Category palette — assigned round-robin to user tags
  static const catColors = <Color>[
    Color(0xFFFFB693), // amber (primary)
    Color(0xFF6FB7FF), // sky blue
    Color(0xFFFF8A65), // coral
    Color(0xFFB39DFF), // violet
    Color(0xFF4DD0E1), // teal
    Color(0xFFFFD166), // yellow-amber
    Color(0xFFFF6FA1), // pink
    Color(0xFF8BC34A), // green
  ];
}

/// ─────────────────────────────────────────────────────────────────────────
/// TEXT STYLES
/// Plus Jakarta Sans for headlines/display, Inter for body/functional text.
/// ─────────────────────────────────────────────────────────────────────────
class AppText {
  // Display — large financial numbers & screen titles
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.t1,
        letterSpacing: -0.5,
      );

  // Headline large (desktop)
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.t1,
        height: 1.25,
      );

  // Headline large mobile
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.t1,
        height: 1.33,
      );

  // Body / functional text
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.t1,
        height: 1.5,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.t2,
        height: 1.43,
      );

  // Label medium — 14px, semi-bold
  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.t2,
        letterSpacing: 0.01 * 14,
        height: 1.43,
      );

  // Label small — 12px, bold, uppercase-ready
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.t2,
        letterSpacing: 0.05 * 12,
        height: 1.33,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.t3,
        height: 1.3,
      );

  // Numeric styles — use Plus Jakarta Sans for a modern financial feel
  static TextStyle numberLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.t1,
        letterSpacing: -1,
      );

  static TextStyle numberMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.t1,
        letterSpacing: -0.5,
      );

  static TextStyle numberSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.t1,
      );
}

/// ─────────────────────────────────────────────────────────────────────────
/// THEME DATA
/// ─────────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg0,
    primaryColor: AppColors.amber,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.amber,
      onPrimary: AppColors.onAmber,
      primaryContainer: AppColors.amberBright,
      onPrimaryContainer: AppColors.onAmberBright,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: AppColors.bg2,
      onSurface: AppColors.t1,
      onSurfaceVariant: AppColors.t2,
      outline: AppColors.t3,
      outlineVariant: AppColors.line,
      error: AppColors.negative,
      errorContainer: AppColors.negativeContainer,
    ),
    dividerColor: AppColors.line,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg0,
      foregroundColor: AppColors.t1,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.t1,
      ),
      iconTheme: const IconThemeData(color: AppColors.t2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
      hintStyle: AppText.bodyMuted,
      labelStyle: AppText.labelMd.copyWith(color: AppColors.t3),
      floatingLabelStyle: AppText.labelMd.copyWith(color: AppColors.amber),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg2,
      labelStyle: AppText.labelMd,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.onAmber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: AppText.label.copyWith(
          fontSize: 13,
          letterSpacing: 0.05 * 13,
          color: AppColors.onAmber,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: AppColors.onAmber,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg1,
      selectedItemColor: AppColors.amber,
      unselectedItemColor: AppColors.t3,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppText.h2.copyWith(fontSize: 20),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.amber,
        textStyle: AppText.body,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.t2,
      textColor: AppColors.t1,
    ),
  );
}
