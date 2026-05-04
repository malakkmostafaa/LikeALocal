import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final double lat;
  final double lng;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.lat,
    required this.lng,
  });

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    final geo = map['location'] as GeoPoint?;

    return Place(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      lat: geo?.latitude ?? 0,
      lng: geo?.longitude ?? 0,
    );
  }
}
