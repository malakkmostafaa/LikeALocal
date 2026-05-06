class AppUser {
  final String uid;
  final String name;
  final String email;

  // Preferences & Personalization
  final List<String> preferences;
  final double maxDistance;
  final int priceRange;

  // Activity Tracking
  final int pinsCount;
  final int placesAdded;
  final int reviewsCount;

  // User Status
  final bool isSuperUser;
  final bool isPremium;

  // Settings
  final bool chatEnabled;
  final bool notificationsEnabled;

  // Gamification
  final List<String> badges;

  // Profile
  final String profileImageUrl;

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
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      preferences: List<String>.from(map['preferences'] ?? []),
      maxDistance: (map['maxDistance'] ?? 10.0).toDouble(),
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
    );
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
    };
  }
}
