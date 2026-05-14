import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/place.dart';

class TrendingStoryItem extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;

  const TrendingStoryItem({
    Key? key,
    required this.place,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (place.images.isNotEmpty) ? place.images.first : null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pinkAccent, width: 3),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Hero(
                      tag: 'place_image_${place.id}',
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                        errorWidget: (ctx, url, err) => const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.location_on, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
