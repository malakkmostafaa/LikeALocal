import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _primary = Color(0xFFE26D45);
  static const _bg = Color(0xFFF7EFE8);
  static const _card = Color(0xFFFFFBF7);
  static const _border = Color(0xFFEEDDD2);
  static const _soft = Color(0xFFFFE6D8);

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'badge':
        return Icons.military_tech_rounded;
      case 'place':
      case 'reminder':
        return Icons.place_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () => provider.markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: provider.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifs = snapshot.data ?? [];

          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _soft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        size: 40, color: _primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No notifications yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 6),
                  const Text("You're all caught up!",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = notifs[i];
              return GestureDetector(
                onTap: () => provider.markRead(n.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: n.read ? _card : const Color(0xFFFFF3EC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: n.read ? _border : _primary.withOpacity(0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.read ? _soft : _primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForType(n.type),
                          color: _primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.read
                                    ? FontWeight.w600
                                    : FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.body,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeAgo(n.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          if (!n.read) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}