import 'package:cloud_firestore/cloud_firestore.dart';
import 'dish.dart';
import 'tip.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> images;
  final GeoPoint location;
  final String? createdBy;
  final DateTime? createdAt;
  final List<Tip> tips;
  final List<Dish> recommendedDishes;
  final double rating;
  final int reviewCount;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.images,
    required this.location,
    this.createdBy,
    this.createdAt,
    this.tips = const [],
    this.recommendedDishes = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  double get lat => location.latitude;
  double get lng => location.longitude;

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    final geo = map['location'] as GeoPoint?;

    final images = (map['images'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final tips = (map['tips'] as List<dynamic>?)
            ?.map((e) => Tip.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final dishes = (map['recommendedDishes'] as List<dynamic>?)
            ?.map((e) => Dish.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return Place(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      images: images,
      location: geo ?? GeoPoint(0, 0),
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      tips: tips,
      recommendedDishes: dishes,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'images': images,
      'location': location,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'tips': tips.map((t) => t.toMap()).toList(),
      'recommendedDishes': recommendedDishes.map((d) => d.toMap()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
