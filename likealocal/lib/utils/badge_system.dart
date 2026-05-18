import '../../models/user_model.dart';

class UserBadge {
  final String id;
  final String emoji;
  final bool isEarned;

  UserBadge({
    required this.id,
    required this.emoji,
    required this.isEarned,
  });
}

class BadgeSystem {
  static List<UserBadge> evaluateBadges(AppUser user) {
    return [
      UserBadge(
        id: 'verified_explorer',
        emoji: '🧭',
        isEarned: user.placesAdded >= 10,
      ),
      UserBadge(
        id: 'local_legend',
        emoji: '👑',
        isEarned: user.isSuperUser ||
            (user.placesAdded >= 50 && user.reviewsCount >= 100),
      ),
      UserBadge(
        id: 'foodie_master',
        emoji: '🍜',
        isEarned: user.preferences.contains('Food') && user.reviewsCount >= 5,
      ),
      UserBadge(
        id: 'night_owl',
        emoji: '🦉',
        isEarned:
            user.preferences.contains('Nightlife') && user.reviewsCount >= 5,
      ),
      UserBadge(
        id: 'art_lover',
        emoji: '🎨',
        isEarned: user.preferences.contains('Art') && user.reviewsCount >= 5,
      ),
      UserBadge(
        id: 'nature_guide',
        emoji: '🌿',
        isEarned: user.preferences.contains('Nature') && user.reviewsCount >= 5,
      ),
    ];
  }

  static double calculateSuperUserProgress(AppUser user) {
    double placesProgress = (user.placesAdded / 50).clamp(0.0, 1.0);
    double reviewsProgress = (user.reviewsCount / 100).clamp(0.0, 1.0);

    return (placesProgress + reviewsProgress) / 2.0;
  }

  static bool checkAndDetermineSuperUser(AppUser user) {
    return user.placesAdded >= 50 && user.reviewsCount >= 100;
  }
}
