import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const amber = Color(0xFFF59E0B);
  static const bg = Color(0xFF0B0B0D);
  static const card = Color(0xFF141417);
  static const card2 = Color(0xFF1C1C21);
  static const border = Color(0xFF252529);
  static const fgMuted = Color(0xFF6A6A74);

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    fontFamily: GoogleFonts.outfit().fontFamily,
    colorScheme: ColorScheme.dark(
      primary: amber,
      surface: card,
      background: bg,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    cardColor: card,
    dividerColor: border,
  );

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    fontFamily: GoogleFonts.outfit().fontFamily,
    colorScheme: ColorScheme.light(
      primary: amber,
      surface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
  );

  // Category colors
  static const catColors = {
    'food':      Color(0xFFF97316),
    'transport': Color(0xFF3B82F6),
    'shopping':  Color(0xFFA855F7),
    'bills':     Color(0xFFEF4444),
    'salary':    Color(0xFF22C55E),
    'refund':    Color(0xFF06B6D4),
    'gift':      Color(0xFFEC4899),
    'other':     Color(0xFF6B7280),
  };

  static Color catColor(String id) => catColors[id] ?? catColors['other']!;
}
