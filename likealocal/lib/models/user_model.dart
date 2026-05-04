class AppUser {
  final String uid;
  final String name;
  final String email;
  final List<String> preferences;
  final int pinsCount;
  final bool isSuperUser;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.preferences,
    required this.pinsCount,
    required this.isSuperUser,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      preferences: List<String>.from(map['preferences'] ?? []),
      pinsCount: map['pinsCount'] ?? 0,
      isSuperUser: map['isSuperUser'] ?? false,
    );
  }
}
