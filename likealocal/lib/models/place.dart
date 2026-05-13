import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// Safely parse a dynamic value into List<String>.
  /// Handles null, List, String, and unexpected types.
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      if (value.trim().isEmpty) return [];
      return [value];
    }

    return [];
  }

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    debugPrint('Parsing place: $id => $map');

    // Safe GeoPoint parsing
    GeoPoint? geo;
    if (map['location'] is GeoPoint) {
      geo = map['location'] as GeoPoint;
    }

    // Safe image parsing — supports both 'images' (List) and 'imageUrl' (String)
    final parsedImages = _parseStringList(map['images'] ?? map['imageUrl']);

    // Safe tips parsing — handle String, List<Map>, or anything else
    List<Tip> parsedTips = [];
    if (map['tips'] is List) {
      parsedTips = (map['tips'] as List)
          .whereType<Map>()
          .map((e) => Tip.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Safe dishes parsing — handle String, List<Map>, or anything else
    List<Dish> parsedDishes = [];
    if (map['recommendedDishes'] is List) {
      parsedDishes = (map['recommendedDishes'] as List)
          .whereType<Map>()
          .map((e) => Dish.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return Place(
      id: id,
      name: map['name']?.toString() ?? 'Unknown',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      images: parsedImages,
      location: geo ?? const GeoPoint(0, 0),
      createdBy: map['createdBy']?.toString(),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      tips: parsedTips,
      recommendedDishes: parsedDishes,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      reviewCount: (map['reviewCount'] is num) ? (map['reviewCount'] as num).toInt() : 0,
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
