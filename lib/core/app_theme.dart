import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBg = Color(0xFFF0F2F5);
  static const Color textGrey = Color(0xFF65676B);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: fbBlue,
    // Use Google Inter on non-Android platforms. On Android use the system font (Roboto)
    // because some devices restrict dynamic font fetching which causes UI fallbacks or missing glyphs.
    // Also provide a fallback fontFamily for systems that do not support GoogleFonts.
    textTheme: (defaultTargetPlatform == TargetPlatform.android)
        ? ThemeData.light().textTheme.apply(fontFamily: 'Roboto')
        : GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(fontFamilyFallback: const ['Roboto', 'NotoSans']),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black, size: 24),
      titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 19),
    ),
    // Ensure a default icon theme so icons render consistently across platforms.
    iconTheme: const IconThemeData(color: Colors.black, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fbBlue, width: 1.5),
      ),
    ),
  );
}
