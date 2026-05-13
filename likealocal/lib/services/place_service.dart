
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place.dart';
class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Place>> getPlaces() {
    return _firestore.collection('places').snapshots().map((snapshot) {
      debugPrint('Places snapshot count: ${snapshot.docs.length}');
      debugPrint('Firebase user: ${FirebaseAuth.instance.currentUser?.uid}');

      for (final doc in snapshot.docs) {
        debugPrint('Place doc: ${doc.id} => ${doc.data()}');
      }

      return snapshot.docs.map((doc) {
        return Place.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> seedTestPlaces() async {
    final places = [
      {
        'name': 'Khan El Khalili',
        'description': 'Historic market in Cairo',
        'category': 'Culture',
        'images': [],
        'location': const GeoPoint(30.0478, 31.2625),
        'rating': 4.7,
        'reviewCount': 10,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Test Cafe',
        'description': 'A nice cafe',
        'category': 'Cafe',
        'images': [],
        'location': const GeoPoint(30.0444, 31.2357),
        'rating': 4.5,
        'reviewCount': 10,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Test Park',
        'description': 'A big green park',
        'category': 'Park',
        'images': [],
        'location': const GeoPoint(30.0500, 31.2400),
        'rating': 4.8,
        'reviewCount': 5,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var place in places) {
      try {
        await _firestore.collection('places').add(place);
      } catch (e) {
        debugPrint('Seed failed: $e');
        rethrow;
      }
    }
  }
}
