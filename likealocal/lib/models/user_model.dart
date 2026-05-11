class AppUser {
  final String uid;
  final String name;
  final String email;
  final List<String> preferences;
  final int pinsCount;
  final int placesAdded;
  final int reviewsCount;
  final bool isSuperUser;
  final double maxDistance;
  final int priceRange;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.preferences,
    required this.pinsCount,
    required this.placesAdded,
    required this.reviewsCount,
    required this.isSuperUser,
    required this.maxDistance,
    required this.priceRange,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      preferences: List<String>.from(map['preferences'] ?? []),
      pinsCount: map['pinsCount'] ?? 0,
      placesAdded: map['placesAdded'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      isSuperUser: map['isSuperUser'] ?? false,
      maxDistance: (map['maxDistance'] ?? 10.0).toDouble(),
      priceRange: map['priceRange'] ?? 1,
    );
  }

Map<String, dynamic> toMap() {
  return {
    'uid': uid,
    'name': name,
    'email': email,
    'preferences': preferences,
    'pinsCount': pinsCount,
    'placesAdded': placesAdded,
    'reviewsCount': reviewsCount,
    'isSuperUser': isSuperUser,
  };
}
}
