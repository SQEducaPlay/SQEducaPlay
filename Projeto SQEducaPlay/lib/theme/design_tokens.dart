import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignTokens {
  // Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFF57C00);
  static const Color success = Color(0xFF43A047);
  static const Color surface = Color(0xFFF3F9FF);
  static const Color card = Colors.white;

  // Spacing scale
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 20.0;

  // Typography helpers
  static TextTheme textTheme([TextTheme? base]) {
    final b = base ?? Typography.material2018().black;
    return GoogleFonts.interTextTheme(b).copyWith(
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary),
      scaffoldBackgroundColor: surface,
      cardColor: card,
      textTheme: textTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSM)),
        ),
      ),
    );
  }
}
