import 'package:flutter/foundation.dart';
import 'package:skillservice_frontend/core/api_service.dart';

class LocationService {
  Future<List<String>> searchLocations(String query) async {
    if (query.trim().length < 3) return [];

    try {
      final response = await ApiService().client.get(
        '/locations/search',
        queryParameters: {'query': query.trim()},
      );
      final data = response.data;
      if (data is List) {
        return data.map((item) => item.toString()).where((s) => s.length > 3).toList();
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
    return [];
  }
}
