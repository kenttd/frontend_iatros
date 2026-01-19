class Participant {
  final String displayName;
  final String role;

  Participant({required this.displayName, required this.role});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      displayName: json['displayName'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'USER',
    );
  }
}

class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, Participant> participantDetails;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Parse participant details
    final participantDetailsJson =
        json['participantDetails'] as Map<String, dynamic>? ?? {};
    final participantDetails = participantDetailsJson.map(
      (key, value) =>
          MapEntry(key, Participant.fromJson(value as Map<String, dynamic>)),
    );

    return Conversation(
      id: json['id'] as String,
      participants: List<String>.from(json['participants'] as List),
      participantDetails: participantDetails,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Get the other participant's name (useful for displaying in UI)
  String getOtherParticipantName(String currentUserId) {
    final otherParticipantId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
    return participantDetails[otherParticipantId]?.displayName ?? 'Unknown';
  }

  /// Get the other participant's role
  String getOtherParticipantRole(String currentUserId) {
    final otherParticipantId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
    return participantDetails[otherParticipantId]?.role ?? 'USER';
  }
}
