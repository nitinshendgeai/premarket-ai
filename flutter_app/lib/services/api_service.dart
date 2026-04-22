// lib/services/api_service.dart
// Handles all HTTP communication with the FastAPI backend.
// Throws typed ApiException on any failure so the UI can render clear errors.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analysis_model.dart';

/// Change this to your server's IP when running on a physical device.
/// Android emulator  → http://10.0.2.2:8000
/// iOS simulator     → http://127.0.0.1:8000
/// Physical device   → http://<your-machine-local-ip>:8000
const String kBaseUrl = 'https://premarket-assistant-production.up.railway.app';

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 30);

  /// Fetch the full pre-market analysis from the backend.
  static Future<AnalysisResult> fetchPremarketAnalysis() async {
    final uri = Uri.parse('$kBaseUrl/premarket-analysis');

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AnalysisResult.fromJson(json);
      }

      // Try to parse FastAPI error detail
      String detail = 'HTTP ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        detail = err['detail']?.toString() ?? detail;
      } catch (_) {}

      throw ApiException(detail, statusCode: response.statusCode);

    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Request timed out (30s).\n\nThe backend may be starting up or fetching live data. Please retry.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot reach server at $kBaseUrl\n\n'
        'Make sure the FastAPI backend is running:\n'
        '  uvicorn main:app --reload\n\n'
        'Error: ${e.message}',
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Quick health check — returns true if the server is reachable.
  static Future<bool> ping() async {
    try {
      final resp = await http
          .get(Uri.parse('$kBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
