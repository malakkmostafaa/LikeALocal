import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      _error = null;
      notifyListeners();

      await _authService.login(
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      _error = null;
      notifyListeners();

      await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _error = null;
      notifyListeners();

      await _authService.logout();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
