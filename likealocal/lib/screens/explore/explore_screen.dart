import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/place_service.dart';
import '../../services/user_service.dart';
import '../../services/recommendation_service.dart';
import '../../utils/categories.dart';
import '../place/place_details_screen.dart';

import 'widgets/place_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/category_filter.dart';
import 'widgets/trending_section.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlaceService _placeService = PlaceService();
  final RecommendationService _recommendationService = RecommendationService();
  late final Stream<List<Place>> _placesStream;

  String _searchQuery = '';
  String? _selectedCategory;
  bool _showForYou = false;

  Map<String, AppUser> _creators = {};
  bool _isFetchingCreators = false;

  Map<String, dynamic>? _recommendationProfile;
  Timer? _searchDebounce;

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    _placesStream = _placeService.getPlaces();
    _loadRecommendationProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecommendationProfile() async {
    final profile = await _recommendationService.getRecommendationProfile();
    if (mounted) {
      setState(() => _recommendationProfile = profile);
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.toLowerCase());

    _searchDebounce?.cancel();
    if (val.trim().length > 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 700), () {
        _recommendationService.trackSearch(val);
      });
    }
  }

  Future<void> _loadCreators(List<Place> places) async {
    final creatorIds = places
        .map((p) => p.createdBy)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    if (creatorIds.isEmpty) return;

    final newIds = creatorIds.where((id) => !_creators.containsKey(id)).toList();
    if (newIds.isEmpty) return;

    if (_isFetchingCreators) return;
    _isFetchingCreators = true;

    try {
      final users = await UserService().getUsersByIds(newIds);
      if (mounted) {
        setState(() {
          _creators.addAll(users);
          _isFetchingCreators = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFetchingCreators = false);
      }
    }
  }

  List<Place> _filterPlaces(List<Place> places, AppUser? user) {
    var filtered = places.where((place) {
      final matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery) ||
          place.description.toLowerCase().contains(_searchQuery) ||
          place.category.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == null || place.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (_showForYou) {
      final likedCategories = List<String>.from(_recommendationProfile?['likedCategories'] ?? []);
      final interactionScores = Map<String, dynamic>.from(_recommendationProfile?['interactionScore'] ?? {});
      final userPrefs = user?.preferences ?? [];

      filtered.sort((a, b) {
        double calculateScore(Place place) {
          double score = 0;

          // User preference boost (+10)
          if (userPrefs.contains(place.category)) {
            score += 10;
          }

          // Liked categories boost (+8)
          if (likedCategories.contains(place.category)) {
            score += 8;
          }

          // Interaction score boost
          score += (interactionScores[place.category] ?? 0).toDouble();

          // Super User boost (+3)
          final isSuper = _creators[place.createdBy]?.isSuperUser == true;
          if (isSuper) {
            score += 3;
          }

          // Rating
          score += place.rating;

          // Review count (+0.1 per review)
          score += place.reviewCount * 0.1;

          debugPrint('Explore [${place.name}] score = $score (Cat: ${place.category}, Super: $isSuper)');
          return score;
        }

        final scoreA = calculateScore(a);
        final scoreB = calculateScore(b);

        return scoreB.compareTo(scoreA);
      });
    } else {
      // Standard Sorting: Super User priority -> Rating -> ReviewCount -> Date
      filtered.sort((a, b) {
        final aIsSuper = _creators[a.createdBy]?.isSuperUser == true;
        final bIsSuper = _creators[b.createdBy]?.isSuperUser == true;

        if (aIsSuper && !bIsSuper) return -1;
        if (!aIsSuper && bIsSuper) return 1;

        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;

        final reviewCompare = b.reviewCount.compareTo(a.reviewCount);
        if (reviewCompare != 0) return reviewCompare;

        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    }

    return filtered;
  }

  List<Place> _getTrending(List<Place> places) {
    final result = List<Place>.from(places);
    result.sort((a, b) {
      final aScore = a.rating * 2 + a.reviewCount * 0.1;
      final bScore = b.rating * 2 + b.reviewCount * 0.1;
      return bScore.compareTo(aScore);
    });
    return result.take(10).toList();
  }

  double? _getDistance(Place place) {
    final pos = context.read<LocationProvider>().currentPosition;
    if (pos == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, place.lat, place.lng);
  }

  void _openPlaceDetails(Place place) {
    _recommendationService.trackViewPlace(place.id, place.category);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: place,
          distanceInMeters: _getDistance(place),
        ),
      ),
    ).then((_) => _loadRecommendationProfile()); // Refresh profile when back
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Place>>(
          stream: _placesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: primaryColor));
            }

            final allPlaces = snapshot.data ?? [];
            if (allPlaces.isNotEmpty) {
              _loadCreators(allPlaces);
            }

            final filtered = _filterPlaces(allPlaces, user);
            final trending = _getTrending(allPlaces);

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 17 ? 'afternoon' : 'evening'}, ${user?.name.split(' ').first ?? 'Nazmy'} 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Discover local gems tonight',
                          style: TextStyle(
                            fontSize: 15,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SearchBarWidget(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () => setState(() => _searchQuery = ''),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'For You',
                          isSelected: _showForYou,
                          onTap: () {
                            setState(() => _showForYou = !_showForYou);
                            if (_showForYou) _loadRecommendationProfile();
                          },
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(width: 8),
                        CategoryFilter(
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                          categories: Categories.all,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_searchQuery.isEmpty && _selectedCategory == null && !_showForYou)
                  SliverToBoxAdapter(
                    child: TrendingSection(
                      trendingPlaces: trending,
                      getDistance: _getDistance,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      'Explore Feed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No places found matching your filters.',
                        style: TextStyle(color: mutedText),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final place = filtered[index];
                          final creator = _creators[place.createdBy];
                          return PlaceCard(
                            place: place,
                            distanceInMeters: _getDistance(place),
                            creatorName: creator?.name,
                            isSuperUser: creator?.isSuperUser ?? false,
                            onTap: () => _openPlaceDetails(place),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : lightPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

