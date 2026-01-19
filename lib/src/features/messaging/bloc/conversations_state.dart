import 'package:equatable/equatable.dart';
import '../models/conversation.dart';
import '../models/doctor.dart';

enum ConversationsStatus { initial, loading, loaded, error }

class ConversationsState extends Equatable {
  final ConversationsStatus status;
  final List<Conversation> conversations;
  final List<Doctor> doctors;
  final String? errorMessage;
  final Conversation? newlyCreatedConversation;

  const ConversationsState({
    this.status = ConversationsStatus.initial,
    this.conversations = const [],
    this.doctors = const [],
    this.errorMessage,
    this.newlyCreatedConversation,
  });

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<Conversation>? conversations,
    List<Doctor>? doctors,
    String? errorMessage,
    Conversation? newlyCreatedConversation,
  }) {
    return ConversationsState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      doctors: doctors ?? this.doctors,
      errorMessage: errorMessage,
      newlyCreatedConversation: newlyCreatedConversation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    doctors,
    errorMessage,
    newlyCreatedConversation,
  ];
}
