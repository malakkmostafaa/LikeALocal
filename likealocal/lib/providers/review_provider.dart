import 'package:flutter/foundation.dart';

import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  final Map<String, List<Map<String, dynamic>>> _reviewsByPlace = {};

  List<UserReview> _myReviews = [];

  bool _isLoading = false;
  bool _isLoadingMyReviews = false;
  bool _loadedFromCache = false;

  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingMyReviews => _isLoadingMyReviews;
  bool get loadedFromCache => _loadedFromCache;
  String? get errorMessage => _errorMessage;

  List<UserReview> get myReviews => List.unmodifiable(_myReviews);

  List<Map<String, dynamic>> reviewsForPlace(String placeId) {
    return List.unmodifiable(_reviewsByPlace[placeId] ?? []);
  }

  Stream<List<Map<String, dynamic>>> watchPlaceReviews(String placeId) {
    return _reviewService.getReviewsForPlace(placeId).map((reviews) {
      _reviewsByPlace[placeId] = reviews;
      notifyListeners();
      return reviews;
    });
  }

  Future<void> loadMyReviews(String uid) async {
    if (uid.trim().isEmpty) return;

    _isLoadingMyReviews = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reviews = await _reviewService.getReviewsByUserAcrossPlaces(uid);

      _myReviews = reviews;
      _loadedFromCache = false;
    } catch (e) {
      _errorMessage = e.toString();

      try {
        final cachedReviews =
            await _reviewService.getReviewsByUserAcrossPlaces(uid);

        _myReviews = cachedReviews;
        _loadedFromCache = true;
      } catch (_) {
        // Keep old cached in-memory reviews if available.
      }
    } finally {
      _isLoadingMyReviews = false;
      notifyListeners();
    }
  }

  Future<void> addReview({
    required String placeId,
    required String text,
    required double rating,
    required bool isOffline,
  }) async {
    if (isOffline) {
      throw Exception('Reviews can be added when you are back online.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.addReviewToPlace(
        placeId: placeId,
        text: text,
        rating: rating,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editReview({
    required String placeId,
    required String reviewId,
    required String text,
    required double rating,
    required bool isOffline,
  }) async {
    if (isOffline) {
      throw Exception('Review changes are not available offline.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.editReview(
        placeId: placeId,
        reviewId: reviewId,
        text: text,
        rating: rating,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReview({
    required String placeId,
    required String reviewId,
    required bool isOffline,
  }) async {
    if (isOffline) {
      throw Exception('Review deletion is not available offline.');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.deleteReview(
        placeId: placeId,
        reviewId: reviewId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPlaceReviews(String placeId) {
    _reviewsByPlace.remove(placeId);
    notifyListeners();
  }

  void clearMyReviews() {
    _myReviews = [];
    _loadedFromCache = false;
    _errorMessage = null;
    notifyListeners();
  }
}
