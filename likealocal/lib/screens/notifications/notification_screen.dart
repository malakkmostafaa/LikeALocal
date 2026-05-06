import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_rounded;
      case 'nearby': return Icons.location_on_rounded;
      case 'badge': return Icons.star_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'message': return const Color(0xFFD85A30);
      case 'nearby': return Colors.teal;
      case 'badge': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => NotificationService()
                .simulateNearbyNotification('Café Riche'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: service.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No notifications yet.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final notifs = snapshot.data!;
          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, i) {
              final notif = notifs[i];
              return ListTile(
                onTap: () => service.markAsRead(notif.id),
                tileColor: notif.read ? Colors.white : const Color(0xFFFAECE7),
                leading: CircleAvatar(
                  backgroundColor:
                      _colorForType(notif.type).withOpacity(0.15),
                  child: Icon(_iconForType(notif.type),
                      color: _colorForType(notif.type), size: 20),
                ),
                title: Text(notif.title,
                    style: TextStyle(
                        fontWeight: notif.read
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontSize: 14)),
                subtitle: Text(notif.body,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
                trailing: Text(
                  DateFormat('h:mm a').format(notif.timestamp),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}