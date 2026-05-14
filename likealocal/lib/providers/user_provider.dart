import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();

    _userService.currentUserStream().listen(
      (AppUser? user) {
        _user = user;
        _isLoading = false;
        _error = null;

        if (user != null) {
          _saveToCache(user);
        } else {
          _clearCache();
        }

        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('cached_user_profile');

      if (userData == null) return;

      final Map<String, dynamic> map = json.decode(userData);
      _user = AppUser.fromMap(map);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('User cache load error: $e');
    }
  }

  Future<void> _saveToCache(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_profile',
        json.encode(user.toCacheMap()),
      );
    } catch (e) {
      debugPrint('User cache save error: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_profile');
    } catch (e) {
      debugPrint('User cache clear error: $e');
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    await _userService.updateCurrentUser(data);
  }
}
