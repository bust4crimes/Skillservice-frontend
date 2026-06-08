// lib/core/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: "https://skillservice-backend.onrender.com",
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String token = await user.getIdToken(true) ?? '';
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Use kDebugMode guard and print for simpler analysis output
        if (kDebugMode) {
          print("Backend Error: ${e.response?.statusCode} - ${e.message} - ${e.response?.data}");
        }
        return handler.next(e);
      }
    ));
  }

  Dio get client => _dio;
  Dio get dio => _dio;
}
