import 'package:flutter/material.dart';

/// Calm Islamic palette: deep green, teal, gold and cream.
class AppColors {
  static const deep = Color(0xFF0B2E24);
  static const green = Color(0xFF134E3A);
  static const teal = Color(0xFF1F6F5C);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE9D8A6);
  static const cream = Color(0xFFFBF6E9);
  static const correct = Color(0xFF2E9E6B);
  static const wrong = Color(0xFFC0533E);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.dark,
    primary: AppColors.gold,
    onPrimary: AppColors.deep,
    surface: AppColors.green,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.deep,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.cream,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.cream,
      ),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
