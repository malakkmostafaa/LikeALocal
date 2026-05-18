import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/badge_system.dart';
import '../../services/user_service.dart';

class SuperUserScreen extends StatefulWidget {
  final AppUser user;

  const SuperUserScreen({super.key, required this.user});

  @override
  State<SuperUserScreen> createState() => _SuperUserScreenState();
}

class _SuperUserScreenState extends State<SuperUserScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkSuperUserStatus();
  }

  Future<void> _checkSuperUserStatus() async {
    final bool shouldBeSuperUser =
        BadgeSystem.checkAndDetermineSuperUser(widget.user);
    if (shouldBeSuperUser && !widget.user.isSuperUser) {
      // Auto upgrade user to Super User
      await _userService.updateCurrentUser({
        'isSuperUser': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);
    const backgroundColor = Color(0xFFF8F6F3);

    final progress = BadgeSystem.calculateSuperUserProgress(widget.user);
    final badges = BadgeSystem.evaluateBadges(widget.user);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          'super_user.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================
            // HERO CARD
            // ========================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEBE1), // Light sandy orange
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium,
                            color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'super_user.progress_title'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'super_user.percent_complete'.tr(namedArgs: {'percent': '${(progress * 100).toInt()}'}),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white,
                      color: primaryColor,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ========================
            // PROGRESS TRACKER
            // ========================
            Text(
              'super_user.progress_tracker'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildTrackerRow(
              icon: Icons.place_outlined,
              label: 'super_user.places_added'.tr(),
              current: widget.user.placesAdded,
              target: 50,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            _buildTrackerRow(
              icon: Icons.star_outline,
              label: 'super_user.reviews_written'.tr(),
              current: widget.user.reviewsCount,
              target: 100,
              color: primaryColor,
            ),
            // const SizedBox(height: 20),
            // _buildTrackerRow(
            //   icon: Icons.bookmark_border,
            //   label: "Pins Created",
            //   current: widget.user.pinsCount,
            //   target: 30,
            //   color: primaryColor,
            // ),

            const SizedBox(height: 36),

            // ========================
            // EARNED BADGES
            // ========================
            Text(
              'super_user.earned_badges'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(badge, primaryColor);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerRow({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required Color color,
  }) {
    final double progress = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              "${current > target ? target : current}/$target",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(UserBadge badge, Color primaryColor) {
    if (!badge.isEarned) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.3,
              child: Text(
                badge.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'badge.${badge.id}'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'badge.${badge.id}'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87, // Slightly darker for earned
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'super_user.earned'.tr(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
