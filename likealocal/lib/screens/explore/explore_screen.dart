import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/place_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../models/place.dart';
import '../../models/user_model.dart';
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
  final PlaceService _placeService = PlaceService();
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();

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
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _userService.getCurrentUser().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _toggleNearMe() async {
    if (_sortByNearMe) {
      setState(() {
        _sortByNearMe = false;
      });
      return;
    }

    final pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _currentPosition = pos;
        _sortByNearMe = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied or disabled.')),
        );
        setState(() {
          _sortByNearMe = false;
        });
      }
    }
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
    var filtered = places.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      // 1. User preferences boost
      bool aPref = _currentUser?.preferences.contains(a.category) ?? false;
      bool bPref = _currentUser?.preferences.contains(b.category) ?? false;

      if (aPref && !bPref) return -1;
      if (!aPref && bPref) return 1;

      // 2. Near Me distance sort
      if (_sortByNearMe && _currentPosition != null) {
        final distA = _getDistance(a) ?? double.infinity;
        final distB = _getDistance(b) ?? double.infinity;
        return distA.compareTo(distB);
      }

      // 3. Fallback to Rating
      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  List<Place> _getTrending(List<Place> places) {
    var trending = List<Place>.from(places);
    trending.sort((a, b) {
      if (b.rating != a.rating) {
        return b.rating.compareTo(a.rating); 
      }
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return trending.take(5).toList(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.my_location,
              color: _sortByNearMe ? Theme.of(context).primaryColor : Colors.grey,
            ),
            onPressed: _toggleNearMe,
            tooltip: 'Near Me',
          ),
        ],
      ),
      body: Column(
        children: [
          // Visual Verification Text
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              'Member 1 Explore Active',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Place>>(
              stream: _placeService.getPlaces(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Firestore error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No places found"));
                }

                final allPlaces = snapshot.data!;
                final displayPlaces = _filterAndSortPlaces(allPlaces);
                final trendingPlaces = _getTrending(allPlaces);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SearchBarWidget(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CategoryFilter(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                        categories: _categories,
                      ),
                    ),
                    if (_searchQuery.isEmpty && _selectedCategory == null && !_sortByNearMe)
                      SliverToBoxAdapter(
                        child: TrendingSection(
                          trendingPlaces: trendingPlaces,
                          getDistance: _getDistance,
                        ),
                      ),
                    if (displayPlaces.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text("No places matching your filters.")),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final place = displayPlaces[index];
                              return PlaceCard(
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
          ),
        ],
      ),
    );
  }
}
