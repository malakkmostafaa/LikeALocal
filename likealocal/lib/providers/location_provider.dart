import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;

  LocationProvider() {
    _loadFromCache();
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        _currentPosition = position;
        await _saveToCache(position);
      } else {
        _error = 'Location is unavailable or permission was denied.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double? calculateDistance(double endLatitude, double endLongitude) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? posData = prefs.getString('cached_position');

    if (posData == null) return;

    try {
      final Map<String, dynamic> map = json.decode(posData);
      _currentPosition = Position.fromMap(map);
      notifyListeners();
    } catch (e) {
      debugPrint('Location cache load error: $e');
    }
  }

  Future<void> _saveToCache(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_position',
        json.encode(position.toJson()),
      );
    } catch (e) {
      debugPrint('Location cache save error: $e');
    }
  }
}
