import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// COLOR PALETTE
/// Inspired by the "Monex" reference: deep navy-black base with a punchy
/// lime accent. We keep it restrained — lime is used sparingly for primary
/// actions, active states, and positive numbers. Everything else is
/// desaturated near-blacks and soft greys for an editorial, premium feel.
/// ─────────────────────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const bg0 = Color(0xFF0A0E14); // app background (deepest)
  static const bg1 = Color(0xFF0F141C); // base surfaces
  static const bg2 = Color(0xFF161D28); // cards
  static const bg3 = Color(0xFF1E2733); // elevated cards / inputs

  // Borders / dividers
  static const line   = Color(0xFF26303D);
  static const lineHi = Color(0xFF36424F);

  // Accent — lime
  static const lime    = Color(0xFFCFFF4D);
  static const limeDim = Color(0x22CFFF4D);
  static const limeMid = Color(0x55CFFF4D);

  // Text
  static const t1 = Color(0xFFF3F5F7); // primary text
  static const t2 = Color(0xFF8A93A3); // secondary / labels
  static const t3 = Color(0xFF49525F); // tertiary / disabled

  // Semantic
  static const positive = lime;             // savings / income
  static const negative = Color(0xFFFF6B6B); // spend / over-budget
  static const warn     = Color(0xFFFFC857);

  // Category palette — assigned round-robin to user tags
  static const catColors = <Color>[
    Color(0xFFCFFF4D), // lime
    Color(0xFF6FB7FF), // sky blue
    Color(0xFFFF8A65), // coral
    Color(0xFFB39DFF), // violet
    Color(0xFF4DD0E1), // teal
    Color(0xFFFFD166), // amber
    Color(0xFFFF6FA1), // pink
    Color(0xFF8BC34A), // green
  ];
}

/// ─────────────────────────────────────────────────────────────────────────
/// TEXT STYLES
/// We use a geometric sans (Manrope) for UI text and a monospace (JetBrains
/// Mono) for all numeric/currency values — gives the "financial terminal"
/// precision feel from the reference, without leaning on a serif.
/// ─────────────────────────────────────────────────────────────────────────
class AppText {
  static TextStyle get display => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.t1,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.t1,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.t1,
      );

  static TextStyle get bodyMuted => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.t2,
      );

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.t2,
        letterSpacing: 1.2,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.t3,
      );

  // Monospace numeric styles
  static TextStyle numberLarge({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.t1,
        letterSpacing: -1,
      );

  static TextStyle numberMedium({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.t1,
        letterSpacing: -0.5,
      );

  static TextStyle numberSmall({Color? color}) => GoogleFonts.jetBrainsMono(
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
    primaryColor: AppColors.lime,
    fontFamily: GoogleFonts.manrope().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lime,
      secondary: AppColors.lime,
      surface: AppColors.bg2,
      error: AppColors.negative,
    ),
    dividerColor: AppColors.line,
    splashFactory: InkRipple.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
      ),
      hintStyle: AppText.bodyMuted,
    ),
  );
}
