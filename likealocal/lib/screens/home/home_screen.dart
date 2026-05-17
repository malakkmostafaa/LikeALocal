import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/screens/chat/chat_screen.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../providers/place_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/pin_button.dart';
import '../explore/widgets/social_place_card.dart';
import '../place/place_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color borderColor = Color(0xFFF0E4DC);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  final RecommendationService _recommendationService = RecommendationService();
  Map<String, dynamic>? _recommendationProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendationProfile();
  }

  Future<void> _loadRecommendationProfile() async {
    try {
      final profile = await _recommendationService.getRecommendationProfile();
      if (mounted) {
        setState(() {
          _recommendationProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<Map<String, AppUser>> _loadCreators(List<Place> places) async {
    final creatorIds = places
        .map((place) => place.createdBy)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    return UserService().getUsersByIds(creatorIds);
  }

  double _calculateScore({
    required Place place,
    required AppUser? user,
    required List<String> likedCategories,
    required Map<String, dynamic> interactionScores,
    required AppUser? creator,
  }) {
    double score = 0;

    // User preference boost (+10)
    if (user?.preferences.contains(place.category) == true) {
      score += 10;
    }

    // Liked categories boost (+8)
    if (likedCategories.contains(place.category)) {
      score += 8;
    }

    // Interaction score boost
    score += (interactionScores[place.category] ?? 0).toDouble();

    // Super User boost (+3)
    if (creator?.isSuperUser == true) {
      score += 3;
    }

    // Rating
    score += place.rating;

    // Review count (+0.1 per review)
    score += place.reviewCount * 0.1;

    return score;
  }

  List<Place> _getRecommendedPlaces(
    List<Place> places,
    Map<String, AppUser> creators,
    AppUser? user,
  ) {
    final result = List<Place>.from(places);

    final likedCategories =
        List<String>.from(_recommendationProfile?['likedCategories'] ?? []);
    final interactionScores = Map<String, dynamic>.from(
        _recommendationProfile?['interactionScore'] ?? {});

    result.sort((a, b) {
      final scoreA = _calculateScore(
        place: a,
        user: user,
        likedCategories: likedCategories,
        interactionScores: interactionScores,
        creator: creators[a.createdBy],
      );
      final scoreB = _calculateScore(
        place: b,
        user: user,
        likedCategories: likedCategories,
        interactionScores: interactionScores,
        creator: creators[b.createdBy],
      );

      if (scoreA == scoreB) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      }

      return scoreB.compareTo(scoreA);
    });

    return result.take(10).toList();
  }

  List<Place> _getFeedPlaces(
    List<Place> places,
    Map<String, AppUser> creators,
    AppUser? user,
  ) {
    final result = List<Place>.from(places);

    // Filter out some if needed, or just sort.
    // Usually main feed is just recent/trending if not "Recommended" section,
    // but here we keep it sorted by the same logic as requested before or just latest.
    // User requested "Keep Latest local posts section below it".

    result.sort((a, b) {
      // Latest logic as requested for main feed
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer2<PlaceProvider, UserProvider>(
        builder: (context, placeProvider, userProvider, child) {
          if (placeProvider.isLoading || _isLoadingProfile) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final places = placeProvider.places;
          final currentUser = userProvider.user;

          if (places.isEmpty) {
            return _EmptyHomeState(user: currentUser);
          }

          return FutureBuilder<Map<String, AppUser>>(
            future: _loadCreators(places),
            builder: (context, snapshot) {
              final creators = snapshot.data ?? {};
              final recommendedPlaces =
                  _getRecommendedPlaces(places, creators, currentUser);
              final feedPlaces = _getFeedPlaces(places, creators, currentUser);

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  await _loadRecommendationProfile();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeHeader(user: currentUser),
                    ),
                    if (recommendedPlaces.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _RecommendedPlacesSection(
                          places: recommendedPlaces,
                          creators: creators,
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Latest local posts',
                        subtitle: 'Fresh recommendations from the community',
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final place = feedPlaces[index];
                            return SocialPlaceCard(place: place);
                          },
                          childCount: feedPlaces.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 28),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final AppUser? user;

  const _HomeHeader({required this.user});

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim().split(' ').first
        : 'there';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'LikeALocal',
                    style: TextStyle(
                      color: _HomeScreenState.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.chat_bubble_rounded,
                  isPrimary: true,
                  onTap: () => _openChat(context),
                ),
                const SizedBox(width: 10),
                _HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Hey, $firstName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeScreenState.textColor,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Trusted local recommendations, curated for you.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _HomeScreenState.mutedText,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? _HomeScreenState.primaryColor
          : _HomeScreenState.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(
                    color: _HomeScreenState.borderColor,
                  ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? _HomeScreenState.primaryColor.withOpacity(0.22)
                    : Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : _HomeScreenState.textColor,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _RecommendedPlacesSection extends StatelessWidget {
  final List<Place> places;
  final Map<String, AppUser> creators;

  const _RecommendedPlacesSection({
    required this.places,
    required this.creators,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Recommended for You',
            subtitle: 'Based on your preferences and activity',
          ),
          SizedBox(
            height: 235,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final place = places[index];
                final creator =
                    place.createdBy == null ? null : creators[place.createdBy!];

                return _RecommendedPlaceCard(
                  place: place,
                  creator: creator,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedPlaceCard extends StatefulWidget {
  final Place place;
  final AppUser? creator;

  const _RecommendedPlaceCard({
    required this.place,
    required this.creator,
  });

  @override
  State<_RecommendedPlaceCard> createState() => _RecommendedPlaceCardState();
}

class _RecommendedPlaceCardState extends State<_RecommendedPlaceCard> {
  final RecommendationService _recommendationService = RecommendationService();

  void _openDetails() {
    _recommendationService.trackViewPlace(
        widget.place.id, widget.place.category,
        budgetLevel: widget.place.budgetLevel);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(place: widget.place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final hasImage = place.images.isNotEmpty && place.images.first.isNotEmpty;

    return GestureDetector(
      onTap: _openDetails,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 155,
                  width: 220,
                  decoration: BoxDecoration(
                    color: _HomeScreenState.softPrimary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: place.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: _HomeScreenState.softPrimary,
                          ),
                          errorWidget: (_, __, ___) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _HomeScreenState.cardColor.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      place.category.isEmpty ? 'General' : place.category,
                      style: const TextStyle(
                        color: _HomeScreenState.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: PinButton(
                    placeId: widget.place.id,
                    backgroundColor: _HomeScreenState.cardColor,
                    activeColor: _HomeScreenState.primaryColor,
                    inactiveColor: _HomeScreenState.textColor,
                    onChanged: (pinned) {
                      if (pinned) {
                        _recommendationService.trackSavePlace(
                          widget.place.id,
                          widget.place.category,
                          budgetLevel: widget.place.budgetLevel,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeScreenState.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE5A11A),
                  size: 18,
                ),
                const SizedBox(width: 3),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: _HomeScreenState.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.rate_review_outlined,
                  size: 15,
                  color: _HomeScreenState.mutedText.withOpacity(0.75),
                ),
                const SizedBox(width: 3),
                Text(
                  '${place.reviewCount}',
                  style: const TextStyle(
                    color: _HomeScreenState.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _HomeScreenState.textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _HomeScreenState.mutedText,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _HomeScreenState.softPrimary,
      child: const Center(
        child: Icon(
          Icons.place_rounded,
          color: _HomeScreenState.primaryColor,
          size: 44,
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final AppUser? user;

  const _EmptyHomeState({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HomeHeader(user: user)),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No places yet. Add the first local gem!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _HomeScreenState.mutedText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
