import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(height: 1.5),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      cardColor: const Color(0xFF1F2937),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(height: 1.5, color: Colors.white70),
      ),
      useMaterial3: true,
    );
  }

  // يمكن إضافة getters للألوان المتكررة
  static Color get gradientStart => const Color(0xFF2563EB);
  static Color get gradientEnd => const Color(0xFF10B981);

  static ColorScheme get lightColorScheme => light.colorScheme;
  static ColorScheme get darkColorScheme  => dark.colorScheme;
}