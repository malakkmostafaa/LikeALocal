import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final List<String> participants;
  final String placeId;
  final String placeName;
  final String lastMessage;
  final DateTime? lastMessageTime;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.placeId,
    required this.placeName,
    required this.lastMessage,
    this.lastMessageTime,
  });

  String otherUserId(String myId) =>
      participants.firstWhere((p) => p != myId, orElse: () => '');

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      placeId: map['placeId'] ?? '',
      placeName: map['placeName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
    );
  }
}