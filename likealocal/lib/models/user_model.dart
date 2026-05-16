import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;

  final List<String> preferences;
  final double maxDistance;
  final int priceRange;

  final int pinsCount;
  final int placesAdded;
  final int reviewsCount;

  final bool isSuperUser;
  final bool isPremium;

  final bool chatEnabled;
  final bool notificationsEnabled;

  final List<String> badges;

  final String profileImageUrl;
  final String bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int? chatStartHour;   
  final int? chatEndHour;     

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.preferences,
    required this.maxDistance,
    required this.priceRange,
    required this.pinsCount,
    required this.placesAdded,
    required this.reviewsCount,
    required this.isSuperUser,
    required this.isPremium,
    required this.chatEnabled,
    required this.notificationsEnabled,
    required this.badges,
    required this.profileImageUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
    required this.chatStartHour,
    required this.chatEndHour,
  });

  factory AppUser.empty({
    required String uid,
    required String email,
    String name = '',
  }) {
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      preferences: const [],
      maxDistance: 10.0,
      priceRange: 1,
      pinsCount: 0,
      placesAdded: 0,
      reviewsCount: 0,
      isSuperUser: false,
      isPremium: false,
      chatEnabled: true,
      notificationsEnabled: true,
      badges: const [],
      profileImageUrl: '',
      bio: '',
      createdAt: null,
      updatedAt: null,
      chatStartHour: null,
      chatEndHour: null,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      preferences: List<String>.from(map['preferences'] ?? []),
      maxDistance: ((map['maxDistance'] ?? 10.0) as num).toDouble(),
      priceRange: map['priceRange'] ?? 1,
      pinsCount: map['pinsCount'] ?? 0,
      placesAdded: map['placesAdded'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      isSuperUser: map['isSuperUser'] ?? false,
      isPremium: map['isPremium'] ?? false,
      chatEnabled: map['chatEnabled'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      badges: List<String>.from(map['badges'] ?? []),
      profileImageUrl: map['profileImageUrl'] ?? '',
      bio: map['bio'] ?? '',
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      chatStartHour: map['chatStartHour'] as int?,
      chatEndHour: map['chatEndHour'] as int?,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'preferences': preferences,
      'maxDistance': maxDistance,
      'priceRange': priceRange,
      'pinsCount': pinsCount,
      'placesAdded': placesAdded,
      'reviewsCount': reviewsCount,
      'isSuperUser': isSuperUser,
      'isPremium': isPremium,
      'chatEnabled': chatEnabled,
      'notificationsEnabled': notificationsEnabled,
      'badges': badges,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'chatStartHour': chatStartHour,
      'chatEndHour': chatEndHour,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'preferences': preferences,
      'maxDistance': maxDistance,
      'priceRange': priceRange,
      'pinsCount': pinsCount,
      'placesAdded': placesAdded,
      'reviewsCount': reviewsCount,
      'isSuperUser': isSuperUser,
      'isPremium': isPremium,
      'chatEnabled': chatEnabled,
      'notificationsEnabled': notificationsEnabled,
      'badges': badges,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'chatStartHour': chatStartHour,
      'chatEndHour': chatEndHour,
    };
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'preferences': preferences,
      'maxDistance': maxDistance,
      'priceRange': priceRange,
      'pinsCount': pinsCount,
      'placesAdded': placesAdded,
      'reviewsCount': reviewsCount,
      'isSuperUser': isSuperUser,
      'isPremium': isPremium,
      'chatEnabled': chatEnabled,
      'notificationsEnabled': notificationsEnabled,
      'badges': badges,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'chatStartHour': chatStartHour,
      'chatEndHour': chatEndHour,
    };
  }

  bool get isChatAvailableNow {
    if (!chatEnabled) return false;
    if (chatStartHour == null || chatEndHour == null) return true; // no restriction
    final hour = DateTime.now().hour;
    if (chatStartHour! <= chatEndHour!) {
      return hour >= chatStartHour! && hour < chatEndHour!;
    } else {
      // overnight e.g. 10 PM – 2 AM
      return hour >= chatStartHour! || hour < chatEndHour!;
    }
  }
}
