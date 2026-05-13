import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../services/place_service.dart';
import '../../services/user_service.dart';

import 'widgets/category_filter.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/social_place_card.dart';
import 'widgets/trending_section.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PlaceService _placeService = PlaceService();
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;
  bool _sortByNearMe = false;
  Position? _currentPosition;
  AppUser? _currentUser;

  final List<String> _categories = [
    'Restaurant',
    'Cafe',
    'Park',
    'Museum',
    'Shopping',
    'Nightlife',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _userService.getCurrentUser().listen((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleNearMe() async {
    if (_sortByNearMe) {
      setState(() {
        _sortByNearMe = false;
      });
      return;
    }

    final pos = await _locationService.getCurrentLocation();

    if (pos == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied or disabled.'),
        ),
      );

      return;
    }

    setState(() {
      _currentPosition = pos;
      _sortByNearMe = true;
    });
  }

  double? _getDistance(Place place) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.lat,
      place.lng,
    );
  }

  List<Place> _filterAndSortPlaces(List<Place> places) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = places.where((place) {
      final name = place.name.toLowerCase();
      final description = place.description.toLowerCase();
      final category = place.category.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          category.contains(query);

      final matchesCategory =
          _selectedCategory == null || place.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      final aPref = _currentUser?.preferences.contains(a.category) ?? false;
      final bPref = _currentUser?.preferences.contains(b.category) ?? false;

      if (aPref && !bPref) return -1;
      if (!aPref && bPref) return 1;

      if (_sortByNearMe && _currentPosition != null) {
        final distA = _getDistance(a) ?? double.infinity;
        final distB = _getDistance(b) ?? double.infinity;
        return distA.compareTo(distB);
      }

      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  List<Place> _getTrending(List<Place> places) {
    final trending = List<Place>.from(places);

    trending.sort((a, b) {
      if (b.rating != a.rating) {
        return b.rating.compareTo(a.rating);
      }

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return trending.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      appBar: AppBar(
        title: const Text('Explore'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.my_location,
              color: _sortByNearMe
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: _toggleNearMe,
          ),
        ],
      ),
      body: StreamBuilder<List<Place>>(
        stream: _placeService.getPlaces(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Firestore error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPlaces = snapshot.data ?? [];

          if (allPlaces.isEmpty) {
            return const Center(child: Text('No places found'));
          }

          final displayPlaces = _filterAndSortPlaces(allPlaces);
          final trendingPlaces = _getTrending(allPlaces);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: CategoryFilter(
                  selectedCategory: _selectedCategory,
                  categories: _categories,
                  onCategorySelected: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              if (_searchQuery.isEmpty &&
                  _selectedCategory == null &&
                  !_sortByNearMe)
                SliverToBoxAdapter(
                  child: TrendingSection(
                    trendingPlaces: trendingPlaces,
                    getDistance: _getDistance,
                  ),
                ),
              if (displayPlaces.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No places matching your search.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = displayPlaces[index];

                        return SocialPlaceCard(
                          place: place,
                          distanceInMeters: _getDistance(place),
                        );
                      },
                      childCount: displayPlaces.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}