import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/place.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Place place;
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      body: StreamBuilder<AppUser?>(
        stream: userService.currentUserStream(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.black),
                flexibleSpace: FlexibleSpaceBar(
                  background: place.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) =>
                              Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                        )
                      : Container(color: Colors.orange.shade100),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(place.category,
                            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),
                      const Text("About",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        place.description.isEmpty ? "No description provided." : place.description,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("${place.lat.toStringAsFixed(4)}, ${place.lng.toStringAsFixed(4)}",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
