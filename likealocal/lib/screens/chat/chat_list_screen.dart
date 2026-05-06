import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Messages',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No conversations yet.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final chats = snapshot.data!;
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final otherUid = chat.participants
                  .firstWhere((uid) => uid != currentUid, orElse: () => '');

              return FutureBuilder<String>(
                future: chatService.getOtherUserName(otherUid),
                builder: (context, nameSnapshot) {
                  final name = nameSnapshot.data ?? 'User';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFAECE7),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFFD85A30)),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600)),
                        if (chat.placeName.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 11, color: Color(0xFFD85A30)),
                              const SizedBox(width: 2),
                              Text(chat.placeName,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFD85A30))),
                            ],
                          ),
                      ],
                    ),
                    trailing: Text(
                      DateFormat('h:mm a').format(chat.lastMessageTime),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUid: otherUid,
                          otherName: name,
                          placeId: chat.placeId,
                          placeName: chat.placeName,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}