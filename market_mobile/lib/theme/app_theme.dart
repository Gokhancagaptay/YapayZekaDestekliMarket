// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00695C);     // Teal 700
  static const Color secondaryColor = Color(0xFFFF7043);   // Deep Orange 400
  static const Color backgroundColor = Color(0xFFF5F5F5);  // Light grey
  static const Color surfaceColor = Colors.white;
  static const Color accentColor = Color(0xFFFFC400);      // Amber 600

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    scaffoldBackgroundColor: backgroundColor,

    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[800]),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: primaryColor,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
      iconTheme: IconThemeData(color: primaryColor),
    ),

    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,      // eskiden primary
        foregroundColor: Colors.white,       // eskiden onPrimary
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    iconTheme: IconThemeData(color: primaryColor, size: 24),
  );
}
