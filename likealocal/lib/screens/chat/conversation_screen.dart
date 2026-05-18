import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String placeName;
  final String? otherUserName;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.placeName,
    this.otherUserName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final UserService _userService = UserService();

  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  AppUser? _otherUser;
  bool _isLoadingUser = true;

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFBE8DF);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    try {
      final user = await _userService.getUserById(widget.otherUserId);

      if (!mounted) return;

      setState(() {
        _otherUser = user;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  String get _displayName {
    final passedName = widget.otherUserName?.trim();

    if (passedName != null && passedName.isNotEmpty) {
      return passedName;
    }

    final loadedName = _otherUser?.name.trim();

    if (loadedName != null && loadedName.isNotEmpty) {
      return loadedName;
    }

    return 'Place contributor';
  }

  String get _profileImageUrl {
    return _otherUser?.profileImageUrl ?? '';
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
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      _controller.text = text;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Message not sent',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        titleSpacing: 0,
        title: _ConversationHeader(
          name: _displayName,
          placeName: widget.placeName,
          imageUrl: _profileImageUrl,
          isLoadingUser: _isLoadingUser,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'availability') {
                _showAvailabilityInfo(context);
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'availability',
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                      SizedBox(width: 10),
                      Text('View availability'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _PlaceContextBanner(placeName: widget.placeName),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: context.read<ChatProvider>().getMessages(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (messages.isEmpty) {
                  return const _EmptyConversationState();
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _myId;

                    return _MessageBubble(
                      text: msg.text,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _MessageInputBar(
            controller: _controller,
            onSend: _send,
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
      message = '$_displayName has disabled chat.';
    } else if (startHour != null && endHour != null) {
      message =
          '$_displayName is available between ${_formatHour(startHour)} and ${_formatHour(endHour)}.';
    } else {
      message = '$_displayName is available anytime.';
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Chat availability',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$h $period';
  }
}

class _ConversationHeader extends StatelessWidget {
  final String name;
  final String placeName;
  final String imageUrl;
  final bool isLoadingUser;

  const _ConversationHeader({
    required this.name,
    required this.placeName,
    required this.imageUrl,
    required this.isLoadingUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallUserAvatar(
          imageUrl: imageUrl,
          isLoading: isLoadingUser,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ConversationScreenState.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 13,
                    color: _ConversationScreenState.primaryColor,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'About $placeName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ConversationScreenState.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallUserAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isLoading;

  const _SmallUserAvatar({
    required this.imageUrl,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircleAvatar(
        radius: 19,
        backgroundColor: _ConversationScreenState.softPrimary,
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _ConversationScreenState.primaryColor,
          ),
        ),
      );
    }

    if (imageUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 19,
        backgroundColor: _ConversationScreenState.softPrimary,
        child: Icon(
          Icons.person_rounded,
          color: _ConversationScreenState.primaryColor,
          size: 21,
        ),
      );
    }

    return CircleAvatar(
      radius: 19,
      backgroundColor: _ConversationScreenState.softPrimary,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
    );
  }
}

class _PlaceContextBanner extends StatelessWidget {
  final String placeName;

  const _PlaceContextBanner({
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _ConversationScreenState.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ConversationScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ConversationScreenState.softPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: _ConversationScreenState.primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Place:',
                  style: TextStyle(
                    color: _ConversationScreenState.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ConversationScreenState.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMe ? _ConversationScreenState.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(color: _ConversationScreenState.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : _ConversationScreenState.textColor,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: _ConversationScreenState.cardColor,
        border: Border(
          top: BorderSide(color: _ConversationScreenState.borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask about this place...',
                  hintStyle: const TextStyle(
                    color: _ConversationScreenState.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF0EEE9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _ConversationScreenState.primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
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

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'No messages yet.\nAsk something about this place!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ConversationScreenState.mutedText,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
