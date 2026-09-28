import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E6FD9);
  static const accent = Color(0xFF2F8CFF);
  static const bubbleMine = Color(0xFFDCEBFF);
  static const bubbleTheirs = Colors.white;
  static const chatBackground = Color(0xFFE8EEF6);
  static const tickRead = Color(0xFF0A84FF);
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
