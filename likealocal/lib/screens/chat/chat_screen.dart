import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_conversation.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFBE8DF);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const _MessagesHeader(),
            Expanded(
              child: StreamBuilder<List<ChatConversation>>(
                stream: chatProvider.getConversations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  final convos = snapshot.data ?? [];

                  if (convos.isEmpty) {
                    return const _EmptyMessagesState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                    itemCount: convos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final convo = convos[i];

                      return _ConversationTile(
                        convo: convo,
                        myId: myId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEDEBE6),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: ChatScreen.textColor,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Messages',
            style: TextStyle(
              color: ChatScreen.textColor,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation convo;
  final String myId;

  const _ConversationTile({
    required this.convo,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = convo.otherUserId(myId);

    return FutureBuilder<AppUser?>(
      future: UserService().getUserById(otherId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        final otherName = otherUser?.name.trim().isNotEmpty == true
            ? otherUser!.name.trim()
            : 'Place contributor';

        final profileImageUrl = otherUser?.profileImageUrl ?? '';

        return Material(
          color: ChatScreen.cardColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    chatId: convo.id,
                    otherUserId: otherId,
                    placeName: convo.placeName,
                    otherUserName: otherName,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
              decoration: BoxDecoration(
                color: ChatScreen.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ChatAvatar(imageUrl: profileImageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                otherName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ChatScreen.textColor,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (convo.lastMessageTime != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  _formatTime(convo.lastMessageTime!),
                                  style: const TextStyle(
                                    color: ChatScreen.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          convo.lastMessage.trim().isEmpty
                              ? 'Start the conversation'
                              : convo.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ChatScreen.mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: ChatScreen.primaryColor,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                convo.placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ChatScreen.primaryColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Optional mock unread badge look.
                  // Replace this with your actual unread count later.
                  if (_mockUnreadCount(convo) > 0) ...[
                    const SizedBox(width: 8),
                    _UnreadBadge(count: _mockUnreadCount(convo)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _mockUnreadCount(ChatConversation convo) {
    // Temporary UI-only logic.
    // Later replace with convo.unreadCount if your model supports it.
    return 0;
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final difference = now.difference(t);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    return '${t.day}/${t.month}';
  }
}

class _ChatAvatar extends StatelessWidget {
  final String imageUrl;

  const _ChatAvatar({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: ChatScreen.softPrimary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: ChatScreen.primaryColor,
          size: 27,
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: ChatScreen.softPrimary,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: ChatScreen.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: ChatScreen.softPrimary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: ChatScreen.primaryColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No conversations yet',
              style: TextStyle(
                color: ChatScreen.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Open a place and tap “Chat with contributor” to start asking about it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChatScreen.mutedText,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
