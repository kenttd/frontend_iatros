import 'package:equatable/equatable.dart';
import '../models/message.dart';

enum MessageThreadStatus { initial, loading, loaded, sending, error }

class MessageThreadState extends Equatable {
  final MessageThreadStatus status;
  final List<Message> messages;
  final String? conversationId;
  final String? errorMessage;
  final String? summary;
  final bool isSummarizing;

  const MessageThreadState({
    this.status = MessageThreadStatus.initial,
    this.messages = const [],
    this.conversationId,
    this.errorMessage,
    this.summary,
    this.isSummarizing = false,
  });

  MessageThreadState copyWith({
    MessageThreadStatus? status,
    List<Message>? messages,
    String? conversationId,
    String? errorMessage,
    String? summary,
    bool? isSummarizing,
  }) {
    return MessageThreadState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: errorMessage,
      summary: summary ?? this.summary,
      isSummarizing: isSummarizing ?? this.isSummarizing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    conversationId,
    errorMessage,
    summary,
    isSummarizing,
  ];
}
