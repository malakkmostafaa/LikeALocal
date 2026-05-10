import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // Generate a consistent chatId for two users
  String _chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Check if receiver allows chats
  Future<bool> canChat(String receiverUid) async {
    // Allow test user for development
    if (receiverUid == 'test_user_123') return true;

    final doc = await _firestore.collection('users').doc(receiverUid).get();
    final data = doc.data();
    if (data == null) return true;
    return data['chatEnabled'] ?? true; // ← matches settings screen
  }

  // Open or create a chat between current user and another user
  Future<String> getOrCreateChat({
    required String otherUid,
    required String placeId,
    required String placeName,
  }) async {
    final chatId = _chatId(currentUid, otherUid);
    final ref = _firestore.collection('chats').doc(chatId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'participants': [currentUid, otherUid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'placeId': placeId,
        'placeName': placeName,
      });
    }
    return chatId;
  }

  // Send a message
  Future<void> sendMessage(
      String chatId, String text, String receiverUid) async {
    final messagesRef =
        _firestore.collection('chats').doc(chatId).collection('messages');

    await messagesRef.add({
      'senderId': currentUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Send notification to receiver (skip for test user)
    if (receiverUid != 'test_user_123') {
      final senderDoc =
          await _firestore.collection('users').doc(currentUid).get();
      final senderName = senderDoc.data()?['name'] ?? 'Someone';
      await NotificationService().sendNotification(
        toUid: receiverUid,
        title: 'New message from $senderName',
        body: text,
        type: 'message',
      );
    }
  }

  // Stream messages for a chat (real-time)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  // Stream all chats for current user
  Stream<List<ChatModel>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromDoc).toList());
  }

  // Get other participant's name
  Future<String> getOtherUserName(String otherUid) async {
    // Handle test user
    if (otherUid == 'test_user_123') return 'Test User';

    final doc = await _firestore.collection('users').doc(otherUid).get();
    final data = doc.data();
    return data?['name'] ?? 'User';
  }
}
