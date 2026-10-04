import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Philippine Lotto vibrant signature colors
  static const Color primaryGold = Color(0xFFFFB300);
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color crimsonRed = Color(0xFFEF4444);

  // Game specific colors
  static const Color ultraColor = Color(0xFF8B5CF6); // Purple
  static const Color grandColor = Color(0xFFEC4899); // Pink
  static const Color superColor = Color(0xFFF59E0B); // Amber
  static const Color megaColor = Color(0xFF3B82F6);  // Blue
  static const Color lottoColor = Color(0xFF10B981); // Emerald

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: primaryGold,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF3B82F6),
      secondary: primaryGold,
      surface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E293B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
