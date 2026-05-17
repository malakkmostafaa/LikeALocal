import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'fcm_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<List<Map<String, dynamic>>> getReviewsForPlace(String placeId) {
    if (placeId.trim().isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          ...data,
          'id': doc.id,
          'createdAt': _dateFromValue(data['createdAt']),
          'updatedAt': _dateFromValue(data['updatedAt']),
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getReviewsForPlaceOnce(
    String placeId, {
    bool fromCache = false,
  }) async {
    if (placeId.trim().isEmpty) return [];

    final snapshot = await _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get(
          fromCache
              ? const GetOptions(source: Source.cache)
              : const GetOptions(source: Source.serverAndCache),
        );

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        ...data,
        'id': doc.id,
        'createdAt': _dateFromValue(data['createdAt']),
        'updatedAt': _dateFromValue(data['updatedAt']),
      };
    }).toList();
  }

  Future<List<UserReview>> getReviewsByUserAcrossPlaces(String uid) async {
    if (uid.trim().isEmpty) return [];

    QuerySnapshot<Map<String, dynamic>> placesSnapshot;

    try {
      placesSnapshot = await _firestore.collection('places').get(
            const GetOptions(source: Source.serverAndCache),
          );
    } catch (_) {
      placesSnapshot = await _firestore.collection('places').get(
            const GetOptions(source: Source.cache),
          );
    }

    final List<UserReview> reviews = [];

    for (final placeDoc in placesSnapshot.docs) {
      final placeData = placeDoc.data();

      final placeId = placeDoc.id;
      final placeName = placeData['name']?.toString() ?? 'Unknown place';

      QuerySnapshot<Map<String, dynamic>> reviewsSnapshot;

      try {
        reviewsSnapshot = await placeDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: uid)
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        reviewsSnapshot = await placeDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: uid)
            .get(const GetOptions(source: Source.cache));
      }

      for (final reviewDoc in reviewsSnapshot.docs) {
        final data = reviewDoc.data();

        reviews.add(
          UserReview(
            reviewId: reviewDoc.id,
            placeId: placeId,
            placeName: data['placeName']?.toString().trim().isNotEmpty == true
                ? data['placeName'].toString()
                : placeName,
            userId: data['userId']?.toString() ?? '',
            userName: data['userName']?.toString() ?? '',
            text: data['text']?.toString() ?? '',
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            createdAt: _dateFromValue(data['createdAt']),
            updatedAt: _dateFromValue(data['updatedAt']),
          ),
        );
      }
    }

    reviews.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return reviews;
  }

  Future<void> addReviewToPlace({
    required String placeId,
    required String text,
    required double rating,
    String? userId,
  }) async {
    final currentUser = _auth.currentUser;
    final uid = userId ?? currentUser?.uid;

    if (uid == null) {
      throw Exception('User must be authenticated to add a review.');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Review text cannot be empty.');
    }

    final cleanRating = rating.clamp(1.0, 5.0);

    final placeRef = _firestore.collection('places').doc(placeId);
    final userRef = _firestore.collection('users').doc(uid);

    final userDoc = await userRef.get();
    final userData = userDoc.data();

    final userName = userData?['name']?.toString().trim().isNotEmpty == true
        ? userData!['name'].toString().trim()
        : currentUser?.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName!.trim()
            : currentUser?.email ?? 'Local User';

    final placeDoc = await placeRef.get();

    if (!placeDoc.exists || placeDoc.data() == null) {
      throw Exception('Place not found.');
    }

    final placeData = placeDoc.data()!;
    final placeName = placeData['name']?.toString() ?? 'Unknown place';

    final reviewRef = placeRef.collection('reviews').doc();

    await reviewRef.set({
      'userId': uid,
      'userName': userName,
      'placeId': placeId,
      'placeName': placeName,
      'text': cleanText,
      'rating': cleanRating,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await userRef.set({
      'reviewsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await recalculatePlaceRating(placeId);

    // Notify the place owner
    final ownerId = placeData['createdBy']?.toString();
    if (ownerId != null && ownerId.isNotEmpty && ownerId != uid) {
      try {
        await _firestore.collection('notifications').add({
          'userId': ownerId,
          'title': 'New review on your place',
          'body': cleanText.length > 60
              ? '${cleanText.substring(0, 60)}…'
              : cleanText,
          'type': 'place',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('ReviewService: notification write failed: $e');
      }
    }

    if (ownerId != null && ownerId.isNotEmpty && ownerId != uid) {
      await FcmService.sendToUser(
        recipientUid: ownerId,
        title: 'New review on your place',
        body: cleanText.length > 60
            ? '${cleanText.substring(0, 60)}…'
            : cleanText,
        data: {'type': 'place', 'placeId': placeId},
      );
    }
  }

  Future<void> editReview({
    required String placeId,
    required String reviewId,
    required String text,
    required double rating,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User must be authenticated to edit a review.');
    }

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Review text cannot be empty.');
    }

    final cleanRating = rating.clamp(1.0, 5.0);

    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId);

    final reviewDoc = await reviewRef.get();

    if (!reviewDoc.exists || reviewDoc.data() == null) {
      throw Exception('Review not found.');
    }

    final reviewData = reviewDoc.data()!;

    if (reviewData['userId'] != uid) {
      throw Exception('You can only edit your own reviews.');
    }

    await reviewRef.update({
      'text': cleanText,
      'rating': cleanRating,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await recalculatePlaceRating(placeId);
  }

  Future<void> deleteReview({
    required String placeId,
    required String reviewId,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User must be authenticated to delete a review.');
    }

    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId);

    final reviewDoc = await reviewRef.get();

    if (!reviewDoc.exists || reviewDoc.data() == null) {
      throw Exception('Review not found.');
    }

    final reviewData = reviewDoc.data()!;

    if (reviewData['userId'] != uid) {
      throw Exception('You can only delete your own reviews.');
    }

    await reviewRef.delete();

    await _firestore.collection('users').doc(uid).set({
      'reviewsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await recalculatePlaceRating(placeId);
  }

  Future<void> recalculatePlaceRating(String placeId) async {
    final reviewsSnapshot = await _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .get();

    final reviews = reviewsSnapshot.docs;

    double totalRating = 0;

    for (final doc in reviews) {
      final data = doc.data();
      totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
    }

    final count = reviews.length;
    final average = count == 0 ? 0.0 : totalRating / count;

    await _firestore.collection('places').doc(placeId).update({
      'rating': double.parse(average.toStringAsFixed(1)),
      'reviewCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

class UserReview {
  final String reviewId;
  final String placeId;
  final String placeName;
  final String userId;
  final String userName;
  final String text;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserReview({
    required this.reviewId,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });
}
