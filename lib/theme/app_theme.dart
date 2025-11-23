import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF0000);

  // Dark theme colors
  static const Color backgroundLight = Color(0xFF121212);
  static const Color backgroundDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFA0AEC0);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF333333);

  // Light theme colors
  static const Color backgroundLightMode = Color(0xFFFFFFFF);
  static const Color backgroundDarkMode = Color(0xFFF5F5F5);
  static const Color textLightMode = Color(0xFF000000);
  static const Color textDarkMode = Color(0xFF666666);
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  static const Color borderLightMode = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: backgroundDark,
        background: backgroundLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
      ),
      // CardTheme yerine CardThemeData kullanıldı
      cardTheme: CardThemeData(
        color: backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLightMode,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surfaceLightMode,
        background: backgroundLightMode,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLightMode,
        elevation: 0,
        iconTheme: IconThemeData(color: textLightMode),
        titleTextStyle: TextStyle(
          color: textLightMode,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      // CardTheme yerine CardThemeData kullanıldı
      cardTheme: CardThemeData(
        color: surfaceLightMode,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
