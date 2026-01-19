class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? translatedText;
  final String? detectedLanguage;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.readAt,
    this.translatedText,
    this.detectedLanguage,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      translatedText: json['translatedText'] as String?,
      detectedLanguage: json['detectedLanguage'] as String?,
    );
  }

  /// Check if this message was sent by the given user
  bool isSentBy(String userId) => senderId == userId;
}
