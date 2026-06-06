// lib/core/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = "https://skillservice-backend.onrender.com";
  final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
    connectTimeout: const Duration(seconds: 15),
  ));
}

// lib/core/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBg = Color(0xFFF0F2F5);

  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: fbBg,
    primaryColor: fbBlue,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
    ),
  );
}