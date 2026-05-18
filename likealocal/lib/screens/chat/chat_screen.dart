import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          'chat.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              if (chat.messages.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'chat.new_chat'.tr(),
                onPressed: chat.clear,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.messages.isEmpty) {
                  return const _EmptyState();
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chat.messages.length) {
                      return const _TypingBubble();
                    }
                    final msg = chat.messages[index];
                    return _MessageBubble(
                      text: msg.text,
                      isUser: msg.role == ChatRole.user,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _ChatScreenState.softPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: _ChatScreenState.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'chat.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _ChatScreenState.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'chat.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ChatScreenState.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? _ChatScreenState.primaryColor : Colors.white;
    final fg = isUser ? Colors.white : _ChatScreenState.textColor;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 20),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SelectableText(
          text,
          style: TextStyle(color: fg, height: 1.4),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 24,
          height: 16,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _ChatScreenState.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<ChatProvider>().isSending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: _ChatScreenState.bgColor,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'chat.hint'.tr(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _ChatScreenState.primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isSending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
