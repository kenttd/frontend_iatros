import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../bloc/message_thread_bloc.dart';
import '../bloc/message_thread_event.dart';
import '../bloc/message_thread_state.dart';
import '../models/message.dart';

class MessageThreadScreen extends StatelessWidget {
  final String conversationId;
  final String? participantName;

  const MessageThreadScreen({
    super.key,
    required this.conversationId,
    this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MessageThreadBloc()..add(LoadMessages(conversationId)),
      child: _MessageThreadView(participantName: participantName ?? 'Chat'),
    );
  }
}

class _MessageThreadView extends StatefulWidget {
  final String participantName;

  const _MessageThreadView({required this.participantName});

  @override
  State<_MessageThreadView> createState() => _MessageThreadViewState();
}

class _MessageThreadViewState extends State<_MessageThreadView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FScaffold(
      header: FHeader(
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
            Text(widget.participantName),
            const Spacer(),
            BlocBuilder<MessageThreadBloc, MessageThreadState>(
              builder: (context, state) {
                if (state.isSummarizing) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  onPressed: () {
                    context.read<MessageThreadBloc>().add(
                      const SummarizeConversation(),
                    );
                  },
                  icon: const Icon(Icons.summarize_outlined),
                  tooltip: 'Summarize Conversation',
                );
              },
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<MessageThreadBloc, MessageThreadState>(
                  listenWhen: (previous, current) =>
                      previous.summary != current.summary &&
                      current.summary != null,
                  listener: (context, state) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24.0),
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              MarkdownBody(
                                data: state.summary!,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 16, height: 1.5),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  blockSpacing: 12.0,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                BlocListener<MessageThreadBloc, MessageThreadState>(
                  listenWhen: (previous, current) =>
                      previous.errorMessage != current.errorMessage &&
                      current.errorMessage != null,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage!)),
                    );
                  },
                ),
                BlocListener<MessageThreadBloc, MessageThreadState>(
                  listenWhen: (previous, current) =>
                      previous.status != current.status &&
                      current.status == MessageThreadStatus.loaded,
                  listener: (context, state) {
                    _scrollToBottom();
                  },
                ),
              ],
              child: BlocBuilder<MessageThreadBloc, MessageThreadState>(
                builder: (context, state) {
                  if (state.status == MessageThreadStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a message to start the conversation',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId == currentUserId;

                      return _MessageBubble(message: message, isMe: isMe);
                    },
                  );
                },
              ),
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FTextField(
                controller: _textController,
                focusNode: _focusNode,
                hint: 'Type a message...',
                maxLines: 4,
                onChange: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<MessageThreadBloc, MessageThreadState>(
              builder: (context, state) {
                final isSending = state.status == MessageThreadStatus.sending;

                return FButton(
                  onPress: isSending || _textController.text.trim().isEmpty
                      ? null
                      : () {
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            context.read<MessageThreadBloc>().add(
                              SendMessage(text),
                            );
                            _textController.clear();
                            _focusNode.requestFocus();
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (isMe) {
          final messageThreadBloc = context.read<MessageThreadBloc>();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Message'),
              content: const Text(
                'Are you sure you want to delete this message? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    messageThreadBloc.add(DeleteMessage(message.id));
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.medical_services,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (message.translatedText != null) ...[
                      const SizedBox(height: 8),
                      Divider(
                        color: isMe ? Colors.white24 : Colors.grey.shade300,
                        height: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Translated:',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      Text(
                        message.translatedText!,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }
}
