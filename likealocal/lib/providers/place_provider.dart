import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import '../services/place_service.dart';

class PlaceProvider extends ChangeNotifier {
  final PlaceService _placeService = PlaceService();
  List<Place> _places = [];
  bool _isLoading = true;

  List<Place> get places => _places;
  bool get isLoading => _isLoading;

  PlaceProvider() {
    _loadFromCache();
    _placeService.getPlaces().listen((List<Place> places) {
      _places = places;
      _isLoading = false;
      _saveToCache(places);
      notifyListeners();
    });
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? placesData = prefs.getString('cached_places');
    if (placesData != null) {
      try {
        final List<dynamic> listData = json.decode(placesData);
        _places = listData.map((data) {
          if (data['location'] != null) {
            data['location'] =
                GeoPoint(data['location']['lat'], data['location']['lng']);
          }
          if (data['createdAt'] != null) {
            data['createdAt'] =
                Timestamp.fromDate(DateTime.parse(data['createdAt']));
          }
          return Place.fromMap(data, data['id']);
        }).toList();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Places Cache load error: $e');
      }
    }
  }

  Future<void> _saveToCache(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> listData = places.map((place) {
      final map = place.toMap();
      map['id'] = place.id;
      if (map['location'] != null) {
        map['location'] = {
          'lat': (map['location'] as GeoPoint).latitude,
          'lng': (map['location'] as GeoPoint).longitude,
        };
      }
      if (map['createdAt'] != null) {
        map['createdAt'] =
            (map['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      return map;
    }).toList();
    prefs.setString('cached_places', json.encode(listData));
  }
}
