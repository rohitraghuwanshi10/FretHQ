import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds & Surface
  static const Color background = Color(0xFF0C0D14);
  static const Color surface = Color(0xFF141624);
  static const Color surfaceLight = Color(0xFF1D2035);
  static const Color surfaceElevated = Color(0xFF262A44);
  static const Color surfaceGlass = Color(0x99161828);

  // Borders
  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const Color borderMedium = Color(0x33FFFFFF);
  static const Color borderGlass = Color(0x2EFFFFFF);

  // Accents & Neons
  static const Color gold = Color(0xFFFFB800);
  static const Color goldGlow = Color(0x40FFB800);
  static const Color amberDark = Color(0xFFD97706);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0x4006B6D4);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleDark = Color(0xFF6D28D9);
  static const Color purpleGlow = Color(0x408B5CF6);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x4010B981);

  static const Color coral = Color(0xFFEF4444);
  static const Color coralGlow = Color(0x40EF4444);

  static const Color orange = Color(0xFFF97316);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFC01D), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1C1E32), Color(0xFF121422)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF181A2C), Color(0xFF101220)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF231E3D), Color(0xFF141224)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final outfitFont = GoogleFonts.outfit();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      canvasColor: AppColors.background,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      fontFamily: outfitFont.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.cyan,
        tertiary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: AppColors.goldGlow,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderMedium),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
