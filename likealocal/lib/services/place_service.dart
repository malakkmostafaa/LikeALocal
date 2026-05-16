import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    List<String> localVideoPaths = const [],
  }) async {
    final data = place.toMap();
    data.remove('images');
    data.remove('videos');

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

    if (localVideoPaths.isNotEmpty) {
      final urls = await uploadPlaceVideos(docRef.id, localVideoPaths);
      if (urls.isNotEmpty) {
        await docRef.update({
          'videos': urls,
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

        if (fileSize > 50 * 1024 * 1024) {
          debugPrint('Media file too large: $filePath');
          continue;
        }

        final extension = _getMediaExtension(filePath);
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

  Future<List<String>> uploadPlaceVideos(
    String placeId,
    List<String> filePaths,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to upload videos.');
    }

    if (placeId.trim().isEmpty) {
      throw Exception('Place ID is missing. Cannot upload videos.');
    }

    final List<String> urls = [];

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);

        if (!await file.exists()) {
          throw Exception('Video file not found: $filePath');
        }

        final fileSize = await file.length();

        if (fileSize == 0) {
          throw Exception('Video file is empty.');
        }

        if (fileSize > 200 * 1024 * 1024) {
          throw Exception(
              'Video is too large. Please choose a video under 200MB.');
        }

        final extension = _getVideoExtension(filePath);
        final fileName = '${_uuid.v4()}.$extension';

        final ref = _storage
            .ref()
            .child('places')
            .child(placeId)
            .child('videos')
            .child(fileName);

        final metadata = SettableMetadata(
          contentType: _contentTypeFromExtension(extension),
          customMetadata: {
            'placeId': placeId,
            'uploadedBy': user.uid,
            'type': 'place_video',
          },
        );

        final snapshot = await ref.putFile(file, metadata);
        final url = await snapshot.ref.getDownloadURL();

        debugPrint('Video uploaded successfully: $url');

        urls.add(url);
      } on FirebaseException catch (e) {
        debugPrint('Firebase video upload error: ${e.code} - ${e.message}');
        throw Exception(e.message ?? 'Video upload failed.');
      } catch (e) {
        debugPrint('Error uploading video: $e');
        rethrow;
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
    List<String> newLocalVideoPaths = const [],
    List<String> removeVideoUrls = const [],
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

    if (removeVideoUrls.isNotEmpty) {
      for (final url in removeVideoUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (_) {}
      }
      await docRef.update({
        'videos': FieldValue.arrayRemove(removeVideoUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (newLocalVideoPaths.isNotEmpty) {
      final uploaded = await uploadPlaceVideos(place.id, newLocalVideoPaths);
      if (uploaded.isNotEmpty) {
        await docRef.update({
          'videos': FieldValue.arrayUnion(uploaded),
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

  Future<void> deletePlace(String placeId, String createdBy) async {
    final docRef = _firestore.collection('places').doc(placeId);

    final placeDoc = await docRef.get();

    if (!placeDoc.exists || placeDoc.data() == null) {
      throw Exception('Place not found.');
    }

    final placeData = placeDoc.data()!;

    final imageUrls = _parseStringList(placeData['images']);
    final videoUrls = _parseStringList(placeData['videos']);

    Future<void> deleteFileFromUrl(String url) async {
      if (url.trim().isEmpty) return;

      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
        debugPrint('Deleted storage file: $url');
      } on FirebaseException catch (e) {
        debugPrint(
          'Storage delete failed for URL: $url | ${e.code} - ${e.message}',
        );
        rethrow;
      } catch (e) {
        debugPrint('Storage delete failed for URL: $url | $e');
        rethrow;
      }
    }

    Future<void> deleteStorageFolder(String folderPath) async {
      try {
        final listRef = _storage.ref().child(folderPath);
        final listResult = await listRef.listAll();

        for (final item in listResult.items) {
          try {
            await item.delete();
            debugPrint('Deleted storage item: ${item.fullPath}');
          } on FirebaseException catch (e) {
            debugPrint(
              'Storage folder item delete failed: ${item.fullPath} | ${e.code} - ${e.message}',
            );
            rethrow;
          }
        }

        for (final prefix in listResult.prefixes) {
          await deleteStorageFolder(prefix.fullPath);
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'Storage folder cleanup failed for $folderPath | ${e.code} - ${e.message}',
        );
        rethrow;
      } catch (e) {
        debugPrint('Storage folder cleanup failed for $folderPath: $e');
        rethrow;
      }
    }

    // 1. Delete exact media URLs stored in Firestore.
    for (final url in imageUrls) {
      await deleteFileFromUrl(url);
    }

    for (final url in videoUrls) {
      await deleteFileFromUrl(url);
    }

    // 2. Backup cleanup in case there are orphaned files not stored in arrays.
    await deleteStorageFolder('places/$placeId/images');
    await deleteStorageFolder('places/$placeId/videos');

    final batch = _firestore.batch();

    final reviewsSnapshot = await docRef.collection('reviews').get();
    final userReviewOffsets = <String, int>{};

    for (final doc in reviewsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;

      if (userId != null && userId.isNotEmpty) {
        userReviewOffsets[userId] = (userReviewOffsets[userId] ?? 0) - 1;
      }

      batch.delete(doc.reference);
    }

    for (final entry in userReviewOffsets.entries) {
      batch.update(_firestore.collection('users').doc(entry.key), {
        'reviewsCount': FieldValue.increment(entry.value),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final dishesSnapshot = await docRef.collection('dishes').get();

    for (final doc in dishesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    if (createdBy.trim().isNotEmpty) {
      batch.update(_firestore.collection('users').doc(createdBy), {
        'placesAdded': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.delete(docRef);

    await batch.commit();
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return [];
  }

  String _getVideoExtension(String filePath) {
    final rawExt = filePath.split('.').last.split('?').first.toLowerCase();

    if (['mp4', 'mov', 'm4v'].contains(rawExt)) {
      return rawExt;
    }

    return 'mp4';
  }

  String _getMediaExtension(String filePath) {
    // Strip query strings that some temp paths contain
    final rawExt = filePath.split('.').last.split('?').first.toLowerCase();

    if (rawExt == 'jpg') return 'jpeg';

    if (['jpeg', 'png', 'webp'].contains(rawExt)) return rawExt;
    if (['mp4', 'mov', 'mkv', 'm4v', 'avi'].contains(rawExt)) return rawExt;

    return 'jpeg'; // image fallback
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
