import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/messaging_repository.dart';
import '../models/conversation.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final MessagingRepository _repository;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;

  ConversationsBloc({MessagingRepository? repository})
    : _repository = repository ?? MessagingRepository(),
      super(const ConversationsState()) {
    on<LoadConversations>(_onLoadConversations);
    on<ConversationsUpdated>(_onConversationsUpdated);
    on<LoadDoctors>(_onLoadDoctors);
    on<StartNewConversation>(_onStartNewConversation);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(state.copyWith(status: ConversationsStatus.loading));

    try {
      // Start listening to real-time updates
      _conversationsSubscription?.cancel();
      _conversationsSubscription = _repository.streamConversations().listen(
        (conversations) {
          add(ConversationsUpdated(conversations));
        },
        onError: (error) {
          emit(
            state.copyWith(
              status: ConversationsStatus.error,
              errorMessage: error.toString(),
            ),
          );
        },
      );

      // Also do an initial fetch from the API
      final conversations = await _repository.getConversations();
      emit(
        state.copyWith(
          status: ConversationsStatus.loaded,
          conversations: conversations,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ConversationsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onConversationsUpdated(
    ConversationsUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    emit(
      state.copyWith(
        status: ConversationsStatus.loaded,
        conversations: event.conversations,
      ),
    );
  }

  Future<void> _onLoadDoctors(
    LoadDoctors event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final doctors = await _repository.getDoctors();
      emit(state.copyWith(doctors: doctors));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to load doctors: $e'));
    }
  }

  Future<void> _onStartNewConversation(
    StartNewConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final conversation = await _repository.createConversation(event.doctorId);
      emit(state.copyWith(newlyCreatedConversation: conversation));
    } catch (e) {
      emit(
        state.copyWith(
          status: ConversationsStatus.error,
          errorMessage: 'Failed to start conversation: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}
