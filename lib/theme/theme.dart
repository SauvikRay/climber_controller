import 'package:flutter/material.dart';

class RobotTheme {
  // Brand Colors
  static const Color spaceDark = Color(0xFF070B19);
  static const Color surfaceDark = Color(0xFF0E152B);
  static const Color cardDark = Color(0x9A162244); // semi-transparent glass

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonTeal = Color(0xFF05FFC8);
  static const Color neonPurple = Color(0xFFAC26FF);
  static const Color neonOrange = Color(0xFFFF851B);
  static const Color neonAmber = Color(0xFFFFD700);

  // Neutral Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  // Gradient Colors
  static const LinearGradient cyberGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFFAC26FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCyberGradient = LinearGradient(
    colors: [Color(0xFF0A0F24), Color(0xFF130E26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeBtnGradient = LinearGradient(
    colors: [Color(0xFF05FFC8), Color(0xFF00F0FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box Shadows for Neon Glow
  static List<BoxShadow> cyanGlow({double radius = 10, double opacity = 0.5}) {
    return [
      BoxShadow(
        color: neonCyan.withValues(alpha: opacity),
        blurRadius: radius,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: neonCyan.withValues(alpha: opacity * 0.4),
        blurRadius: radius * 2,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> tealGlow({double radius = 10, double opacity = 0.5}) {
    return [
      BoxShadow(
        color: neonTeal.withValues(alpha: opacity),
        blurRadius: radius,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: neonTeal.withValues(alpha: opacity * 0.4),
        blurRadius: radius * 2,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> purpleGlow({
    double radius = 10,
    double opacity = 0.5,
  }) {
    return [
      BoxShadow(
        color: neonPurple.withValues(alpha: opacity),
        blurRadius: radius,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: neonPurple.withValues(alpha: opacity * 0.4),
        blurRadius: radius * 2,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> orangeGlow({
    double radius = 10,
    double opacity = 0.5,
  }) {
    return [
      BoxShadow(
        color: neonOrange.withValues(alpha: opacity),
        blurRadius: radius,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: neonOrange.withValues(alpha: opacity * 0.4),
        blurRadius: radius * 2,
        spreadRadius: 2,
      ),
    ];
  }

  // Card Decorations
  static BoxDecoration glassCardDecoration({
    Color borderColor = Colors.white10,
  }) {
    return BoxDecoration(
      color: cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // App Theme Setup
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: spaceDark,
      cardColor: surfaceDark,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
      ),
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: surfaceDark,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
