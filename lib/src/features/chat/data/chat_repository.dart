import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/api_client.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String> sendMessage(String message) async {
    try {
      final response = await _apiClient.post(
        '/chat',
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}
