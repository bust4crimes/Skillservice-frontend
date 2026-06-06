import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBg = Color(0xFFF0F2F5);
  static const Color textGrey = Color(0xFF65676B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fbBg,
      primaryColor: fbBlue,
      textTheme: GoogleFonts.interTextTheme(),
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
      colorScheme: ColorScheme.fromSeed(
        seedColor: fbBlue,
        background: fbBg,
      ),
    );
  }
}