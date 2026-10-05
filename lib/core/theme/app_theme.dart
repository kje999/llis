import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Philippine Lotto & PCSO official signature colors
  static const Color pcsoBlue = Color(0xFF0038A8);
  static const Color pcsoNavy = Color(0xFF0A1E4D);
  static const Color pcsoRed = Color(0xFFCE1126);
  static const Color pcsoGold = Color(0xFFFCD116);
  static const Color pcsoAmber = Color(0xFFF59E0B);
  static const Color primaryGold = Color(0xFFFFB300);
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color crimsonRed = Color(0xFFEF4444);

  // Dynamic PCSO Signature Gradients
  static const LinearGradient pcsoTricolorGradient = LinearGradient(
    colors: [Color(0xFF0038A8), Color(0xFF1E3A8A), Color(0xFFCE1126)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pcsoHeroGradient = LinearGradient(
    colors: [Color(0xFF071B44), Color(0xFF0038A8), Color(0xFF991B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pcsoGoldGradient = LinearGradient(
    colors: [Color(0xFFFCD116), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pcsoBlueGradient = LinearGradient(
    colors: [Color(0xFF0038A8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pcsoRedGradient = LinearGradient(
    colors: [Color(0xFFCE1126), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pcsoGreenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      seedColor: pcsoBlue,
      brightness: Brightness.light,
      primary: pcsoBlue,
      secondary: primaryGold,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: pcsoBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: pcsoBlue),
      unselectedIconTheme: IconThemeData(color: Colors.blueGrey),
      selectedLabelTextStyle: TextStyle(color: pcsoBlue, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: TextStyle(color: Colors.blueGrey),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: pcsoBlue,
      unselectedItemColor: Colors.blueGrey,
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
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedIconTheme: IconThemeData(color: primaryGold),
      unselectedIconTheme: IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: TextStyle(color: Colors.white70),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      labelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: Color(0xFF475569)),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E293B),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 14),
    ),
  );
}
