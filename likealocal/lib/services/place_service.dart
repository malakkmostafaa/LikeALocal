import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
        if (!file.existsSync()) continue;

        final ext = path.split('.').last;
        final name = _uuid.v4();
        final ref = _storage.ref().child('places/$placeId/images/$name.$ext');

        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        // continue on error for individual files
        continue;
      }
    }

    return urls;
  }

  /// Create a new place document; optionally upload images first.
  /// If images are provided, they'll be uploaded and the place document
  /// will include the `images` array of download URLs.
  Future<DocumentReference> addPlace(Place place, {List<String> localImagePaths = const []}) async {
    // create a map without images (we'll add images after upload)
    final data = place.toMap();
    data.remove('images');

    final docRef = await _firestore.collection('places').add(data);

    try {
      if (localImagePaths.isNotEmpty) {
        final urls = await uploadPlaceImages(docRef.id, localImagePaths);
        if (urls.isNotEmpty) {
          await docRef.update({'images': urls});
        }
      }
    } catch (e) {
      // swallow upload errors but keep the place created
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

    await _firestore.collection('places').doc(placeId).collection('reviews').add(map);
  }

  /// Stream reviews for a place (reads from `places/{placeId}/reviews`).
  Stream<List<Map<String, dynamic>>> getReviews(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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
