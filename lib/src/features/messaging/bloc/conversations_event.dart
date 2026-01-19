import 'package:equatable/equatable.dart';
import '../models/conversation.dart';
import '../models/doctor.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationsEvent {
  const LoadConversations();
}

class ConversationsUpdated extends ConversationsEvent {
  final List<Conversation> conversations;

  const ConversationsUpdated(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class LoadDoctors extends ConversationsEvent {
  const LoadDoctors();
}

class StartNewConversation extends ConversationsEvent {
  final String doctorId;

  const StartNewConversation(this.doctorId);

  @override
  List<Object?> get props => [doctorId];
}

class DoctorsLoaded extends ConversationsEvent {
  final List<Doctor> doctors;

  const DoctorsLoaded(this.doctors);

  @override
  List<Object?> get props => [doctors];
}
