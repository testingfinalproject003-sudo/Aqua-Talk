import 'package:flutter/material.dart';

class AppTheme {
  // --- Custom Colors ---
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF80CBC4);

  // ☀️ LIGHT THEME
  static ThemeData light = ThemeData(
    useMaterial3: true, // Modern Flutter apps ke liye zaroori hai
    brightness: Brightness.light,
    primaryColor: darkTeal,
    scaffoldBackgroundColor: Colors.white,
    
    // AppBar Styling
    appBarTheme: const AppBarTheme(
      backgroundColor: darkTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),

    // Floating Action Button (FAB)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkTeal,
      foregroundColor: Colors.white,
    ),

    // Color Scheme (Material 3 style)
    colorScheme: ColorScheme.light(
      primary: darkTeal,
      secondary: accentTeal,
      surface: Colors.white,
    ),
  );

  // 🌙 DARK THEME
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkTeal,
    scaffoldBackgroundColor: const Color(0xFF002520), // Thoda soft dark teal background
    
    appBarTheme: const AppBarTheme(
      backgroundColor: darkTeal,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    colorScheme: ColorScheme.dark(
      primary: darkTeal,
      secondary: accentTeal,
      surface: const Color(0xFF002520),
    ),
  );
}