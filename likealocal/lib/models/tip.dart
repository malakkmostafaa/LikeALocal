import 'package:cloud_firestore/cloud_firestore.dart';

class Tip {
  final String text;
  final String? authorId;
  final DateTime? createdAt;

  Tip({
    required this.text,
    this.authorId,
    this.createdAt,
  });

  factory Tip.fromMap(Map<String, dynamic> map) {
    return Tip(
      text: map['text'] ?? '',
      authorId: map['authorId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (authorId != null) 'authorId': authorId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
