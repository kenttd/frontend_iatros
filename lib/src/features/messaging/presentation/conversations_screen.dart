import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';
import '../models/conversation.dart';
import 'doctor_selection_bottom_sheet.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationsBloc()..add(const LoadConversations()),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: BlocConsumer<ConversationsBloc, ConversationsState>(
        listener: (context, state) {
          // Navigate to new conversation when created
          if (state.newlyCreatedConversation != null) {
            context.push('/messaging/${state.newlyCreatedConversation!.id}');
          }

          // Show error messages
          if (state.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            });
          }
        },
        builder: (context, state) {
          return FScaffold(
            header: FHeader(
              title: const Text('Messages'),
              suffixes: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FButton(
                    onPress: () {
                      _showDoctorSelection(context);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            child: _buildBody(context, state, currentUserId),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ConversationsState state,
    String currentUserId,
  ) {
    if (state.status == ConversationsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ConversationsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load conversations',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () {
                context.read<ConversationsBloc>().add(
                  const LoadConversations(),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with a doctor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: () {
                _showDoctorSelection(context);
              },
              child: const Text('Find a Doctor'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.conversations.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        return _ConversationTile(
          conversation: conversation,
          currentUserId: currentUserId,
          onTap: () {
            context.push('/messaging/${conversation.id}');
          },
        );
      },
    );
  }

  void _showDoctorSelection(BuildContext context) {
    context.read<ConversationsBloc>().add(const LoadDoctors());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: context.read<ConversationsBloc>(),
          child: const DoctorSelectionBottomSheet(),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipantName = conversation.getOtherParticipantName(
      currentUserId,
    );
    final otherParticipantRole = conversation.getOtherParticipantRole(
      currentUserId,
    );
    final isDoctor = otherParticipantRole == 'DOCTOR';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isDoctor ? Colors.blue.shade100 : Colors.grey.shade200,
        child: Icon(
          isDoctor ? Icons.medical_services : Icons.person,
          color: isDoctor ? Colors.blue : Colors.grey,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherParticipantName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDoctor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Doctor',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(dateTime);
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }
}
