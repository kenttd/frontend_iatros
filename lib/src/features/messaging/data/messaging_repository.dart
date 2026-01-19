import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/doctor.dart';
import '../../../core/database/local_database.dart';

class MessagingRepository {
  final ApiClient _apiClient;

  MessagingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Fetch all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    // 1. Fetch from Local DB first (Instant load)
    try {
      final localConversations = await LocalDatabase.instance
          .getConversations();
      if (localConversations.isNotEmpty) {
        // Find a way to return this, but also trigger network fetch.
        // Since this is a Future, we return what we have.
        // The bloc calls streamConversations() separately which will handle updates.
        // But for the initial await, returning local data matches "Instant Load".

        // HOWEVER, if we ONLY return local, we might miss fresh data if stream isn't listening yet?
        // The Bloc listens to stream BEFORE calling getConversations (or in parallel).
        // So returning local here is safe.
        // We SHOULD try to background fetch here too if we want to be sure?
        // No, let the stream/polling handle the network.
      }
    } catch (e) {
      print('Error fetching local conversations: $e');
    }

    // 2. Try Network (if needed, or just return local and let stream update?)
    // If we only return local, and it's empty, we should fetch network.
    // If we return local, and it's stale, the stream will update it.

    // Better strategy for this specific method (which returns Future):
    // Try Local. If empty, await Network. If not empty, return Local (and let stream update).
    // Actually, to ensure freshness if not streaming, we usually Fetch Network.
    // But since we use polling streams, we can rely on that.

    // Let's return local if available, otherwise fetch network.
    final localData = await LocalDatabase.instance.getConversations();
    if (localData.isNotEmpty) {
      _refreshConversationsInBackground(); // Fire and forget
      return localData;
    }

    try {
      return await _fetchAndSaveConversations();
    } catch (e) {
      // If network fails and we have no local data, throw.
      // If we had local data we returned it above.
      rethrow;
    }
  }

  Future<void> _refreshConversationsInBackground() async {
    try {
      await _fetchAndSaveConversations();
    } catch (_) {}
  }

  Future<List<Conversation>> _fetchAndSaveConversations() async {
    final response = await _apiClient.get('/messaging/conversations');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final conversations = data
          .map((json) => Conversation.fromJson(json))
          .toList();
      await LocalDatabase.instance.saveConversations(conversations);
      return conversations;
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  /// Create a new conversation with a doctor
  Future<Conversation> createConversation(String doctorId) async {
    try {
      final response = await _apiClient.post(
        '/messaging/conversations',
        body: json.encode({'participantId': doctorId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception(
          'Failed to create conversation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Fetch messages for a conversation (initial load)
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    // Local first
    final localMessages = await LocalDatabase.instance.getMessages(
      conversationId,
      limit: limit,
    );
    if (localMessages.isNotEmpty) {
      _refreshMessagesInBackground(conversationId, limit);
      return localMessages;
    }

    try {
      return await _fetchAndSaveMessages(conversationId, limit: limit);
    } catch (e) {
      return localMessages; // Return empty list if network fails and no local
    }
  }

  Future<void> _refreshMessagesInBackground(
    String conversationId,
    int limit,
  ) async {
    try {
      await _fetchAndSaveMessages(conversationId, limit: limit);
    } catch (_) {}
  }

  Future<List<Message>> _fetchAndSaveMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      '/messaging/conversations/$conversationId/messages',
      queryParameters: {'limit': limit.toString()},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final messages = data.map((json) => Message.fromJson(json)).toList();
      await LocalDatabase.instance.saveMessages(conversationId, messages);
      return messages;
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  /// Send a message in a conversation
  Future<Message> sendMessage(String conversationId, String text) async {
    // Generate a temporary ID or just send to API?
    // For true offline support we'd queue it.
    // For now, let's keep it simple: API then Save.
    // Or Optimistic: Save locally (with temp ID?) -> UI updates -> API calls -> Replace ID.
    // Complexity warning: ID collision.
    // Let's just do API -> Save for now to ensure consistency,
    // but the read will be from DB.

    try {
      final response = await _apiClient.post(
        '/messaging/conversations/$conversationId/messages',
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = Message.fromJson(data);
        await LocalDatabase.instance.saveMessage(conversationId, message);
        return message;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Fetch available doctors
  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _apiClient.get('/messaging/doctors');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch doctors: $e');
    }
  }

  /// Stream messages using polling
  Stream<List<Message>> streamMessages(String conversationId) async* {
    // Yield local first
    yield await LocalDatabase.instance.getMessages(conversationId);

    while (true) {
      try {
        final messages = await _fetchAndSaveMessages(conversationId);
        yield messages;
      } catch (e) {
        // Yield local if network fails?
        // Or just silence.
        // If we yield local here, we might overwrite error state?
        // Let's just rely on the first yield + updates.
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Stream conversations using polling
  Stream<List<Conversation>> streamConversations() async* {
    yield await LocalDatabase.instance.getConversations();

    while (true) {
      try {
        final conversations = await _fetchAndSaveConversations();
        yield conversations;
      } catch (e) {
        // Ignore errors during polling
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Request a summary of the conversation
  Future<String> getChatSummary(String conversationId) async {
    try {
      final response = await _apiClient.post(
        '/chat/summary',
        body: json.encode({'conversationId': conversationId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else {
        throw Exception('Failed to get summary: ${response.statusCode}');
      }
    } catch (e) {
      throw new Exception('Failed to get summary: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      final response = await _apiClient.delete(
        '/messaging/conversations/$conversationId/messages/$messageId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
}
