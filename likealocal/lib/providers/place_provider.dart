import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import '../services/place_service.dart';

class PlaceProvider extends ChangeNotifier {
  final PlaceService _placeService = PlaceService();

  StreamSubscription<List<Place>>? _placesSubscription;

  List<Place> _places = [];

  bool _isLoading = true;
  bool _loadedFromCache = false;
  String? _error;

  List<Place> get places => List.unmodifiable(_places);
  bool get isLoading => _isLoading;
  bool get loadedFromCache => _loadedFromCache;
  String? get error => _error;

  PlaceProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();
    _listenToPlaces();
  }

  void _listenToPlaces() {
    _placesSubscription?.cancel();

    _placesSubscription = _placeService.getPlaces().listen(
      (places) {
        _places = places;
        _isLoading = false;
        _loadedFromCache = false;
        _error = null;

        _saveToCache(places);

        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshFromCache() async {
    try {
      final places = await _placeService.getPlacesOnce(fromCache: true);
      _places = places;
      _loadedFromCache = true;
      _isLoading = false;
      _saveToCache(places);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addPlace(
    Place place, {
    List<String> localImagePaths = const [],
    required bool isOffline,
  }) async {
    if (isOffline && localImagePaths.isNotEmpty) {
      throw Exception(
        'Place image uploads are not available offline. Please reconnect.',
      );
    }

    await _placeService.addPlace(
      place,
      localImagePaths: localImagePaths,
    );
  }

  Future<void> updatePlace(
    Place place, {
    List<String> newLocalImagePaths = const [],
    List<String> removeImageUrls = const [],
    required bool isOffline,
  }) async {
    if (isOffline &&
        (newLocalImagePaths.isNotEmpty || removeImageUrls.isNotEmpty)) {
      throw Exception(
        'Image changes are not available offline. Please reconnect.',
      );
    }

    await _placeService.updatePlace(
      place,
      newLocalImagePaths: newLocalImagePaths,
      removeImageUrls: removeImageUrls,
    );
  }

  Future<void> deletePlace(
    String placeId, {
    required bool isOffline,
  }) async {
    if (isOffline) {
      throw Exception('Deleting places is not available offline.');
    }

    await _placeService.deletePlace(placeId);
  }

  List<Place> placesByUser(String uid) {
    final result = _places.where((place) => place.createdBy == uid).toList();

    result.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return result;
  }

  List<Place> topRatedPlaces({int limit = 10}) {
    final result = List<Place>.from(_places);

    result.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;
      return b.reviewCount.compareTo(a.reviewCount);
    });

    return result.take(limit).toList();
  }

  List<Place> newestPlaces({int limit = 10}) {
    final result = List<Place>.from(_places);

    result.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return result.take(limit).toList();
  }

  List<Place> trendingPlaces({int limit = 10}) {
    final result = List<Place>.from(_places);

    result.sort((a, b) {
      return _trendingScore(b).compareTo(_trendingScore(a));
    });

    return result.take(limit).toList();
  }

  List<Place> searchPlaces(String query) {
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) return List<Place>.from(_places);

    return _places.where((place) {
      return place.name.toLowerCase().contains(cleanQuery) ||
          place.description.toLowerCase().contains(cleanQuery) ||
          place.category.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  List<Place> placesByCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return List<Place>.from(_places);
    }

    return _places.where((place) => place.category == category).toList();
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

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? placesData = prefs.getString('cached_places');

    if (placesData == null) return;

    try {
      final List<dynamic> listData = json.decode(placesData);

      _places = listData.map((data) {
        final map = Map<String, dynamic>.from(data as Map);

        if (map['location'] != null && map['location'] is Map) {
          map['location'] = GeoPoint(
            (map['location']['lat'] as num).toDouble(),
            (map['location']['lng'] as num).toDouble(),
          );
        }

        if (map['createdAt'] != null && map['createdAt'] is String) {
          map['createdAt'] = Timestamp.fromDate(
            DateTime.parse(map['createdAt']),
          );
        }

        return Place.fromMap(map, map['id']?.toString() ?? '');
      }).toList();

      _isLoading = false;
      _loadedFromCache = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Places cache load error: $e');
    }
  }

  Future<void> _saveToCache(List<Place> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> listData = places.map((place) {
        final map = place.toMap();
        map['id'] = place.id;

        final location = map['location'];

        if (location is GeoPoint) {
          map['location'] = {
            'lat': location.latitude,
            'lng': location.longitude,
          };
        }

        final createdAt = map['createdAt'];

        if (createdAt is Timestamp) {
          map['createdAt'] = createdAt.toDate().toIso8601String();
        }

        return map;
      }).toList();

      await prefs.setString('cached_places', json.encode(listData));
    } catch (e) {
      debugPrint('Places cache save error: $e');
    }
  }

  @override
  void dispose() {
    _placesSubscription?.cancel();
    super.dispose();
  }
}
