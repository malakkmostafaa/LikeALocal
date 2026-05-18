import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_conversation.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: chatProvider.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final convos = snapshot.data ?? [];
          if (convos.isEmpty) {
            return const Center(
              child: Text('No conversations yet.\nChat with a place contributor!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            itemCount: convos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = convos[i];
              return _ConversationTile(convo: c, myId: myId);
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation convo;
  final String myId;

  const _ConversationTile({required this.convo, required this.myId});

  @override
  Widget build(BuildContext context) {
    final otherId = convo.otherUserId(myId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFBE8DF),
        child: const Icon(Icons.person_rounded, color: Color(0xFFE26D45)),
      ),
      title: Text(convo.placeName,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(convo.lastMessage,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: convo.lastMessageTime != null
          ? Text(
              _formatTime(convo.lastMessageTime!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            chatId: convo.id,
            otherUserId: otherId,
            placeName: convo.placeName,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day}/${t.month}';
  }
}