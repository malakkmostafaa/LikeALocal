import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authSubscription = _authService.authStateChanges.listen(
      (User? user) {
        _user = user;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> login(String email, String password) async {
    await _runAuthAction(() {
      return _authService.login(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signUp(
    String name,
    String email,
    String password, {
    List<String> interests = const [],
  }) async {
    await _runAuthAction(() {
      return _authService.signUp(
        name: name,
        email: email,
        password: password,
        interests: interests,
      );
    });
  }

  Future<void> logout() async {
    await _runAuthAction(_authService.logout);
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    try {
      _isSubmitting = true;
      _error = null;
      notifyListeners();

      await action();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
