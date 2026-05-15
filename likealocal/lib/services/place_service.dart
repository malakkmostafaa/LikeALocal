import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../models/dish.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  Future<List<Place>> getPlacesOnce({bool fromCache = false}) async {
    final snapshot = await _firestore
        .collection('places')
        .orderBy('createdAt', descending: true)
        .get(
          fromCache
              ? const GetOptions(source: Source.cache)
              : const GetOptions(source: Source.serverAndCache),
        );

    return snapshot.docs.map((doc) {
      return Place.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Stream<Place?> getPlaceById(String placeId) {
    return _firestore.collection('places').doc(placeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Place.fromMap(doc.data()!, doc.id);
    });
  }

  Future<Place?> getPlaceByIdOnce(String placeId,
      {bool fromCache = false}) async {
    if (placeId.trim().isEmpty) return null;

    final doc = await _firestore.collection('places').doc(placeId).get(
          fromCache
              ? const GetOptions(source: Source.cache)
              : const GetOptions(source: Source.serverAndCache),
        );

    if (!doc.exists || doc.data() == null) return null;

    return Place.fromMap(doc.data()!, doc.id);
  }

  Stream<List<Place>> getPlacesByUser(String uid) {
    return _firestore
        .collection('places')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final places = snapshot.docs.map((doc) {
        return Place.fromMap(doc.data(), doc.id);
      }).toList();

      places.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return places;
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

  Future<void> addTipToPlace(
    String placeId, {
    required String text,
    String? authorId,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('Tip text cannot be empty.');
    }

    final map = {
      'text': cleanText,
      if (authorId != null) 'authorId': authorId,
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
}
