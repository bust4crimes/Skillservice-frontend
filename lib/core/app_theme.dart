// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBg = Color(0xFFF0F2F5);
  static const Color textGrey = Color(0xFF65676B);

  static ThemeData lightTheme = ThemeData(
    primaryColor: fbBlue,
    scaffoldBackgroundColor: fbBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black, 
        fontWeight: FontWeight.bold, 
        fontSize: 18
      ),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: fbBlue),
    useMaterial3: true,
  );
}