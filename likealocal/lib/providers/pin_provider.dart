import 'package:flutter/foundation.dart';

import '../services/pin_service.dart';

class PinProvider extends ChangeNotifier {
  final PinService _pinService = PinService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get freePinLimit => PinService.freePinLimit;

  Stream<bool> isPinnedStream(String placeId) {
    return _pinService.isPinnedStream(placeId);
  }

  Stream<List<String>> pinnedPlaceIdsStream(String uid) {
    return _pinService.pinnedPlaceIdsStream(uid);
  }

  /// Toggles a pin and returns the new state. Rethrows
  /// [PinLimitReachedException] so the UI can show the upgrade dialog.
  Future<bool> togglePin(String placeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _pinService.togglePin(placeId);
    } on PinLimitReachedException {
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
