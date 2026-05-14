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
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);
    final imageUrl = (place.images.isNotEmpty) ? place.images.first : null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? Hero(
                        tag: 'place_image_${place.id}',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: lightPrimary),
                          errorWidget: (ctx, url, err) => Container(
                            color: lightPrimary,
                            child: const Icon(Icons.image, size: 30, color: primaryColor),
                          ),
                        ),
                      )
                    : Container(
                        color: lightPrimary,
                        child: const Icon(Icons.location_on, size: 30, color: primaryColor),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
