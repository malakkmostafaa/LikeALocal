import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOffline = false;
  bool _hasCheckedConnection = false;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;
  bool get hasCheckedConnection => _hasCheckedConnection;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);

      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        _updateStatus(result);
      });
    } catch (e) {
      debugPrint('Connectivity error: $e');
      _isOffline = false;
      _hasCheckedConnection = true;
      notifyListeners();
    }
  }

  void _updateStatus(List<ConnectivityResult> result) {
    final offline = result.isEmpty ||
        result.every((item) => item == ConnectivityResult.none);

    if (_isOffline != offline || !_hasCheckedConnection) {
      _isOffline = offline;
      _hasCheckedConnection = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
