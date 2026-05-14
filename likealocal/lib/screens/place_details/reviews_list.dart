import 'package:flutter/material.dart';
import '../../services/place_service.dart';
import 'review_item.dart';

class ReviewsList extends StatefulWidget {
  final String placeId;

  const ReviewsList({super.key, required this.placeId});

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  @override
  Widget build(BuildContext context) {
    final placeService = PlaceService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: placeService.getReviews(widget.placeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading reviews: ${snapshot.error}'),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet. Be the first to review!'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final reviewId = review['id'] as String;
            return ReviewItem(
              review: review,
              reviewId: reviewId,
              placeId: widget.placeId,
              onReviewUpdated: () => setState(() {}),
            );
          },
        );
      },
    );
  }
}
