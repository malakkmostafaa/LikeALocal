import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  AppUser? _user;

  bool _isLoading = true;
  bool _isUpdating = false;

  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  UserProvider() {
    _init();
  }

  StreamSubscription<AppUser?>? _userStreamSub; // ← add this field

  Future<void> _init() async {
    await _loadFromCache();
    _startListening();
  }

  void _startListening() {
    _userStreamSub?.cancel();
    _userStreamSub = _userService.currentUserStream().listen(
      (AppUser? user) {
        _user = user;
        _isLoading = false;
        _error = null;

        if (user != null) {
          _saveToCache(user);
          if (!user.isSuperUser &&
              user.placesAdded >= 50 &&
              user.reviewsCount >= 100) {
            _userService.updateCurrentUser({'isSuperUser': true});
          }
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

  void clear() {
    _userStreamSub?.cancel();
    _user = null;
    _isLoading = false;
    _clearCache();
    notifyListeners();
    _startListening(); // ← restart stream for new user
  }

  @override
  void dispose() {
    _userStreamSub?.cancel();
    super.dispose();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    required List<String> preferences,
    required double maxDistance,
    required int priceRange,
    File? profileImageFile,
    required bool isOffline,
  }) async {
    final cleanName = name.trim();
    final cleanBio = bio.trim();

    if (cleanName.isEmpty) {
      throw Exception('Name cannot be empty.');
    }

    if (preferences.isEmpty) {
      throw Exception('Please select at least one interest.');
    }

    if (profileImageFile != null && isOffline) {
      throw Exception(
        'Profile image upload is not available offline. Please reconnect.',
      );
    }

    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      String imageUrl = _user?.profileImageUrl ?? '';

      if (profileImageFile != null) {
        imageUrl = await _storageService.uploadCurrentUserProfileImage(
          profileImageFile,
        );
      }

      await _userService.updateCurrentUser({
        'name': cleanName,
        'bio': cleanBio,
        'preferences': preferences,
        'maxDistance': maxDistance,
        'priceRange': priceRange,
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateCurrentUser(data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('cached_user_profile');

      if (userData == null) return;

      final Map<String, dynamic> map = json.decode(userData);
      final cachedUser = AppUser.fromMap(map);

      // Discard cache if it belongs to a different or no signed-in user.
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (currentUid == null || cachedUser.uid != currentUid) {
        await _clearCache();
        return;
      }

      _user = cachedUser;
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
}
