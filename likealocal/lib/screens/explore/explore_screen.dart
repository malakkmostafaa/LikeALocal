import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/categories.dart';
import '../place/place_details_screen.dart';

import 'widgets/place_card.dart';
import 'widgets/search_bar_widget.dart';

enum ExploreCollectionType {
  all,
  category,
  trending,
  nearby,
  topRated,
  newest,
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const Color bgColor = Color(0xFFF6EFE8);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color borderColor = Color(0xFFF0E4DC);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  static List<_CategoryCollectionData> get categoryCollections {
    return Categories.all.map((category) {
      return _CategoryCollectionData(
        label: _displayCategoryName(category),
        category: category,
        icon: _categoryIcon(category),
      );
    }).toList();
  }

  static String _displayCategoryName(String category) {
    switch (category) {
      case Categories.cafe:
        return 'Cafes';
      case Categories.food:
        return 'Food';
      case Categories.restaurant:
        return 'Restaurants';
      case Categories.park:
        return 'Parks';
      case Categories.museum:
        return 'Museums';
      case Categories.bar:
        return 'Bars';
      case Categories.shop:
        return 'Shopping';
      case Categories.other:
        return 'Other';
      default:
        return category;
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case Categories.cafe:
        return Icons.local_cafe_rounded;
      case Categories.food:
        return Icons.restaurant_rounded;
      case Categories.restaurant:
        return Icons.dinner_dining_rounded;
      case Categories.park:
        return Icons.park_rounded;
      case Categories.museum:
        return Icons.museum_rounded;
      case Categories.bar:
        return Icons.local_bar_rounded;
      case Categories.shop:
        return Icons.shopping_bag_rounded;
      case Categories.other:
        return Icons.more_horiz_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  void _openCollection(
    BuildContext context, {
    required ExploreCollectionType type,
    required String title,
    String? category,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceCollectionScreen(
          type: type,
          title: title,
          category: category,
        ),
      ),
    );
  }

  List<Place> _previewPlaces(List<Place> places) {
    final result = List<Place>.from(places);

    result.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      final reviewCompare = b.reviewCount.compareTo(a.reviewCount);
      if (reviewCompare != 0) return reviewCompare;

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return result.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Consumer<PlaceProvider>(
          builder: (context, placeProvider, child) {
            if (placeProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final places = placeProvider.places;

            if (places.isEmpty) {
              return const _EmptyExploreState();
            }

            final previewPlaces = _previewPlaces(places);

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: _ExploreHeader(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: _SearchEntryCard(
                      onTap: () {
                        _openCollection(
                          context,
                          type: ExploreCollectionType.all,
                          title: 'Search Places',
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _AllPlacesHeroCard(
                      totalPlaces: places.length,
                      previewPlaces: previewPlaces,
                      onTap: () {
                        _openCollection(
                          context,
                          type: ExploreCollectionType.all,
                          title: 'All Places',
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Collections',
                    subtitle:
                        'Browse places by the kind of experience you want',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryCollections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = categoryCollections[index];

                        final count = places.where((place) {
                          return place.category == item.category;
                        }).length;

                        return _CategoryCollectionCard(
                          data: item,
                          count: count,
                          places: places,
                          onTap: () {
                            _openCollection(
                              context,
                              type: ExploreCollectionType.category,
                              title: item.label,
                              category: item.category,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                const SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Ways to explore',
                    subtitle: 'Find places by activity, distance, or quality',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _DiscoveryRowCard(
                          title: 'Trending now',
                          subtitle:
                              'Popular places based on ratings, reviews, and recent activity',
                          icon: Icons.trending_up_rounded,
                          onTap: () {
                            _openCollection(
                              context,
                              type: ExploreCollectionType.trending,
                              title: 'Trending Now',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _DiscoveryRowCard(
                          title: 'Near you',
                          subtitle:
                              'Places sorted by distance using your current location',
                          icon: Icons.near_me_rounded,
                          onTap: () {
                            _openCollection(
                              context,
                              type: ExploreCollectionType.nearby,
                              title: 'Near You',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _DiscoveryRowCard(
                          title: 'Top rated gems',
                          subtitle:
                              'The highest rated local spots from the community',
                          icon: Icons.star_rounded,
                          onTap: () {
                            _openCollection(
                              context,
                              type: ExploreCollectionType.topRated,
                              title: 'Top Rated',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _DiscoveryRowCard(
                          title: 'Newly added',
                          subtitle: 'Fresh places recently shared by locals',
                          icon: Icons.fiber_new_rounded,
                          onTap: () {
                            _openCollection(
                              context,
                              type: ExploreCollectionType.newest,
                              title: 'Newly Added',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 34),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlaceCollectionScreen extends StatefulWidget {
  final ExploreCollectionType type;
  final String title;
  final String? category;

  const PlaceCollectionScreen({
    super.key,
    required this.type,
    required this.title,
    this.category,
  });

  @override
  State<PlaceCollectionScreen> createState() => _PlaceCollectionScreenState();
}

class _PlaceCollectionScreenState extends State<PlaceCollectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSort = 'Smart sort';

  Position? _currentPosition;
  bool _isFetchingLocation = false;

  final List<String> _sortOptions = const [
    'Smart sort',
    'Nearby',
    'Trending',
    'Top Rated',
    'Newest',
  ];

  @override
  void initState() {
    super.initState();

    final cachedPosition = context.read<LocationProvider>().currentPosition;
    if (cachedPosition != null) {
      _currentPosition = cachedPosition;
    }

    if (widget.type == ExploreCollectionType.nearby) {
      _selectedSort = 'Nearby';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLocation();
      });
    } else if (widget.type == ExploreCollectionType.trending) {
      _selectedSort = 'Trending';
    } else if (widget.type == ExploreCollectionType.topRated) {
      _selectedSort = 'Top Rated';
    } else if (widget.type == ExploreCollectionType.newest) {
      _selectedSort = 'Newest';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    final locationProvider = context.read<LocationProvider>();
    await locationProvider.fetchLocation();

    if (!mounted) return;

    setState(() {
      _currentPosition = locationProvider.currentPosition;
      _isFetchingLocation = false;
    });

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied or disabled.'),
        ),
      );
    }
  }

  Future<void> _selectSort(String sort) async {
    if (sort == 'Nearby' && _currentPosition == null) {
      await _fetchLocation();
    }

    if (!mounted) return;

    setState(() {
      _selectedSort = sort;
    });
  }

  double? _getDistance(Place place) {
    if (_currentPosition == null) return null;
    if (place.lat == 0 || place.lng == 0) return null;

    return context.read<LocationProvider>().calculateDistance(
          place.lat,
          place.lng,
        );
  }

  double _trendingScore(Place place) {
    final ratingScore = place.rating * 2.2;
    final reviewScore = place.reviewCount * 0.35;

    double recencyScore = 0;
    final createdAt = place.createdAt;

    if (createdAt != null) {
      final daysOld = DateTime.now().difference(createdAt).inDays;

      if (daysOld <= 3) {
        recencyScore = 3;
      } else if (daysOld <= 7) {
        recencyScore = 2;
      } else if (daysOld <= 30) {
        recencyScore = 1;
      }
    }

    return ratingScore + reviewScore + recencyScore;
  }

  List<Place> _basePlaces(List<Place> places) {
    if (widget.type == ExploreCollectionType.category &&
        widget.category != null) {
      return places.where((place) {
        return place.category == widget.category;
      }).toList();
    }

    return List<Place>.from(places);
  }

  List<Place> _applySearch(List<Place> places) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return places;

    return places.where((place) {
      return place.name.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query) ||
          place.category.toLowerCase().contains(query);
    }).toList();
  }

  List<Place> _sortPlaces(List<Place> places, AppUser? user) {
    final result = List<Place>.from(places);

    result.sort((a, b) {
      if (_selectedSort == 'Nearby') {
        final distA = _getDistance(a) ?? double.infinity;
        final distB = _getDistance(b) ?? double.infinity;
        return distA.compareTo(distB);
      }

      if (_selectedSort == 'Trending') {
        return _trendingScore(b).compareTo(_trendingScore(a));
      }

      if (_selectedSort == 'Top Rated') {
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.reviewCount.compareTo(a.reviewCount);
      }

      if (_selectedSort == 'Newest') {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      }

      final aPref = user?.preferences.contains(a.category) ?? false;
      final bPref = user?.preferences.contains(b.category) ?? false;

      if (aPref && !bPref) return -1;
      if (!aPref && bPref) return 1;

      final trendingCompare = _trendingScore(b).compareTo(_trendingScore(a));
      if (trendingCompare != 0) return trendingCompare;

      return b.rating.compareTo(a.rating);
    });

    return result;
  }

  String _subtitle(int count) {
    if (widget.type == ExploreCollectionType.category &&
        widget.category != null) {
      return '$count places in ${widget.category}';
    }

    if (_selectedSort == 'Nearby' && _currentPosition == null) {
      return 'Allow location access to sort by distance';
    }

    return '$count places · $_selectedSort';
  }

  void _openPlaceDetails(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: place,
          distanceInMeters: _getDistance(place),
        ),
      ),
    );
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ExploreScreen.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ExploreScreen.borderColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort places',
                    style: TextStyle(
                      color: ExploreScreen.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ..._sortOptions.map((sort) {
                  final selected = _selectedSort == sort;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? ExploreScreen.primaryColor
                          : ExploreScreen.mutedText,
                    ),
                    title: Text(
                      sort,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w600,
                        color: ExploreScreen.textColor,
                      ),
                    ),
                    subtitle: Text(
                      _sortDescription(sort),
                      style: const TextStyle(
                        color: ExploreScreen.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, sort),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    await _selectSort(result);
  }

  String _sortDescription(String sort) {
    switch (sort) {
      case 'Nearby':
        return 'Closest places based on your current location';
      case 'Trending':
        return 'Rating, reviews, and recency';
      case 'Top Rated':
        return 'Highest rated places first';
      case 'Newest':
        return 'Recently added places first';
      default:
        return 'Balanced discovery using preferences and place activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreScreen.bgColor,
      body: SafeArea(
        bottom: false,
        child: Consumer2<PlaceProvider, UserProvider>(
          builder: (context, placeProvider, userProvider, child) {
            if (placeProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ExploreScreen.primaryColor,
                ),
              );
            }

            final base = _basePlaces(placeProvider.places);
            final searched = _applySearch(base);
            final displayPlaces = _sortPlaces(searched, userProvider.user);

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: _CollectionHeader(
                    title: widget.title,
                    subtitle: _subtitle(displayPlaces.length),
                    sort: _selectedSort,
                    isFetchingLocation: _isFetchingLocation,
                    onSortTap: _openSortSheet,
                  ),
                ),
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
                if (displayPlaces.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No places found here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ExploreScreen.mutedText,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final place = displayPlaces[index];

                          return PlaceCard(
                            place: place,
                            distanceInMeters: _getDistance(place),
                            onTap: () => _openPlaceDetails(place),
                          );
                        },
                        childCount: displayPlaces.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 28),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: TextStyle(
              color: ExploreScreen.textColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Curated ways to discover local places.',
            style: TextStyle(
              color: ExploreScreen.mutedText,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchEntryCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExploreScreen.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ExploreScreen.borderColor),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: ExploreScreen.primaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search local places...',
                  style: TextStyle(
                    color: ExploreScreen.mutedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: ExploreScreen.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllPlacesHeroCard extends StatelessWidget {
  final int totalPlaces;
  final List<Place> previewPlaces;
  final VoidCallback onTap;

  const _AllPlacesHeroCard({
    required this.totalPlaces,
    required this.previewPlaces,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = previewPlaces
        .where(
            (place) => place.images.isNotEmpty && place.images.first.isNotEmpty)
        .map((place) => place.images.first)
        .take(3)
        .toList();

    return Material(
      color: ExploreScreen.primaryColor,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 185,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE26D45),
                Color(0xFFB94F32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: ExploreScreen.primaryColor.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const Spacer(),
                      const Text(
                        'All local places',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$totalPlaces places shared by locals',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 116,
                child: Stack(
                  children: [
                    if (imageUrls.isEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 98,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      )
                    else
                      ...imageUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;

                        return Positioned(
                          right: index * 18.0,
                          top: 16 + index * 12.0,
                          child: Container(
                            width: 76,
                            height: 98,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.75),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.16),
                                child: const Icon(
                                  Icons.place_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

class _CategoryCollectionCard extends StatelessWidget {
  final _CategoryCollectionData data;
  final int count;
  final List<Place> places;
  final VoidCallback onTap;

  const _CategoryCollectionCard({
    required this.data,
    required this.count,
    required this.places,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryPlaces = places.where((place) {
      return place.category == data.category &&
          place.images.isNotEmpty &&
          place.images.first.isNotEmpty;
    }).toList();

    final imageUrl =
        categoryPlaces.isNotEmpty ? categoryPlaces.first.images.first : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: ExploreScreen.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl == null
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFEEE6),
                              Color(0xFFFFFBF7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: ExploreScreen.softPrimary,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: ExploreScreen.softPrimary,
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: imageUrl == null
                          ? [
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.20),
                            ]
                          : [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.62),
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: imageUrl == null
                        ? ExploreScreen.primaryColor
                        : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    data.icon,
                    color: imageUrl == null
                        ? Colors.white
                        : ExploreScreen.primaryColor,
                    size: 23,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: imageUrl == null
                            ? ExploreScreen.textColor
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count places',
                      style: TextStyle(
                        color: imageUrl == null
                            ? ExploreScreen.mutedText
                            : Colors.white.withOpacity(0.86),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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

class _DiscoveryRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DiscoveryRowCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  LinearGradient get _gradient {
    if (title.contains('Trending')) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFEEE6),
          Color(0xFFFFD6C2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (title.contains('Near')) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFEEE6),
          Color(0xFFFFD6C2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (title.contains('Top')) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFEEE6),
          Color(0xFFFFD6C2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [
        Color(0xFFFFEEE6),
        Color(0xFFFFD6C2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color get _accentColor {
    return ExploreScreen.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: _accentColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ExploreScreen.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ExploreScreen.textColor.withOpacity(0.62),
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _accentColor,
                  size: 18,
                ),
              ),
            ],
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ExploreScreen.textColor,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: ExploreScreen.mutedText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String sort;
  final bool isFetchingLocation;
  final VoidCallback onSortTap;

  const _CollectionHeader({
    required this.title,
    required this.subtitle,
    required this.sort,
    required this.isFetchingLocation,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: ExploreScreen.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ExploreScreen.textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6, bottom: 12),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: ExploreScreen.mutedText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: _SortButton(
              label: sort,
              isLoading: isFetchingLocation,
              onTap: onSortTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExploreScreen.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ExploreScreen.borderColor),
          ),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ExploreScreen.primaryColor,
                  ),
                )
              else
                const Icon(
                  Icons.swap_vert_rounded,
                  color: ExploreScreen.primaryColor,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ExploreScreen.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ExploreScreen.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExploreState extends StatelessWidget {
  const _EmptyExploreState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No places yet. Add the first local gem!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ExploreScreen.mutedText,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _CategoryCollectionData {
  final String label;
  final String category;
  final IconData icon;

  const _CategoryCollectionData({
    required this.label,
    required this.category,
    required this.icon,
  });
}
