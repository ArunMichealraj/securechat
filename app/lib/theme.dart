import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF008069);
  static const accent = Color(0xFF25D366);
  static const bubbleMine = Color(0xFFD9FDD3);
  static const bubbleTheirs = Colors.white;
  static const chatBackground = Color(0xFFEFEAE2);
  static const tickRead = Color(0xFF53BDEB);
  static const muted = Color(0xFF667781);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
