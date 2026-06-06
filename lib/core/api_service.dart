import 'package:dio/dio.dart';

class ApiService {
  // Your Render Backend URL
  static const String backendBaseUrl = "https://skillservice-backend.onrender.com";
  
  final Dio dio = Dio(BaseOptions(
    baseUrl: backendBaseUrl,
    headers: {"Content-Type": "application/json"},
    connectTimeout: const Duration(seconds: 15),
  ));

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
}