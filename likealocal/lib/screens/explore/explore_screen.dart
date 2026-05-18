import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../utils/voice_search_matcher.dart';

import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/place_provider.dart';
import '../../services/user_service.dart';
import '../../services/recommendation_service.dart';
import '../../utils/categories.dart';
import '../place/place_details_screen.dart';
import '../chat/ai_chatbot_screen.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';

import 'widgets/place_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/trending_section.dart';

enum ExploreSortMode {
  recommended,
  newest,
  rating,
  mostReviewed,
  budgetLowToHigh,
  budgetHighToLow,
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  final RecommendationService _recommendationService = RecommendationService();
  final ScrollController _scrollController = ScrollController();

  List<Place> _latestPlaces = [];
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechAvailable = false;
  bool _isListening = false;
  String _searchQuery = '';

  String? _selectedCategory;
  int? _selectedBudgetLevel;
  bool _showScrollToTop = false;

  bool _showForYou = false;
  bool _showNearby = false;
  bool _showNewestFirst = true;

  ExploreSortMode _sortMode = ExploreSortMode.recommended;

  Map<String, AppUser> _creators = {};
  bool _isFetchingCreators = false;

  Map<String, dynamic>? _recommendationProfile;
  Timer? _searchDebounce;

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFBE8DF);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);

  @override
  @override
  void initState() {
    super.initState();

    _loadRecommendationProfile();
    _initSpeech();

    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 420;

      if (shouldShow != _showScrollToTop && mounted) {
        setState(() {
          _showScrollToTop = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  int _compareSuperUserPriority(Place a, Place b) {
    final aIsSuper = _creators[a.createdBy]?.isSuperUser == true;
    final bIsSuper = _creators[b.createdBy]?.isSuperUser == true;

    if (aIsSuper && !bIsSuper) return -1;
    if (!aIsSuper && bIsSuper) return 1;

    return 0;
  }

  void _sortDefaultExploreFeed(List<Place> places) {
    places.sort((a, b) {
      final superCompare = _compareSuperUserPriority(a, b);

      if (superCompare != 0) return superCompare;

      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      final reviewCompare = b.reviewCount.compareTo(a.reviewCount);
      if (reviewCompare != 0) return reviewCompare;

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });
  }

  Future<void> _toggleNearby() async {
    final locationProvider = context.read<LocationProvider>();

    if (!_showNearby) {
      await locationProvider.fetchLocation();

      if (locationProvider.error != null || !locationProvider.hasLocation) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied or disabled.'),
          ),
        );
        return;
      }

      setState(() {
        _showNearby = true;
        _showForYou = false;
        _showNewestFirst = false;
      });
    } else {
      setState(() => _showNearby = false);
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;

          setState(() => _isListening = false);

          final errorMsg = error.errorMsg;

          if (errorMsg == 'error_speech_timeout' ||
              errorMsg == 'error_no_match' ||
              errorMsg == 'error_audio') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('I did not catch that. Try speaking again.'),
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice search error: $errorMsg'),
            ),
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
        _isListening = false;
      });
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
      );
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation,
      localeId: 'en_US',
      onResult: (result) {
        final words = result.recognizedWords.trim();

        if (words.isEmpty) return;

        final correctedQuery = VoiceSearchMatcher.getBestMatch(
          words,
          _latestPlaces,
          threshold: 0.60,
        );

        _searchController.text = correctedQuery;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );

        setState(() {
          _searchQuery = correctedQuery.toLowerCase();
        });

        if (correctedQuery.toLowerCase() != words.toLowerCase() && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Searching for "$correctedQuery"'),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        if (result.finalResult) {
          _recommendationService.trackSearch(correctedQuery);

          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadRecommendationProfile() async {
    final profile = await _recommendationService.getRecommendationProfile();

    if (mounted) {
      setState(() => _recommendationProfile = profile);
    }
  }

  void _toggleForYou() {
    setState(() {
      _showForYou = !_showForYou;

      if (_showForYou) {
        _showNearby = false;
        _showNewestFirst = false;
        _sortMode = ExploreSortMode.recommended;
      }
    });

    if (_showForYou) {
      _loadRecommendationProfile();
    }
  }

  void _toggleNewestFirst() {
    setState(() {
      _showNewestFirst = !_showNewestFirst;

      if (_showNewestFirst) {
        _showForYou = false;
        _showNearby = false;
      }
    });
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

    final newIds =
        creatorIds.where((id) => !_creators.containsKey(id)).toList();

    if (newIds.isEmpty || _isFetchingCreators) return;

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

      final matchesCategory =
          _selectedCategory == null || place.category == _selectedCategory;

      final matchesBudget = _selectedBudgetLevel == null ||
          place.budgetLevel <= _selectedBudgetLevel!;

      return matchesSearch && matchesCategory && matchesBudget;
    }).toList();

    if (_showNearby) {
      final locationProvider = context.read<LocationProvider>();
      final pos = locationProvider.currentPosition;

      if (pos != null) {
        filtered.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            a.lat,
            a.lng,
          );

          final distB = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            b.lat,
            b.lng,
          );

          return distA.compareTo(distB);
        });

        return filtered;
      }
    }

    if (_showForYou) {
      filtered.sort((a, b) {
        final scoreA = _recommendationScore(a, user);
        final scoreB = _recommendationScore(b, user);

        return scoreB.compareTo(scoreA);
      });

      return filtered;
    }

    if (_showNewestFirst || _sortMode == ExploreSortMode.newest) {
      filtered.sort((a, b) {
        final superCompare = _compareSuperUserPriority(a, b);
        if (superCompare != 0) return superCompare;

        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bTime.compareTo(aTime);
      });

      return filtered;
    }

    switch (_sortMode) {
      case ExploreSortMode.rating:
        filtered.sort((a, b) {
          final superCompare = _compareSuperUserPriority(a, b);
          if (superCompare != 0) return superCompare;

          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;

          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;

      case ExploreSortMode.mostReviewed:
        filtered.sort((a, b) {
          final superCompare = _compareSuperUserPriority(a, b);
          if (superCompare != 0) return superCompare;

          final reviewCompare = b.reviewCount.compareTo(a.reviewCount);
          if (reviewCompare != 0) return reviewCompare;

          return b.rating.compareTo(a.rating);
        });
        break;

      case ExploreSortMode.budgetLowToHigh:
        filtered.sort((a, b) {
          final superCompare = _compareSuperUserPriority(a, b);
          if (superCompare != 0) return superCompare;

          final budgetCompare = a.budgetLevel.compareTo(b.budgetLevel);
          if (budgetCompare != 0) return budgetCompare;

          return b.rating.compareTo(a.rating);
        });
        break;

      case ExploreSortMode.budgetHighToLow:
        filtered.sort((a, b) {
          final superCompare = _compareSuperUserPriority(a, b);
          if (superCompare != 0) return superCompare;

          final budgetCompare = b.budgetLevel.compareTo(a.budgetLevel);
          if (budgetCompare != 0) return budgetCompare;

          return b.rating.compareTo(a.rating);
        });
        break;

      case ExploreSortMode.recommended:
        _sortDefaultExploreFeed(filtered);
        break;

      case ExploreSortMode.newest:
        break;
    }

    return filtered;
  }

  double _recommendationScore(Place place, AppUser? user) {
    double score = 0;

    final likedCategories =
        List<String>.from(_recommendationProfile?['likedCategories'] ?? []);

    final interactionScores = Map<String, dynamic>.from(
      _recommendationProfile?['interactionScore'] ?? {},
    );

    final userPrefs = user?.preferences ?? [];
    final budgetScores = Map<String, dynamic>.from(
      _recommendationProfile?['budgetInteractionScore'] ?? {},
    );

    final preferredBudgetLevel =
        (_recommendationProfile?['preferredBudgetLevel'] as num?)?.toInt();

    final userPriceRange = user?.priceRange ?? 1;
    if (userPrefs.contains(place.category)) {
      score += 10;
    }

    if (likedCategories.contains(place.category)) {
      score += 8;
    }

    score += (interactionScores[place.category] ?? 0).toDouble();

    // Match user’s selected price preference.
    final userBudgetDifference = (place.budgetLevel - userPriceRange).abs();

    if (userBudgetDifference == 0) {
      score += 9;
    } else if (userBudgetDifference == 1) {
      score += 5;
    } else if (userBudgetDifference == 2) {
      score += 2;
    }

// Match learned budget behavior from activity.
    final budgetKey = place.budgetLevel.toString();
    score += ((budgetScores[budgetKey] ?? 0) as num).toDouble() * 0.6;

// Boost latest preferred budget level.
    if (preferredBudgetLevel != null &&
        place.budgetLevel == preferredBudgetLevel) {
      score += 4;
    }

    final isSuper = _creators[place.createdBy]?.isSuperUser == true;

    if (isSuper) {
      score += 9;
    }

    score += place.rating;
    score += place.reviewCount * 0.1;

    return score;
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

    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      place.lat,
      place.lng,
    );
  }

  void _openPlaceDetails(Place place) {
    _recommendationService.trackViewPlace(place.id, place.category,
        budgetLevel: place.budgetLevel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: place,
          distanceInMeters: _getDistance(place),
        ),
      ),
    ).then((_) => _loadRecommendationProfile());
  }

  int get _activeAdvancedFilterCount {
    int count = 0;

    if (_selectedCategory != null) count++;
    if (_selectedBudgetLevel != null) count++;
    if (_sortMode != ExploreSortMode.recommended) count++;

    return count;
  }

  String _feedTitle() {
    if (_showNearby) return 'Places Near You';
    if (_showForYou) return 'Picked For You';
    if (_showNewestFirst) return 'Newest Places';

    if (_selectedCategory != null || _selectedBudgetLevel != null) {
      return 'Filtered Places';
    }

    return 'Explore Feed';
  }

  String _sortLabel(ExploreSortMode mode) {
    switch (mode) {
      case ExploreSortMode.recommended:
        return 'Recommended';
      case ExploreSortMode.newest:
        return 'Newest First';
      case ExploreSortMode.rating:
        return 'Highest Rated';
      case ExploreSortMode.mostReviewed:
        return 'Most Reviewed';
      case ExploreSortMode.budgetLowToHigh:
        return 'Budget: \$ → \$\$\$\$';
      case ExploreSortMode.budgetHighToLow:
        return 'Budget: \$\$\$\$ → \$';
    }
  }

  String _budgetLabel(int level) {
    return List.filled(level, r'$').join();
  }

  Future<void> _openFiltersModal() async {
    String? tempCategory = _selectedCategory;
    int? tempBudget = _selectedBudgetLevel;
    ExploreSortMode tempSort = _sortMode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filter places',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(modalContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Refine your feed by category, budget, and sorting preference.',
                        style: TextStyle(
                          color: mutedText,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _FilterSectionTitle(
                        title: 'Categories',
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ModalPill(
                            label: 'All',
                            selected: tempCategory == null,
                            onTap: () {
                              setModalState(() => tempCategory = null);
                            },
                          ),
                          ...Categories.all.map((category) {
                            return _ModalPill(
                              label: category,
                              selected: tempCategory == category,
                              onTap: () {
                                setModalState(() {
                                  tempCategory = tempCategory == category
                                      ? null
                                      : category;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _FilterSectionTitle(
                        title: 'Budget',
                        icon: Icons.payments_rounded,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the maximum budget level you want to see.',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ModalPill(
                            label: 'Any',
                            selected: tempBudget == null,
                            onTap: () {
                              setModalState(() => tempBudget = null);
                            },
                          ),
                          ...List.generate(4, (index) {
                            final level = index + 1;

                            return _ModalPill(
                              label: _budgetLabel(level),
                              selected: tempBudget == level,
                              onTap: () {
                                setModalState(() {
                                  tempBudget =
                                      tempBudget == level ? null : level;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _FilterSectionTitle(
                        title: 'Sort by',
                        icon: Icons.sort_rounded,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: ExploreSortMode.values.map((mode) {
                          return _SortTile(
                            label: _sortLabel(mode),
                            selected: tempSort == mode,
                            onTap: () {
                              setModalState(() {
                                tempSort = mode;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempCategory = null;
                                  tempBudget = null;
                                  tempSort = ExploreSortMode.recommended;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: const BorderSide(color: borderColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = tempCategory;
                                  _selectedBudgetLevel = tempBudget;
                                  _sortMode = tempSort;

                                  if (_sortMode !=
                                      ExploreSortMode.recommended) {
                                    _showForYou = false;
                                  }

                                  if (_sortMode != ExploreSortMode.newest) {
                                    _showNewestFirst = false;
                                  }
                                });

                                Navigator.pop(modalContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _clearAdvancedFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBudgetLevel = null;
      _sortMode = ExploreSortMode.recommended;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final placeProvider = context.watch<PlaceProvider>();
    final allPlaces = placeProvider.places;
    _latestPlaces = allPlaces;

    if (allPlaces.isNotEmpty) {
      _loadCreators(allPlaces);
    }
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _showScrollToTop ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: FloatingActionButton.small(
                heroTag: 'scroll_to_top',
                onPressed: _showScrollToTop ? _scrollToTop : null,
                backgroundColor: cardColor,
                elevation: 4,
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: textColor,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'ai_chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
              );
            },
            backgroundColor: primaryColor,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            if (placeProvider.isLoading && allPlaces.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final filtered = _filterPlaces(allPlaces, user);
            final trending = _getTrending(allPlaces);

            final firstName = (user != null && user.name.trim().isNotEmpty)
                ? user.name.split(' ').first
                : 'there';

            final showTrending = _searchQuery.isEmpty &&
                _selectedCategory == null &&
                _selectedBudgetLevel == null &&
                !_showForYou &&
                !_showNearby;

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _ExploreHeader(firstName: firstName),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SearchBarWidget(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    isListening: _isListening,
                    onMicTap: _toggleVoiceSearch,
                  ),
                ),
                if (_isListening)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: _VoiceListeningBanner(),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _QuickFilterStrip(
                                showNewestFirst: _showNewestFirst,
                                showNearby: _showNearby,
                                showForYou: _showForYou,
                                onNewestTap: _toggleNewestFirst,
                                onNearbyTap: _toggleNearby,
                                onForYouTap: _toggleForYou,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _AdvancedFilterButton(
                              count: _activeAdvancedFilterCount,
                              onTap: _openFiltersModal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_activeAdvancedFilterCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                      child: _ActiveFiltersSummary(
                        category: _selectedCategory,
                        budget: _selectedBudgetLevel == null
                            ? null
                            : _budgetLabel(_selectedBudgetLevel!),
                        sort: _sortMode == ExploreSortMode.recommended
                            ? null
                            : _sortLabel(_sortMode),
                        onClear: _clearAdvancedFilters,
                      ),
                    ),
                  ),
                if (showTrending)
                  SliverToBoxAdapter(
                    child: TrendingSection(
                      trendingPlaces: trending,
                      getDistance: _getDistance,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _feedTitle(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length} places',
                          style: const TextStyle(
                            color: mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyExploreState(
                      onClear: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                          _showForYou = false;
                          _showNearby = false;
                          _showNewestFirst = true;
                          _selectedCategory = null;
                          _selectedBudgetLevel = null;
                          _sortMode = ExploreSortMode.recommended;
                        });
                      },
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
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  final String firstName;

  const _ExploreHeader({
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = _ExploreScreenState.textColor;
    const mutedText = _ExploreScreenState.mutedText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 17 ? 'afternoon' : 'evening'}, $firstName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
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
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ExploreScreenState.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ExploreScreenState.borderColor),
          ),
          child: Icon(
            icon,
            color: _ExploreScreenState.textColor,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _QuickFilterStrip extends StatelessWidget {
  final bool showNewestFirst;
  final bool showNearby;
  final bool showForYou;
  final VoidCallback onNewestTap;
  final VoidCallback onNearbyTap;
  final VoidCallback onForYouTap;

  const _QuickFilterStrip({
    required this.showNewestFirst,
    required this.showNearby,
    required this.showForYou,
    required this.onNewestTap,
    required this.onNearbyTap,
    required this.onForYouTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'Newest',
            isSelected: showNewestFirst,
            icon: Icons.schedule_rounded,
            onTap: onNewestTap,
          ),
          const SizedBox(width: 8),
          _QuickFilterChip(
            label: 'For You',
            isSelected: showForYou,
            icon: Icons.auto_awesome_rounded,
            onTap: onForYouTap,
          ),
          const SizedBox(width: 8),
          _QuickFilterChip(
            label: 'Near Me',
            isSelected: showNearby,
            icon: Icons.near_me_rounded,
            onTap: onNearbyTap,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? _ExploreScreenState.primaryColor
          : _ExploreScreenState.softPrimary,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _ExploreScreenState.primaryColor.withOpacity(0.24),
                      blurRadius: 9,
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
                color: isSelected
                    ? Colors.white
                    : _ExploreScreenState.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : _ExploreScreenState.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceListeningBanner extends StatelessWidget {
  const _VoiceListeningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _ExploreScreenState.softPrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ExploreScreenState.borderColor),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            color: _ExploreScreenState.primaryColor,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Listening... say a place, category, or area',
              style: TextStyle(
                color: _ExploreScreenState.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedFilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AdvancedFilterButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ExploreScreenState.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 42,
          decoration: BoxDecoration(
            color: _ExploreScreenState.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ExploreScreenState.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: _ExploreScreenState.textColor,
                  size: 20,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: _ExploreScreenState.primaryColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _ExploreScreenState.bgColor,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFiltersSummary extends StatelessWidget {
  final String? category;
  final String? budget;
  final String? sort;
  final VoidCallback onClear;

  const _ActiveFiltersSummary({
    required this.category,
    required this.budget,
    required this.sort,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      if (category != null) category!,
      if (budget != null) 'Budget ≤ $budget',
      if (sort != null) sort!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ExploreScreenState.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ExploreScreenState.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: labels.map((label) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ExploreScreenState.softPrimary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _ExploreScreenState.primaryColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear',
              style: TextStyle(
                color: _ExploreScreenState.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FilterSectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: _ExploreScreenState.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _ExploreScreenState.textColor,
            fontSize: 16.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ModalPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModalPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? _ExploreScreenState.primaryColor : const Color(0xFFEDEDE6),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? Colors.white : _ExploreScreenState.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected
            ? _ExploreScreenState.softPrimary
            : const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? _ExploreScreenState.primaryColor.withOpacity(0.30)
                    : _ExploreScreenState.borderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? _ExploreScreenState.primaryColor
                      : _ExploreScreenState.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? _ExploreScreenState.primaryColor
                          : _ExploreScreenState.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
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

class _EmptyExploreState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyExploreState({
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: _ExploreScreenState.primaryColor.withOpacity(0.88),
            ),
            const SizedBox(height: 12),
            const Text(
              'No places found',
              style: TextStyle(
                color: _ExploreScreenState.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search, budget, or category filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ExploreScreenState.mutedText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ExploreScreenState.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Reset Filters',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
