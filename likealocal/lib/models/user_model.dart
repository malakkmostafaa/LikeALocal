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

  // Trivia game
  final int triviaStreak;
  final String lastTriviaDate; // YYYY-MM-DD of last completed daily

  /// Returns triviaStreak only if the streak is still alive (played today or
  /// yesterday). Otherwise returns 0, since the chain has been broken.
  int get activeStreak {
    if (triviaStreak == 0 || lastTriviaDate.isEmpty) return 0;
    // Test mode keys start with 'test-' — skip the date check.
    if (lastTriviaDate.startsWith('test-')) return triviaStreak;
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final today = fmt(now);
    final yesterday = fmt(now.subtract(const Duration(days: 1)));
    return (lastTriviaDate == today || lastTriviaDate == yesterday)
        ? triviaStreak
        : 0;
  }

  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.triviaStreak = 0,
    this.lastTriviaDate = '',
    required this.createdAt,
    required this.updatedAt,
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
      triviaStreak: 0,
      lastTriviaDate: '',
      createdAt: null,
      updatedAt: null,
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
      triviaStreak: (map['triviaStreak'] as num?)?.toInt() ?? 0,
      lastTriviaDate: map['lastTriviaDate']?.toString() ?? '',
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
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
      'triviaStreak': triviaStreak,
      'lastTriviaDate': lastTriviaDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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
      'triviaStreak': triviaStreak,
      'lastTriviaDate': lastTriviaDate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
      'triviaStreak': triviaStreak,
      'lastTriviaDate': lastTriviaDate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
