import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String placeName;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.placeName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    try {
      await context.read<ChatProvider>().sendMessage(
            chatId: widget.chatId,
            text: text,
            receiverId: widget.otherUserId,
          );

      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    } catch (e) {
      // Restore the text so they don't lose it
      _controller.text = text;
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Message not sent',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFFE26D45))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE26D45);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contributor',
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(widget.placeName,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'availability') {
                _showAvailabilityInfo(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'availability',
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 18, color: Color(0xFFE26D45)),
                    SizedBox(width: 10),
                    Text('View availability'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream:
                  context.read<ChatProvider>().getMessages(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _myId;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: isMe ? primary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6)
                          ],
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvailabilityInfo(BuildContext context) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();

    if (!context.mounted) return;

    if (!doc.exists || doc.data() == null) return;

    final data = doc.data()!;
    final chatEnabled = data['chatEnabled'] ?? true;
    final startHour = data['chatStartHour'] as int?;
    final endHour = data['chatEndHour'] as int?;

    String message;
    if (!chatEnabled) {
      message = 'This contributor has disabled chat.';
    } else if (startHour != null && endHour != null) {
      message =
          'Available between ${_formatHour(startHour)} and ${_formatHour(endHour)}.';
    } else {
      message = 'This contributor is available anytime.';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contributor availability',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFE26D45))),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h $period';
  }
}