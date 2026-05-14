import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;

  LocationProvider() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? posData = prefs.getString('cached_position');
    if (posData != null) {
      try {
        final Map<String, dynamic> map = json.decode(posData);
        _currentPosition = Position.fromMap(map);
        notifyListeners();
      } catch (e) {
        debugPrint('Location Cache load error: $e');
      }
    }
  }

  Future<void> _saveToCache(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_position', json.encode(position.toJson()));
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    notifyListeners();

    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      _saveToCache(position);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  double calculateDistance(double endLatitude, double endLongitude) {
    if (_currentPosition == null) return 0.0;
    return _locationService.calculateDistance(
        _currentPosition!.latitude, _currentPosition!.longitude, endLatitude, endLongitude);
  }
}
