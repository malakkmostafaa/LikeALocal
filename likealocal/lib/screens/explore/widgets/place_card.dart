import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../models/place.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final double? distanceInMeters;

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.distanceInMeters,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);
    const textColor = Color(0xFF1F1F28);
    const mutedText = Color(0xFF777777);

    final hasImage = place.images.isNotEmpty && place.images.first.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SizedBox(
                height: 190,
                child: hasImage
                    ? Hero(
                        tag: 'place_image_${place.id}',
                        child: CachedNetworkImage(
                          imageUrl: place.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: lightPrimary),
                          errorWidget: (_, __, ___) => _placeholder(),
                        ),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name.isEmpty ? 'Unknown Place' : place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE5A11A),
                        size: 21,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mutedText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _smallChip(
                        icon: Icons.category_rounded,
                        label:
                            place.category.isEmpty ? 'General' : place.category,
                        color: primaryColor,
                        bg: lightPrimary,
                      ),
                      _smallChip(
                        icon: Icons.rate_review_rounded,
                        label: '${place.reviewCount} reviews',
                        color: mutedText,
                        bg: Colors.grey.shade100,
                      ),
                      if (distanceInMeters != null)
                        _smallChip(
                          icon: Icons.location_on_rounded,
                          label: _formatDistance(distanceInMeters!),
                          color: mutedText,
                          bg: Colors.grey.shade100,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFFBE8DF),
      child: const Center(
        child: Icon(
          Icons.image_rounded,
          size: 60,
          color: Color(0xFFE26D45),
        ),
      ),
    );
  }

  Widget _smallChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
