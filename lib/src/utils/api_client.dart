import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Authenticated HTTP client that automatically adds Firebase tokens to all requests
class ApiClient {
  // Singleton pattern
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  // Base URL for your API
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  static const String baseUrl = 'https://api.iatros.kentdonovan.com';

  final http.Client _httpClient = http.Client();

  /// Get Firebase ID token for the current user
  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    print('Getting token for user: ${user?.email}');
    if (user == null) {
      print('❌ User not authenticated!');
      throw Exception('User not authenticated');
    }

    try {
      // Add timeout to detect network issues faster
      final token = await user.getIdToken().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Token request timed out - possible network issue');
          throw Exception(
            'Token request timed out. Check your internet connection.',
          );
        },
      );
      print('✅ Token retrieved successfully');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      // Check if this is a network error
      if (e.toString().contains('network-request-failed')) {
        print('🔴 NETWORK ERROR: Cannot reach Firebase servers.');
        print('   → Check emulator internet connection');
        print('   → Try restarting the emulator');
      }
      rethrow;
    }
  }

  /// Get base headers with Authorization token
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getToken();

    print('=== API Client Debug ===');
    print('Current user: ${FirebaseAuth.instance.currentUser?.email}');
    print('Token (first 20 chars): ${token?.substring(0, 20)}...');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final requestHeaders = await _getHeaders(additionalHeaders: headers);

    try {
      return await _httpClient.get(uri, headers: requestHeaders);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  /// POST request
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = await _getHeaders(additionalHeaders: headers);

    try {
      return await _httpClient.post(uri, headers: requestHeaders, body: body);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  /// PUT request
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = await _getHeaders(additionalHeaders: headers);

    try {
      return await _httpClient.put(
        uri,
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  /// PATCH request
  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = await _getHeaders(additionalHeaders: headers);

    try {
      return await _httpClient.patch(
        uri,
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      throw Exception('PATCH request failed: $e');
    }
  }

  /// DELETE request
  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final requestHeaders = await _getHeaders(additionalHeaders: headers);

    try {
      return await _httpClient.delete(
        uri,
        headers: requestHeaders,
        body: body != null ? json.encode(body) : null,
      );
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}
