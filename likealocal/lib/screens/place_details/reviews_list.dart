import 'package:flutter/material.dart';

import '../../services/place_service.dart';
import 'review_item.dart';

class ReviewsList extends StatelessWidget {
  final String placeId;

  const ReviewsList({
    super.key,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    final placeService = PlaceService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: placeService.getReviews(placeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error loading reviews: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No reviews yet. Be the first to review this place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final review = reviews[index];

            return ReviewItem(
              review: review,
              reviewId: review['id'] as String,
              placeId: placeId,
            );
          },
        );
      },
    );
  }
}
