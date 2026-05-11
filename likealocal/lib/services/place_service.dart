import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../models/tip.dart';
import '../models/dish.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Stream<List<Place>> getPlaces() {
    return _firestore.collection('places').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Place.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Upload multiple local image file paths to Firebase Storage for a place
  /// Returns list of download URLs.
  Future<List<String>> uploadPlaceImages(String placeId, List<String> filePaths) async {
    final List<String> urls = [];

    for (final path in filePaths) {
      try {
        final file = File(path);

        // Check if file exists
        if (!await file.exists()) {
          debugPrint('Image file does not exist: $path');
          continue;
        }

        // Validate file size (max 10MB)
        final fileSize = await file.length();
        if (fileSize == 0) {
          debugPrint('Image file is empty: $path');
          continue;
        }
        if (fileSize > 10 * 1024 * 1024) {
          debugPrint('Image file too large: $path (${fileSize} bytes)');
          continue;
        }

        // Determine file extension
        final ext = _getImageExtension(path);
        if (ext == null) {
          debugPrint('Could not determine image extension for: $path');
          continue;
        }

        final name = _uuid.v4();
        final ref = _storage.ref('mobiledev2026').child('places/$placeId/images/$name.$ext');

        debugPrint('Starting upload for: $path');
        debugPrint('Upload path: ${ref.fullPath}');

        // Upload file with minimal metadata
        try {
          final uploadTask = ref.putFile(file);
          
          // Wait for upload to complete
          await uploadTask;
          
          debugPrint('File uploaded successfully');

          // Get download URL
          final url = await ref.getDownloadURL();
          urls.add(url);
          debugPrint('Download URL obtained: $url');
        } on FirebaseException catch (e) {
          debugPrint('Firebase error: Code=${e.code}, Message=${e.message}');
          debugPrint('Plugin=${e.plugin}');
          continue;
        }
      } catch (e, stackTrace) {
        debugPrint('Error uploading image: $e');
        debugPrint('StackTrace: $stackTrace');
        continue;
      }
    }

    debugPrint('Upload complete. Successfully uploaded ${urls.length} of ${filePaths.length} images');
    return urls;
  }

  /// Determine image extension from file path
  String? _getImageExtension(String path) {
    final pathExt = path.split('.').last.toLowerCase();

    // Map common extensions
    if (pathExt == 'jpg') return 'jpeg';
    if (['jpeg', 'png', 'gif', 'webp'].contains(pathExt)) {
      return pathExt;
    }

    // Default fallback
    return 'jpeg';
  }

  /// Create a new place document; optionally upload images first.
  /// If images are provided, they'll be uploaded and the place document
  /// will include the `images` array of download URLs.
  Future<DocumentReference> addPlace(Place place, {List<String> localImagePaths = const []}) async {
    // Validate inputs
    if (localImagePaths.isNotEmpty) {
      debugPrint('Starting place creation with ${localImagePaths.length} images to upload');
    }

    // Create a map without images (we'll add images after upload)
    final data = place.toMap();
    data.remove('images');

    // Add place document first
    final docRef = await _firestore.collection('places').add(data);
    debugPrint('Place document created with ID: ${docRef.id}');

    // Upload images if provided
    if (localImagePaths.isNotEmpty) {
      try {
        debugPrint('Starting image upload for place ${docRef.id}');
        final urls = await uploadPlaceImages(docRef.id, localImagePaths);

        if (urls.isNotEmpty) {
          await docRef.update({'images': urls});
          debugPrint('Successfully updated place ${docRef.id} with ${urls.length} image URLs');
        } else {
          debugPrint('No images were successfully uploaded for place ${docRef.id}');
        }
      } catch (e, stackTrace) {
        debugPrint('Error during image upload for place ${docRef.id}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Don't fail the entire operation if image upload fails
        // The place document is already created successfully
      }
    }

    return docRef;
  }

  /// Add a tip to an existing place as an array element.
  Future<void> addTipToPlace(String placeId, {required String text, String? authorId}) async {
    final map = {
      'text': text,
      if (authorId != null) 'authorId': authorId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('places').doc(placeId).update({
      'tips': FieldValue.arrayUnion([map])
    });
  }

  /// Add a recommended dish to a place (array field). Use UI guards
  /// Add a recommended dish to a place as a subcollection document.
  /// Use UI guards to ensure dishes are only suggested for food-related categories.
  Future<void> addDishToPlace(String placeId, Dish dish) async {
    final map = dish.toMap();
    // add createdAt server timestamp for consistency
    map['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('places').doc(placeId).collection('dishes').add(map);
  }

  /// Stream dishes for a place (reads from `places/{placeId}/dishes`).
  Stream<List<Dish>> getDishes(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('dishes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Dish.fromMap(d.data())).toList());
  }

  /// Add a review to a place (writes a document to `places/{placeId}/reviews`).
  /// Automatically increments reviewCount in place and user's reviewsCount.
  Future<void> addReviewToPlace(String placeId, Map<String, dynamic> review, {String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'User must be authenticated to add a review',
      );
    }

    final map = Map<String, dynamic>.from(review);
    // Ensure the review is associated with the creating user's id (required by rules)
    map['userId'] = uid;
    map['createdAt'] = FieldValue.serverTimestamp();

    // Use batch write to ensure atomicity
    final batch = _firestore.batch();

    // Add the review document
    final reviewRef = _firestore.collection('places').doc(placeId).collection('reviews').doc();
    batch.set(reviewRef, map);

    // Increment review count in place document
    final placeRef = _firestore.collection('places').doc(placeId);
    batch.update(placeRef, {'reviewCount': FieldValue.increment(1)});

    // Increment review count in user document
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {'reviewsCount': FieldValue.increment(1)});

    await batch.commit();
  }

  /// Stream reviews for a place (reads from `places/{placeId}/reviews`).
  Stream<List<Map<String, dynamic>>> getReviews(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {
          ...d.data(),
          'id': d.id, // Include the document ID
        }).toList());
  }

  /// Edit an existing review (only the review owner can edit).
  Future<void> editReview(String placeId, String reviewId, Map<String, dynamic> updatedReview, {String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'User must be authenticated to edit a review',
      );
    }

    final reviewRef = _firestore.collection('places').doc(placeId).collection('reviews').doc(reviewId);

    // First, check if the user owns this review
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'Review not found',
      );
    }

    final reviewData = reviewDoc.data()!;
    if (reviewData['userId'] != uid) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'You can only edit your own reviews',
      );
    }

    // Update the review with new data and updatedAt timestamp
    final map = Map<String, dynamic>.from(updatedReview);
    map['updatedAt'] = FieldValue.serverTimestamp();

    await reviewRef.update(map);
  }

  /// Delete a review (only the review owner can delete).
  /// Automatically decrements reviewCount in place and user's reviewsCount.
  Future<void> deleteReview(String placeId, String reviewId, {String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'User must be authenticated to delete a review',
      );
    }

    final reviewRef = _firestore.collection('places').doc(placeId).collection('reviews').doc(reviewId);

    // First, check if the user owns this review
    final reviewDoc = await reviewRef.get();
    if (!reviewDoc.exists) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'Review not found',
      );
    }

    final reviewData = reviewDoc.data()!;
    if (reviewData['userId'] != uid) {
      throw FirebaseException(
        plugin: 'PlaceService',
        message: 'You can only delete your own reviews',
      );
    }

    // Use batch write to ensure atomicity
    final batch = _firestore.batch();

    // Delete the review document
    batch.delete(reviewRef);

    // Decrement review count in place document
    final placeRef = _firestore.collection('places').doc(placeId);
    batch.update(placeRef, {'reviewCount': FieldValue.increment(-1)});

    // Decrement review count in user document
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {'reviewsCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  /// Update basic place fields (name, description, category, location).
  /// Optionally upload new local images and/or remove specific image URLs.
  Future<void> updatePlace(
    Place place, {
    List<String> newLocalImagePaths = const [],
    List<String> removeImageUrls = const [],
  }) async {
    final docRef = _firestore.collection('places').doc(place.id);

    // Remove images requested for deletion
    if (removeImageUrls.isNotEmpty) {
      for (final url in removeImageUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // ignore delete errors for individual files
        }
      }

      try {
        await docRef.update({
          'images': FieldValue.arrayRemove(removeImageUrls),
        });
      } catch (e) {
        // ignore
      }
    }

    // Upload new local images
    if (newLocalImagePaths.isNotEmpty) {
      final uploaded = await uploadPlaceImages(place.id, newLocalImagePaths);
      if (uploaded.isNotEmpty) {
        await docRef.update({'images': FieldValue.arrayUnion(uploaded)});
      }
    }

    // Update basic fields only
    final data = {
      'name': place.name,
      'description': place.description,
      'category': place.category,
      'location': GeoPoint(place.lat, place.lng),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(data);
  }

  /// Delete a place document and its known subcollections and storage images.
  Future<void> deletePlace(String placeId) async {
    final docRef = _firestore.collection('places').doc(placeId);

    // Delete storage images under places/{placeId}/images
    try {
      final listRef = _storage.ref().child('places/$placeId/images');
      final listResult = await listRef.listAll();
      for (final item in listResult.items) {
        try {
          await item.delete();
        } catch (e) {
          // ignore per-item errors
        }
      }
    } catch (e) {
      // ignore storage listing errors
    }

     // Delete common subcollections (reviews) if present
     Future<void> _deleteSubcollection(String path) async {
       final col = docRef.collection(path);
       final snap = await col.get();
       final batch = _firestore.batch();
       for (final d in snap.docs) {
         batch.delete(d.reference);
       }
       await batch.commit();
     }

     try {
       await _deleteSubcollection('reviews');
     } catch (_) {}

    // Finally delete the place document
    await docRef.delete();
  }
}
