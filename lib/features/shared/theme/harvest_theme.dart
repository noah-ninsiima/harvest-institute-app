import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HarvestTheme {
  // Color Palette
  static const Color primaryNavy = Color(0xFF1A2035); // Dark Navy/Deep Indigo
  static const Color accentTeal = Color(0xFF00A3A9); // Light Teal/Cyan (Interactive)
  static const Color secondaryGold = Color(0xFFFFD700); // Gold/Warm Yellow (Subtle)
  static const Color textLight = Color(0xFFF5F5F5); // White/Very Light Gray
  static const Color textDark = Color(0xFF333333); // Dark Grey for light backgrounds
  static const Color backgroundDark = Color(0xFF121624); // Slightly darker than primary for scaffold background

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: Brightness.dark, // Dark theme base
        primary: primaryNavy,
        onPrimary: textLight,
        secondary: accentTeal,
        onSecondary: textLight, // Text on teal buttons should be light
        tertiary: secondaryGold,
        background: backgroundDark,
        surface: primaryNavy, // Cards, app bars use primary navy
        onSurface: textLight,
      ),
      scaffoldBackgroundColor: backgroundDark,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 57, 
          fontWeight: FontWeight.bold, 
          color: textLight
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 45, 
          fontWeight: FontWeight.w600, 
          color: textLight
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 36, 
          fontWeight: FontWeight.w500, 
          color: textLight
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: textLight
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 28, 
          fontWeight: FontWeight.w600, 
          color: textLight
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 24, 
          fontWeight: FontWeight.w500, 
          color: textLight
        ),
        titleLarge: GoogleFonts.robotoSlab(
          fontSize: 22, 
          fontWeight: FontWeight.w500, 
          color: textLight
        ),
        titleMedium: GoogleFonts.robotoSlab(
          fontSize: 16, 
          fontWeight: FontWeight.w500, 
          color: textLight
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 16, 
          fontWeight: FontWeight.normal, 
          color: textLight
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14, 
          fontWeight: FontWeight.normal, 
          color: textLight.withOpacity(0.8)
        ),
      ),

      // Component Themes
      appBarTheme: AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: textLight,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: textLight
        ),
        elevation: 0,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: textLight,
          textStyle: GoogleFonts.montserrat(
            fontSize: 16, 
            fontWeight: FontWeight.w600
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentTeal,
          textStyle: GoogleFonts.openSans(
            fontSize: 14, 
            fontWeight: FontWeight.w600
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryNavy.withOpacity(0.5),
        labelStyle: TextStyle(color: textLight.withOpacity(0.7)),
        hintStyle: TextStyle(color: textLight.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
      ),
      
      // Removed CardTheme to fix build error for now. Default card theme will be used but with colorScheme surface color.
    );
  }
}
