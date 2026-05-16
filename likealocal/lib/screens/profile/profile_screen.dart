import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/providers/connectivity_provider.dart';
import 'package:like_a_local/providers/pin_provider.dart';
import 'package:like_a_local/providers/place_provider.dart';
import 'package:like_a_local/providers/review_provider.dart';

import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../services/place_service.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'super_user_screen.dart';
import 'subscription_plans_screen.dart';
import '../place/place_details_screen.dart';
import '../add_place/add_place_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileActionsPanel extends StatelessWidget {
  final AppUser user;

  const _ProfileActionsPanel({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ProfileScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProfileActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update info',
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ),
                    );
                  },
                ),
              ),
              const _PanelDivider(vertical: true),
              Expanded(
                child: _ProfileActionTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Super User',
                  subtitle: user.isSuperUser ? 'Unlocked' : 'Progress',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuperUserScreen(user: user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const _PanelDivider(),
          Row(
            children: [
              Expanded(
                child: _ProfileActionTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Plans',
                  subtitle: user.isPremium ? 'Premium' : 'Upgrade',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubscriptionPlansScreen(user: user),
                      ),
                    );
                  },
                ),
              ),
              const _PanelDivider(vertical: true),
              Expanded(
                child: _ProfileActionTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Guide',
                  subtitle: 'Coming soon',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Guide coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isPrimary
        ? _ProfileScreenState.primaryColor
        : _ProfileScreenState.softPrimary;

    final iconColor =
        isPrimary ? Colors.white : _ProfileScreenState.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isPrimary
                      ? [
                          BoxShadow(
                            color: _ProfileScreenState.primaryColor
                                .withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileScreenState.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileScreenState.mutedText,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  final bool vertical;

  const _PanelDivider({
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: vertical ? 1 : double.infinity,
      height: vertical ? 62 : 1,
      color: _ProfileScreenState.borderColor.withOpacity(0.8),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  static const Color bgColor = Color(0xFFF7EFE8);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color surfaceColor = Color(0xFFFFF3EC);

  static const Color primaryColor = Color(0xFFE26D45);
  static const Color primaryDark = Color(0xFFB95637);
  static const Color softPrimary = Color(0xFFFFE6D8);

  static const Color borderColor = Color(0xFFEEDDD2);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF7A6D66);

  static const Color goldColor = Color(0xFFE5A11A);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final uid = currentUser.uid;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(includeMetadataChanges: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists ||
                snapshot.data!.data() == null) {
              return const _ProfileLoadingFallback();
            }

            final user = AppUser.fromMap(snapshot.data!.data()!);
            final joinedText = _joinedText(user.createdAt);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _ProfileTopBar(user: user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _ProfileHeaderCard(
                      user: user,
                      joinedText: joinedText,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _StatsRow(user: user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _ProfileActionsPanel(user: user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: _ProfileTabs(
                      selectedIndex: _selectedTab,
                      onChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildSelectedSection(uid),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedSection(String uid) {
    if (_selectedTab == 0) {
      return _MyPlacesSection(
        key: const ValueKey('my_places'),
        uid: uid,
        onOpenPlace: _openPlaceDetails,
        onDeletePlace: _deletePlace,
      );
    }

    if (_selectedTab == 1) {
      return _SavedPinsSection(
        key: const ValueKey('saved_pins'),
        uid: uid,
        onOpenPlace: _openPlaceDetails,
      );
    }

    return _MyReviewsSection(
      key: const ValueKey('my_reviews'),
      uid: uid,
      onEditReview: _editReview,
      onDeleteReview: _deleteReview,
    );
  }

  void _openPlaceDetails(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  Future<void> _deletePlace(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete place?'),
          content: Text(
            'Are you sure you want to delete "${place.name}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await context.read<PlaceProvider>().deletePlace(
        place,
        isOffline: context.read<ConnectivityProvider>().isOffline,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place deleted')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete place: $e')),
      );
    }
  }

  Future<void> _editReview(_ReviewWithPlace review) async {
    final result = await showDialog<_EditedReviewResult>(
      context: context,
      builder: (_) {
        return _EditReviewDialog(review: review);
      },
    );

    if (result == null) return;

    final isOffline = context.read<ConnectivityProvider>().isOffline;

    try {
      await context.read<ReviewProvider>().editReview(
            placeId: review.placeId,
            reviewId: review.reviewId,
            text: result.text,
            rating: result.rating,
            isOffline: isOffline,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _deleteReview(_ReviewWithPlace review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete review?'),
          content: const Text(
            'Are you sure you want to delete this review? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final isOffline = context.read<ConnectivityProvider>().isOffline;

    try {
      await context.read<ReviewProvider>().deleteReview(
            placeId: review.placeId,
            reviewId: review.reviewId,
            isOffline: isOffline,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  static String _joinedText(DateTime? date) {
    if (date == null) return 'Joined recently';
    return 'Joined ${_monthName(date.month)} ${date.year}';
  }

  static String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month];
  }
}

class _ProfileTopBar extends StatelessWidget {
  final AppUser user;

  const _ProfileTopBar({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: _ProfileScreenState.textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
        ),
        Material(
          color: _ProfileScreenState.cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(user: user),
                ),
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ProfileScreenState.borderColor),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: _ProfileScreenState.textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final AppUser user;
  final String joinedText;

  const _ProfileHeaderCard({
    required this.user,
    required this.joinedText,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user.name.trim().isEmpty ? 'Local User' : user.name;
    final bio = user.bio.trim().isEmpty
        ? 'Exploring Cairo one hidden gem at a time'
        : user.bio.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _ProfileScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.028),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _ProfileScreenState.softPrimary,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _ProfileScreenState.surfaceColor,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: _ProfileScreenState.primaryColor,
                        )
                      : null,
                ),
              ),
              if (user.isSuperUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _ProfileScreenState.cardColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: _ProfileScreenState.goldColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileScreenState.textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (user.isSuperUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 13,
                              color: Color(0xFFC88412),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Super User',
                              style: TextStyle(
                                color: Color(0xFFC88412),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfileScreenState.mutedText,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: _ProfileScreenState.primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      joinedText,
                      style: const TextStyle(
                        color: _ProfileScreenState.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppUser user;

  const _StatsRow({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.place_outlined,
          value: user.placesAdded.toString(),
          label: 'Places',
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.star_outline_rounded,
          value: user.reviewsCount.toString(),
          label: 'Reviews',
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.bookmark_border_rounded,
          value: user.pinsCount.toString(),
          label: 'Pins',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _ProfileScreenState.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _ProfileScreenState.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.022),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _ProfileScreenState.softPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: _ProfileScreenState.primaryColor,
                size: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _ProfileScreenState.textColor,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _ProfileScreenState.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCapsule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCapsule({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 165,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [
                      _ProfileScreenState.primaryColor,
                      _ProfileScreenState.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      _ProfileScreenState.cardColor,
                      _ProfileScreenState.surfaceColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isPrimary
                  ? _ProfileScreenState.primaryColor
                  : _ProfileScreenState.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? _ProfileScreenState.primaryColor.withOpacity(0.18)
                    : Colors.black.withOpacity(0.025),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.18)
                      : _ProfileScreenState.softPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? Colors.white
                      : _ProfileScreenState.primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.white
                            : _ProfileScreenState.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.white.withOpacity(0.78)
                            : _ProfileScreenState.mutedText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  final AppUser user;

  const _EditProfileButton({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ProfileScreenState.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(user: user),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _ProfileScreenState.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_outlined,
                color: _ProfileScreenState.primaryColor,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: _ProfileScreenState.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final AppUser user;

  const _ShortcutGrid({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _ProfileScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Super User',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuperUserScreen(user: user),
                      ),
                    );
                  },
                ),
              ),
              const _DividerLine(vertical: true),
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Plans',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubscriptionPlansScreen(user: user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const _DividerLine(),
          Row(
            children: [
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Guide',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Guide coming soon')),
                    );
                  },
                ),
              ),
              const _DividerLine(vertical: true),
              Expanded(
                child: _ShortcutTile(
                  icon: Icons.send_outlined,
                  title: 'Messages',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Messages coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _ProfileScreenState.softPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _ProfileScreenState.primaryColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileScreenState.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfileScreenState.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  final bool vertical;

  const _DividerLine({
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: vertical ? 1 : double.infinity,
      height: vertical ? 58 : 1,
      color: _ProfileScreenState.borderColor,
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ProfileTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Places', 'Pins', 'Reviews'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _ProfileScreenState.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileScreenState.borderColor),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? _ProfileScreenState.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  border: selected
                      ? Border.all(color: _ProfileScreenState.borderColor)
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 9,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? _ProfileScreenState.primaryColor
                        : _ProfileScreenState.textColor.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MyPlacesSection extends StatelessWidget {
  final String uid;
  final ValueChanged<Place> onOpenPlace;
  final ValueChanged<Place> onDeletePlace;

  const _MyPlacesSection({
    super.key,
    required this.uid,
    required this.onOpenPlace,
    required this.onDeletePlace,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('createdBy', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoadingCard();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptySectionCard(
            icon: Icons.place_outlined,
            title: 'No places added yet',
            message: 'Places you share with the community will appear here.',
          );
        }

        final places = docs.map((doc) {
          return Place.fromMap(doc.data(), doc.id);
        }).toList();

        places.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        return Column(
          children: places.map((place) {
            return _ProfilePlaceCard(
              place: place,
              onTap: () => onOpenPlace(place),
              trailing: PopupMenuButton<String>(
                color: _ProfileScreenState.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: (value) {
                  if (value == 'open') {
                    onOpenPlace(place);
                  } else if (value == 'delete') {
                    onDeletePlace(place);
                  } else if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPlaceScreen(placeToEdit: place),
                      ),
                    );
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'open',
                      child: Text('View details'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit place'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete place',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ];
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SavedPinsSection extends StatelessWidget {
  final String uid;
  final ValueChanged<Place> onOpenPlace;

  const _SavedPinsSection({
    super.key,
    required this.uid,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: context.read<PinProvider>().pinnedPlaceIdsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoadingCard();
        }

        final placeIds = snapshot.data ?? <String>[];

        if (placeIds.isEmpty) {
          return const _EmptySectionCard(
            icon: Icons.bookmark_border_rounded,
            title: 'No pinned places yet',
            message: 'Tap the bookmark on any place to save it here.',
          );
        }

        return Column(
          children: placeIds.map((placeId) {
            return _PinnedPlaceTile(
              key: ValueKey('pin_$placeId'),
              placeId: placeId,
              onOpenPlace: onOpenPlace,
            );
          }).toList(),
        );
      },
    );
  }
}

class _PinnedPlaceTile extends StatefulWidget {
  final String placeId;
  final ValueChanged<Place> onOpenPlace;

  const _PinnedPlaceTile({
    super.key,
    required this.placeId,
    required this.onOpenPlace,
  });

  @override
  State<_PinnedPlaceTile> createState() => _PinnedPlaceTileState();
}

class _PinnedPlaceTileState extends State<_PinnedPlaceTile> {
  final PlaceService _placeService = PlaceService();
  late final Future<Place?> _placeFuture =
      _placeService.getPlaceByIdOnce(widget.placeId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Place?>(
      future: _placeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _SectionLoadingCard(),
          );
        }

        final place = snapshot.data;
        if (place == null) return const SizedBox.shrink();

        return _ProfilePlaceCard(
          place: place,
          onTap: () => widget.onOpenPlace(place),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: _ProfileScreenState.mutedText,
          ),
        );
      },
    );
  }
}

class _MyReviewsSection extends StatefulWidget {
  final String uid;
  final ValueChanged<_ReviewWithPlace> onEditReview;
  final ValueChanged<_ReviewWithPlace> onDeleteReview;

  const _MyReviewsSection({
    super.key,
    required this.uid,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  @override
  State<_MyReviewsSection> createState() => _MyReviewsSectionState();
}

class _MyReviewsSectionState extends State<_MyReviewsSection> {
  late Future<List<_ReviewWithPlace>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadMyReviews();
  }

  Future<void> _refresh() async {
    setState(() {
      _reviewsFuture = _loadMyReviews();
    });
  }

  Future<List<_ReviewWithPlace>> _loadMyReviews() async {
    final firestore = FirebaseFirestore.instance;

    final placesSnapshot = await firestore.collection('places').get();

    final List<_ReviewWithPlace> reviews = [];

    for (final placeDoc in placesSnapshot.docs) {
      final placeData = placeDoc.data();

      final placeId = placeDoc.id;
      final placeName = placeData['name']?.toString() ?? 'Unknown place';

      final reviewsSnapshot = await placeDoc.reference
          .collection('reviews')
          .where('userId', isEqualTo: widget.uid)
          .get();

      for (final reviewDoc in reviewsSnapshot.docs) {
        final data = reviewDoc.data();

        reviews.add(
          _ReviewWithPlace(
            reviewId: reviewDoc.id,
            placeId: placeId,
            text: data['text']?.toString() ?? '',
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            placeName: data['placeName']?.toString().trim().isNotEmpty == true
                ? data['placeName'].toString()
                : placeName,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          ),
        );
      }
    }

    reviews.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ReviewWithPlace>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionLoadingCard();
        }

        if (snapshot.hasError) {
          return _EmptySectionCard(
            icon: Icons.error_outline_rounded,
            title: 'Could not load reviews',
            message: snapshot.error.toString(),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const _EmptySectionCard(
            icon: Icons.rate_review_outlined,
            title: 'No reviews yet',
            message: 'Reviews you write for places will appear here.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            ...reviews.map((review) {
              return _ProfileReviewCard(
                review: review,
                onEdit: () async {
                  widget.onEditReview(review);
                  await Future.delayed(const Duration(milliseconds: 500));
                  _refresh();
                },
                onDelete: () async {
                  widget.onDeleteReview(review);
                  await Future.delayed(const Duration(milliseconds: 500));
                  _refresh();
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class _ContentSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ContentSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ProfileScreenState.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: _ProfileScreenState.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final Widget trailing;

  const _ProfilePlaceCard({
    required this.place,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = place.images.isNotEmpty && place.images.first.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ProfileScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.026),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: place.images.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _fallbackImage(),
                        )
                      : _fallbackImage(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniPill(
                      label:
                          place.category.isEmpty ? 'General' : place.category,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileScreenState.textColor,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: _ProfileScreenState.goldColor,
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: _ProfileScreenState.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.rate_review_outlined,
                          color: _ProfileScreenState.mutedText,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${place.reviewCount}',
                          style: const TextStyle(
                            color: _ProfileScreenState.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: _ProfileScreenState.surfaceColor,
      child: const Center(
        child: Icon(
          Icons.place_rounded,
          color: _ProfileScreenState.primaryColor,
          size: 32,
        ),
      ),
    );
  }
}

class _ProfileReviewCard extends StatelessWidget {
  final _ReviewWithPlace review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ProfileScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.026),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(rating: review.rating),
              const Spacer(),
              PopupMenuButton<String>(
                color: _ProfileScreenState.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit review'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete review',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          if (review.placeName != null && review.placeName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.placeName!,
              style: const TextStyle(
                color: _ProfileScreenState.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            review.text,
            style: const TextStyle(
              color: _ProfileScreenState.textColor,
              height: 1.4,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _ProfileScreenState.softPrimary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ProfileScreenState.primaryColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;

  const _Stars({
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final count = rating.round().clamp(0, 5);

    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFE5A11A),
          size: 19,
        );
      }),
    );
  }
}

class _SectionLoadingCard extends StatelessWidget {
  const _SectionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ProfileScreenState.borderColor),
      ),
      child: const Center(
        child:
            CircularProgressIndicator(color: _ProfileScreenState.primaryColor),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _ProfileScreenState.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ProfileScreenState.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: _ProfileScreenState.primaryColor,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _ProfileScreenState.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileScreenState.mutedText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingFallback extends StatelessWidget {
  const _ProfileLoadingFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileScreenState.bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _ProfileScreenState.cardColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _ProfileScreenState.borderColor),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 46,
                  color: _ProfileScreenState.mutedText,
                ),
                SizedBox(height: 14),
                Text(
                  'Profile is being created...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileScreenState.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'If this stays for more than a few seconds, log out and sign up again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ProfileScreenState.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditReviewDialog extends StatefulWidget {
  final _ReviewWithPlace review;

  const _EditReviewDialog({
    required this.review,
  });

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late TextEditingController _controller;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.text);
    _rating = widget.review.rating.round().clamp(1, 5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    Navigator.pop(
      context,
      _EditedReviewResult(
        text: text,
        rating: _rating.toDouble(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _ProfileScreenState.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      title: const Text('Edit review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFE5A11A),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Update your review...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _ProfileScreenState.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ReviewWithPlace {
  final String reviewId;
  final String placeId;
  final String text;
  final double rating;
  final String? placeName;
  final DateTime? createdAt;

  const _ReviewWithPlace({
    required this.reviewId,
    required this.placeId,
    required this.text,
    required this.rating,
    required this.placeName,
    required this.createdAt,
  });
}

class _EditedReviewResult {
  final String text;
  final double rating;

  const _EditedReviewResult({
    required this.text,
    required this.rating,
  });
}
