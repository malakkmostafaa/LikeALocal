import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> trackSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase();

    if (_uid == null || cleanQuery.isEmpty || cleanQuery.length < 2) return;

    await _trackActivity(
      type: 'search',
      query: cleanQuery,
      points: 1,
    );

    await _updateProfile(
      query: cleanQuery,
      points: 1,
    );
  }

  Future<void> trackViewPlace(
    String placeId,
    String category, {
    int? budgetLevel,
  }) async {
    if (_uid == null || placeId.trim().isEmpty) return;

    final cleanBudget = _normalizeBudgetLevel(budgetLevel);

    await _trackActivity(
      type: 'view',
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 2,
    );

    await _updateProfile(
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 2,
    );
  }

  Future<void> trackLikePlace(
    String placeId,
    String category, {
    int? budgetLevel,
  }) async {
    if (_uid == null || placeId.trim().isEmpty) return;

    final cleanBudget = _normalizeBudgetLevel(budgetLevel);

    await _trackActivity(
      type: 'like',
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 3,
    );

    await _updateProfile(
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 3,
    );
  }

  Future<void> trackSavePlace(
    String placeId,
    String category, {
    int? budgetLevel,
  }) async {
    if (_uid == null || placeId.trim().isEmpty) return;

    final cleanBudget = _normalizeBudgetLevel(budgetLevel);

    await _trackActivity(
      type: 'save',
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 4,
    );

    await _updateProfile(
      placeId: placeId,
      category: category,
      budgetLevel: cleanBudget,
      points: 4,
    );
  }

  Future<Map<String, dynamic>> getRecommendationProfile() async {
    if (_uid == null) return {};

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('recommendationProfile')
        .doc('main')
        .get();

    return doc.data() ?? {};
  }

  int? _normalizeBudgetLevel(int? budgetLevel) {
    if (budgetLevel == null) return null;

    if (budgetLevel < 1) return 1;
    if (budgetLevel > 4) return 4;

    return budgetLevel;
  }

  Future<void> _trackActivity({
    required String type,
    String? placeId,
    String? category,
    int? budgetLevel,
    String? query,
    required int points,
  }) async {
    if (_uid == null) return;

    await _firestore.collection('users').doc(_uid).collection('activity').add({
      'type': type,
      'placeId': placeId,
      'category': category,
      'budgetLevel': budgetLevel,
      'query': query,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateProfile({
    String? placeId,
    String? category,
    int? budgetLevel,
    String? query,
    required int points,
  }) async {
    if (_uid == null) return;

    final profileRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('recommendationProfile')
        .doc('main');

    final cleanCategory = category?.trim();
    final cleanQuery = query?.trim().toLowerCase();
    final cleanBudget = _normalizeBudgetLevel(budgetLevel);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      updates['recentSearches'] = FieldValue.arrayUnion([cleanQuery]);
    }

    if (placeId != null && placeId.trim().isNotEmpty) {
      updates['viewHistory'] = FieldValue.arrayUnion([placeId]);
    }

    if (cleanCategory != null && cleanCategory.isNotEmpty) {
      updates['likedCategories'] = FieldValue.arrayUnion([cleanCategory]);
      updates['interactionScore.$cleanCategory'] = FieldValue.increment(points);
    }

    if (cleanBudget != null) {
      updates['likedBudgetLevels'] = FieldValue.arrayUnion([cleanBudget]);
      updates['budgetInteractionScore.$cleanBudget'] =
          FieldValue.increment(points);

      // This is the latest strong signal. Your Explore scoring can use it
      // together with user.priceRange.
      updates['preferredBudgetLevel'] = cleanBudget;
    }

    await profileRef.set(updates, SetOptions(merge: true));
  }
}
