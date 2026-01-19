import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/messaging/models/conversation.dart';
import '../../features/messaging/models/message.dart';
import 'dart:convert';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  /// Check if database is available (not on web)
  bool get isAvailable => !kIsWeb;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('iatros.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        participants TEXT NOT NULL,
        participantDetails TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageAt TEXT,
        lastMessageSenderId TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        readAt TEXT,
        translatedText TEXT,
        detectedLanguage TEXT,
        FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Conversations ---

  Future<void> saveConversations(List<Conversation> conversations) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    final batch = db.batch();

    for (var conversation in conversations) {
      batch.insert('conversations', {
        'id': conversation.id,
        'participants': json.encode(conversation.participants),
        'participantDetails': json.encode(
          conversation.participantDetails.map(
            (key, value) => MapEntry(key, {
              'displayName': value.displayName,
              'role': value.role,
            }),
          ),
        ),
        'lastMessage': conversation.lastMessage,
        'lastMessageAt': conversation.lastMessageAt?.toIso8601String(),
        'lastMessageSenderId': conversation.lastMessageSenderId,
        'createdAt': conversation.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Conversation>> getConversations() async {
    if (kIsWeb) return []; // Return empty on web
    final db = await instance.database;
    final result = await db.query(
      'conversations',
      orderBy: 'lastMessageAt DESC',
    );

    return result.map((map) {
      final participantDetailsMap =
          json.decode(map['participantDetails'] as String)
              as Map<String, dynamic>;

      return Conversation(
        id: map['id'] as String,
        participants: List<String>.from(
          json.decode(map['participants'] as String),
        ),
        participantDetails: participantDetailsMap.map(
          (key, value) => MapEntry(key, Participant.fromJson(value)),
        ),
        lastMessage: map['lastMessage'] as String?,
        lastMessageAt: map['lastMessageAt'] != null
            ? DateTime.parse(map['lastMessageAt'] as String)
            : null,
        lastMessageSenderId: map['lastMessageSenderId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    }).toList();
  }

  // --- Messages ---

  Future<void> saveMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    final batch = db.batch();

    for (var message in messages) {
      batch.insert('messages', {
        'id': message.id,
        'conversationId': conversationId,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'text': message.text,
        'createdAt': message.createdAt.toIso8601String(),
        'readAt': message.readAt?.toIso8601String(),
        'translatedText': message.translatedText,
        'detectedLanguage': message.detectedLanguage,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (kIsWeb) return []; // Return empty on web
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    // We reverse here because the UI usually expects newest at the bottom or we reverse in UI??
    // Usually chat UIs reverse the list.
    // The query returns DESC (newest first).
    // If we want [Oldest .... Newest], we should return reversed of this, or query ASC.
    // Existing API likely returns DESC or ASC?
    // Let's assume standard behavior: return list of messages.
    // Codebase inspection earlier showed typical chat behaviors.

    return result
        .map(
          (map) => Message(
            id: map['id'] as String,
            senderId: map['senderId'] as String,
            senderName: map['senderName'] as String,
            text: map['text'] as String,
            createdAt: DateTime.parse(map['createdAt'] as String),
            readAt: map['readAt'] != null
                ? DateTime.parse(map['readAt'] as String)
                : null,
            translatedText: map['translatedText'] as String?,
            detectedLanguage: map['detectedLanguage'] as String?,
          ),
        )
        .toList();
  }

  Future<void> saveMessage(String conversationId, Message message) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    await db.insert('messages', {
      'id': message.id,
      'conversationId': conversationId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'createdAt': message.createdAt.toIso8601String(),
      'readAt': message.readAt?.toIso8601String(),
      'translatedText': message.translatedText,
      'detectedLanguage': message.detectedLanguage,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
