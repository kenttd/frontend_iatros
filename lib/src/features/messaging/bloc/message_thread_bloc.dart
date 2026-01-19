import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/messaging_repository.dart';
import '../models/message.dart';
import 'message_thread_event.dart';
import 'message_thread_state.dart';

class MessageThreadBloc extends Bloc<MessageThreadEvent, MessageThreadState> {
  final MessagingRepository _repository;
  StreamSubscription<List<Message>>? _messagesSubscription;

  MessageThreadBloc({MessagingRepository? repository})
    : _repository = repository ?? MessagingRepository(),
      super(const MessageThreadState()) {
    on<LoadMessages>(_onLoadMessages);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SendMessage>(_onSendMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<SummarizeConversation>(_onSummarizeConversation);
  }

  Future<void> _onSummarizeConversation(
    SummarizeConversation event,
    Emitter<MessageThreadState> emit,
  ) async {
    if (state.conversationId == null) return;

    emit(state.copyWith(isSummarizing: true));

    try {
      final summary = await _repository.getChatSummary(state.conversationId!);
      emit(state.copyWith(isSummarizing: false, summary: summary));
    } catch (e) {
      emit(
        state.copyWith(
          isSummarizing: false,
          errorMessage: 'Failed to generate summary: $e',
        ),
      );
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageThreadState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MessageThreadStatus.loading,
        conversationId: event.conversationId,
      ),
    );

    try {
      // Start listening to real-time message updates
      _messagesSubscription?.cancel();
      _messagesSubscription = _repository
          .streamMessages(event.conversationId)
          .listen(
            (messages) {
              add(MessagesUpdated(messages));
            },
            onError: (error) {
              emit(
                state.copyWith(
                  status: MessageThreadStatus.error,
                  errorMessage: error.toString(),
                ),
              );
            },
          );

      // Also do an initial fetch from the API
      final messages = await _repository.getMessages(event.conversationId);
      emit(
        state.copyWith(status: MessageThreadStatus.loaded, messages: messages),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MessageThreadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<MessageThreadState> emit,
  ) {
    emit(
      state.copyWith(
        status: MessageThreadStatus.loaded,
        messages: event.messages,
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageThreadState> emit,
  ) async {
    if (state.conversationId == null) return;

    emit(state.copyWith(status: MessageThreadStatus.sending));

    try {
      await _repository.sendMessage(state.conversationId!, event.text);
      // The real-time stream will automatically update with the new message
      emit(state.copyWith(status: MessageThreadStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: MessageThreadStatus.error,
          errorMessage: 'Failed to send message: $e',
        ),
      );
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<MessageThreadState> emit,
  ) async {
    if (state.conversationId == null) return;

    try {
      await _repository.deleteMessage(state.conversationId!, event.messageId);
      // The real-time stream will automatically update with the message removed
    } catch (e) {
      emit(
        state.copyWith(
          status: MessageThreadStatus.error,
          errorMessage: 'Failed to delete message: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
