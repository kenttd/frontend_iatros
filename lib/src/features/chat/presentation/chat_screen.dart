import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/chat_repository.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(chatRepository: ChatRepository()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Medical Assistant'),
        suffixes: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FButton(
              // style: FButtonStyle.ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state.status == ChatStatus.success ||
                    state.status == ChatStatus.loading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
                if (state.status == ChatStatus.failure) {
                  // Show error toast or snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage ?? 'Error')),
                  );
                }
              },
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Ask me anything about your medications!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length +
                      (state.status == ChatStatus.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final message = state.messages[index];
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? Colors.blue
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: message.isUser
                            ? Text(
                                message.text,
                                style: const TextStyle(color: Colors.white),
                              )
                            : MarkdownBody(
                                data: message.text,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(color: Colors.black),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  em: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Colors.grey.shade300,
                                    fontFamily: 'monospace',
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: FTextField(
                    controller: _textController,
                    hint: 'Type a message...',
                    maxLines: 1,
                    onChange: (value) {},
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return FButton(
                      onPress: state.status == ChatStatus.loading
                          ? null
                          : () {
                              if (_textController.text.trim().isNotEmpty) {
                                context.read<ChatBloc>().add(
                                      ChatMessageSent(_textController.text),
                                    );
                                _textController.clear();
                              }
                            },
                      child: const Text('Send'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
