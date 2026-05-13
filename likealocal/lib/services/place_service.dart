import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Place>> getPlaces() {
    return _firestore.collection('places').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Place.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
