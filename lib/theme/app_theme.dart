import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Modern Brand Color (Clean Electric Blue / Sapphire)
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryGlow = Color(0x333B82F6);

  // Modern Functional Accents
  static const Color cyan = Color(0xFF0EA5E9); // Sky Cyan
  static const Color cyanGlow = Color(0x330EA5E9);

  static const Color purple = Color(0xFF6366F1); // Modern Indigo
  static const Color purpleDark = Color(0xFF4F46E5);
  static const Color purpleGlow = Color(0x336366F1);

  static const Color emerald = Color(0xFF10B981); // Mint / In-Tune / Success
  static const Color emeraldGlow = Color(0x3310B981);

  static const Color coral = Color(0xFFF43F5E); // Rose / Flat / Error
  static const Color coralGlow = Color(0x33F43F5E);

  static const Color orange = Color(0xFFF97316);

  // Subtle Warm Honey (kept as secondary utility accent, never overwhelming)
  static const Color gold = Color(0xFF3B82F6); // Re-routed to Electric Blue for backwards compatibility
  static const Color goldGlow = Color(0x333B82F6);
  static const Color amberDark = Color(0xFF2563EB);

  // Dark Theme Palette (Deep Zinc / Obsidian Slate)
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF131317);
  static const Color surfaceLight = Color(0xFF1B1B22);
  static const Color surfaceElevated = Color(0xFF23232C);
  static const Color surfaceGlass = Color(0xDE131317);

  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const Color borderMedium = Color(0x33FFFFFF);
  static const Color borderGlass = Color(0x2EFFFFFF);

  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Light Theme Palette (Clean Pure Porcelain & Slate)
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF4F4F5);
  static const Color lightSurfaceElevated = Color(0xFFE4E4E7);
  static const Color lightSurfaceGlass = Color(0xF2FFFFFF);

  static const Color lightBorderSubtle = Color(0xFFE4E4E7);
  static const Color lightBorderMedium = Color(0xFFD4D4D8);
  static const Color lightBorderGlass = Color(0xFFE4E4E7);

  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFFA1A1AA);

  // Gradients (Subtle, sleek, non-garish)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = primaryGradient;

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF16161B), Color(0xFF101014)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF171923), Color(0xFF0E1017)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightSurfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightHeroCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F4F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Context-aware color helpers
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? background : lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;
  }

  static Color getSurfaceElevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceElevated : lightSurfaceElevated;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textSecondary : lightTextSecondary;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? borderSubtle : lightBorderSubtle;
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final outfitFont = GoogleFonts.outfit();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      canvasColor: AppColors.background,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      fontFamily: outfitFont.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
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
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderMedium),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final outfitFont = GoogleFonts.outfit();

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primaryDark,
      canvasColor: AppColors.lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      fontFamily: outfitFont.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.cyan,
        tertiary: AppColors.purple,
        surface: AppColors.lightSurface,
        error: AppColors.coral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1,
        shadowColor: const Color(0x0F09090B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorderMedium),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
