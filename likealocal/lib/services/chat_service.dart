import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import 'fcm_service.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // Get or create a chat between current user and another user about a place
  Future<String> getOrCreateChat({
    required String otherUserId,
    required String placeId,
    required String placeName,
  }) async {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    // Sort so the chatId is always the same regardless of who initiates
    final sorted = [myId, otherUserId]..sort();
    final chatId = '${sorted[0]}_${sorted[1]}_$placeId';

    final ref = _db.collection('chats').doc(chatId);

    try {
      final snap = await ref.get();

      if (!snap.exists) {
        // Use set with merge:false so the rule sees all fields atomically
        await ref.set({
          'participants': sorted, // ← must match sorted order
          'placeId': placeId,
          'placeName': placeName,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // If permission denied even on read (chat doesn't exist yet),
      // try creating directly
      if (e.toString().contains('permission-denied')) {
        await ref.set({
          'participants': sorted,
          'placeId': placeId,
          'placeName': placeName,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        rethrow;
      }
    }

    return chatId;
  }

  Stream<List<ChatConversation>> getMyConversations() {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    if (myId == null) return const Stream.empty();

    return _db
        .collection('chats')
        .where('participants', arrayContains: myId)
        .snapshots()
        .handleError((e) {
      // Log but don't crash — index may still be building
      debugPrint('Chat stream error: $e');
    }).map((s) {
      final convos =
          s.docs.map((d) => ChatConversation.fromMap(d.data(), d.id)).toList();
      // Sort client-side while index builds
      convos.sort((a, b) {
        final aTime =
            a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return convos;
    });
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String receiverId,
  }) async {
    final myId = FirebaseAuth.instance.currentUser!.uid;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Check receiver's chat availability
    final receiverDoc = await _db.collection('users').doc(receiverId).get();
    final receiverData = receiverDoc.data();
    if (receiverData != null) {
      final chatEnabled = receiverData['chatEnabled'] ?? true;
      if (!chatEnabled) {
        throw Exception('This user has disabled chat.');
      }
      final startHour = receiverData['chatStartHour'] as int?;
      final endHour = receiverData['chatEndHour'] as int?;
      if (startHour != null && endHour != null) {
        final hour = DateTime.now().hour;
        bool available;
        if (startHour <= endHour) {
          available = hour >= startHour && hour < endHour;
        } else {
          available = hour >= startHour || hour < endHour;
        }
        if (!available) {
          final startLabel = _formatHour(startHour);
          final endLabel = _formatHour(endHour);
          throw Exception(
              'This user only accepts messages between $startLabel and $endLabel.');
        }
      }
    }

    final batch = _db.batch();

    final msgRef =
        _db.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': myId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _db.collection('notifications').add({
      'userId': receiverId,
      'title': 'New message',
      'body': trimmed.length > 60 ? '${trimmed.substring(0, 60)}…' : trimmed,
      'type': 'message',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FcmService.sendToUser(
      recipientUid: receiverId,
      title: 'New message',
      body: trimmed.length > 60 ? '${trimmed.substring(0, 60)}…' : trimmed,
      data: {'type': 'message', 'chatId': chatId},
    );
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }
}
