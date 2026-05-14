import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../models/dish.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Stream<List<Place>> getPlaces() {
    return _firestore
        .collection('places')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Place.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<Place?> getPlaceById(String placeId) {
    return _firestore.collection('places').doc(placeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Place.fromMap(doc.data()!, doc.id);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> addPlace(
    Place place, {
    List<String> localImagePaths = const [],
  }) async {
    final data = place.toMap();
    data.remove('images');

    data['rating'] = 0.0;
    data['reviewCount'] = 0;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('places').add(data);

    if (localImagePaths.isNotEmpty) {
      final urls = await uploadPlaceImages(docRef.id, localImagePaths);

      if (urls.isNotEmpty) {
        await docRef.update({
          'images': urls,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return docRef;
  }

  Future<List<String>> uploadPlaceImages(
    String placeId,
    List<String> filePaths,
  ) async {
    final List<String> urls = [];

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);

        if (!await file.exists()) {
          debugPrint('Image file does not exist: $filePath');
          continue;
        }

        final fileSize = await file.length();

        if (fileSize == 0) {
          debugPrint('Image file is empty: $filePath');
          continue;
        }

        if (fileSize > 10 * 1024 * 1024) {
          debugPrint('Image file too large: $filePath');
          continue;
        }

        final extension = _getImageExtension(filePath);
        final fileName = '${_uuid.v4()}.$extension';

        final ref = _storage
            .ref()
            .child('places')
            .child(placeId)
            .child('images')
            .child(fileName);

        final metadata = SettableMetadata(
          contentType: _contentTypeFromExtension(extension),
          customMetadata: {
            'placeId': placeId,
            'type': 'place_image',
          },
        );

        final snapshot = await ref.putFile(file, metadata);
        final url = await snapshot.ref.getDownloadURL();

        urls.add(url);
      } catch (e, stackTrace) {
        debugPrint('Error uploading image: $e');
        debugPrint('StackTrace: $stackTrace');
      }
    }

    return urls;
  }

  String _getImageExtension(String path) {
    final extension = path.split('.').last.toLowerCase();

    if (extension == 'jpg') return 'jpeg';

    if (['jpeg', 'png', 'webp'].contains(extension)) {
      return extension;
    }

    return 'jpeg';
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> addTipToPlace(
    String placeId, {
    required String text,
    String? authorId,
  }) async {
    final uid = authorId ?? _auth.currentUser?.uid;

    final map = {
      'text': text.trim(),
      if (uid != null) 'authorId': uid,
      'createdAt': Timestamp.now(),
    };

    await _firestore.collection('places').doc(placeId).update({
      'tips': FieldValue.arrayUnion([map]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDishToPlace(String placeId, Dish dish) async {
    final map = dish.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('places')
        .doc(placeId)
        .collection('dishes')
        .add(map);
  }

  Stream<List<Dish>> getDishes(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('dishes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Dish.fromMap(doc.data());
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getReviews(String placeId) {
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

  Future<void> addReviewToPlace(
    String placeId,
    Map<String, dynamic> review, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User must be authenticated to add a review.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();

    final userName = userData?['name'] ??
        _auth.currentUser?.displayName ??
        _auth.currentUser?.email ??
        'Local User';

    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc();

    await reviewRef.set({
      'userId': uid,
      'userName': userName,
      'text': review['text']?.toString().trim() ?? '',
      'rating': (review['rating'] as num?)?.toDouble() ?? 5.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(uid).set({
      'reviewsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await recalculatePlaceRating(placeId);
  }

  Future<void> editReview(
    String placeId,
    String reviewId,
    Map<String, dynamic> updatedReview, {
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User must be authenticated to edit a review.');
    }

    final reviewRef = _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .doc(reviewId);

    final reviewDoc = await reviewRef.get();

    if (!reviewDoc.exists) {
      throw Exception('Review not found.');
    }

    final reviewData = reviewDoc.data()!;

    if (reviewData['userId'] != uid) {
      throw Exception('You can only edit your own reviews.');
    }

    await reviewRef.update({
      'text': updatedReview['text']?.toString().trim() ?? '',
      'rating': (updatedReview['rating'] as num?)?.toDouble() ?? 5.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await recalculatePlaceRating(placeId);
  }

  Future<void> deleteReview(
    String placeId,
    String reviewId, {
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

    if (!reviewDoc.exists) {
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

  Future<void> updatePlace(
    Place place, {
    List<String> newLocalImagePaths = const [],
    List<String> removeImageUrls = const [],
  }) async {
    final docRef = _firestore.collection('places').doc(place.id);

    if (removeImageUrls.isNotEmpty) {
      for (final url in removeImageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (_) {}
      }

      await docRef.update({
        'images': FieldValue.arrayRemove(removeImageUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (newLocalImagePaths.isNotEmpty) {
      final uploaded = await uploadPlaceImages(place.id, newLocalImagePaths);

      if (uploaded.isNotEmpty) {
        await docRef.update({
          'images': FieldValue.arrayUnion(uploaded),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await docRef.update({
      'name': place.name,
      'description': place.description,
      'category': place.category,
      'location': GeoPoint(place.lat, place.lng),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlace(String placeId) async {
    final docRef = _firestore.collection('places').doc(placeId);

    try {
      final listRef = _storage.ref().child('places/$placeId/images');
      final listResult = await listRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {}

    Future<void> deleteSubcollection(String subcollectionName) async {
      final snapshot = await docRef.collection(subcollectionName).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }

    await deleteSubcollection('reviews');
    await deleteSubcollection('dishes');

    await docRef.delete();
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
