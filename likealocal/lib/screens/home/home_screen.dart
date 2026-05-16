import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:like_a_local/screens/chat/chat_screen.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../providers/place_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../explore/widgets/social_place_card.dart';
import '../place/place_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color borderColor = Color(0xFFF0E4DC);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  Future<Map<String, AppUser>> _loadCreators(List<Place> places) async {
    final creatorIds = places
        .map((place) => place.createdBy)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    return UserService().getUsersByIds(creatorIds);
  }

  List<Place> _getSuperUserPlaces(
    List<Place> places,
    Map<String, AppUser> creators,
  ) {
    final result = places.where((place) {
      final creatorId = place.createdBy;
      if (creatorId == null || creatorId.isEmpty) return false;
      return creators[creatorId]?.isSuperUser == true;
    }).toList();

    result.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      final reviewsCompare = b.reviewCount.compareTo(a.reviewCount);
      if (reviewsCompare != 0) return reviewsCompare;

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return result;
  }

  List<Place> _getFeedPlaces(
    List<Place> places,
    List<Place> superUserPlaces,
  ) {
    final superIds = superUserPlaces.map((place) => place.id).toSet();

    final result = places.where((place) {
      return !superIds.contains(place.id);
    }).toList();

    result.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    if (result.isEmpty) {
      final fallback = List<Place>.from(places);
      fallback.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return fallback;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer2<PlaceProvider, UserProvider>(
        builder: (context, placeProvider, userProvider, child) {
          if (placeProvider.isLoading) {
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
              final superUserPlaces = _getSuperUserPlaces(places, creators);
              final feedPlaces = _getFeedPlaces(places, superUserPlaces);

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeHeader(user: currentUser),
                    ),
                    if (superUserPlaces.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _SuperUserPicksSection(
                          places: superUserPlaces.take(8).toList(),
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
              // Brand name only — no buttons (bell lives in MainNavigation)
              const Text(
                'LikeALocal',
                style: TextStyle(
                  color: HomeScreen.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hey, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeScreen.textColor,
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
                  color: HomeScreen.mutedText,
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
      color: isPrimary ? HomeScreen.primaryColor : HomeScreen.cardColor,
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
                    color: HomeScreen.borderColor,
                  ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? HomeScreen.primaryColor.withOpacity(0.22)
                    : Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : HomeScreen.textColor,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _SuperUserPicksSection extends StatelessWidget {
  final List<Place> places;
  final Map<String, AppUser> creators;

  const _SuperUserPicksSection({
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
            title: 'Super User picks',
            subtitle: 'Curated by trusted local contributors',
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

                return _SuperPickCard(
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

class _SuperPickCard extends StatefulWidget {
  final Place place;
  final AppUser? creator;

  const _SuperPickCard({
    required this.place,
    required this.creator,
  });

  @override
  State<_SuperPickCard> createState() => _SuperPickCardState();
}

class _SuperPickCardState extends State<_SuperPickCard> {
  bool _isSaved = false;
  bool _isLoadingSaved = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoadingSaved = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pins')
          .doc(widget.place.id)
          .get();

      if (!mounted) return;

      setState(() {
        _isSaved = doc.exists;
        _isLoadingSaved = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSaved = false);
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final previous = _isSaved;

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pins')
          .doc(widget.place.id);

      if (_isSaved) {
        await docRef.set({
          'placeId': widget.place.id,
          'savedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to pins'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await docRef.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from pins'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaved = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openDetails() {
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
                    color: HomeScreen.softPrimary,
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
                            color: HomeScreen.softPrimary,
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
                      color: HomeScreen.cardColor.withOpacity(0.94),
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
                        color: HomeScreen.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: _isLoadingSaved ? null : _toggleSave,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: HomeScreen.cardColor.withOpacity(0.94),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isLoadingSaved
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: HomeScreen.primaryColor,
                              ),
                            )
                          : Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _isSaved
                                  ? HomeScreen.primaryColor
                                  : HomeScreen.textColor,
                              size: 21,
                            ),
                    ),
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
                color: HomeScreen.textColor,
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
                    color: HomeScreen.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.rate_review_outlined,
                  size: 15,
                  color: HomeScreen.mutedText.withOpacity(0.75),
                ),
                const SizedBox(width: 3),
                Text(
                  '${place.reviewCount}',
                  style: const TextStyle(
                    color: HomeScreen.mutedText,
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
                    color: HomeScreen.textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: HomeScreen.mutedText,
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
      color: HomeScreen.softPrimary,
      child: const Center(
        child: Icon(
          Icons.place_rounded,
          color: HomeScreen.primaryColor,
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
                  color: HomeScreen.mutedText,
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
