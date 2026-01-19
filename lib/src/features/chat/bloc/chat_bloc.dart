import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<ChatMessageSent>(_onMessageSent);
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = ChatMessage(text: event.message, isUser: true);
    emit(state.copyWith(
      status: ChatStatus.loading,
      messages: [...state.messages, userMessage],
    ));

    try {
      final response = await _chatRepository.sendMessage(event.message);
      final botMessage = ChatMessage(text: response, isUser: false);
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: [...state.messages, botMessage],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
