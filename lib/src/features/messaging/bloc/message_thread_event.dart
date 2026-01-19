import 'package:equatable/equatable.dart';
import '../models/message.dart';

abstract class MessageThreadEvent extends Equatable {
  const MessageThreadEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends MessageThreadEvent {
  final String conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MessagesUpdated extends MessageThreadEvent {
  final List<Message> messages;

  const MessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

class SendMessage extends MessageThreadEvent {
  final String text;

  const SendMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class MessageSent extends MessageThreadEvent {
  final Message message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class SummarizeConversation extends MessageThreadEvent {
  const SummarizeConversation();

  @override
  List<Object?> get props => [];
}

class DeleteMessage extends MessageThreadEvent {
  final String messageId;

  const DeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}
