import 'package:equatable/equatable.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});

  @override
  List<Object> get props => [text, isUser];
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}
