import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/review_provider.dart';
import 'review_item.dart';

class ReviewsList extends StatelessWidget {
  final String placeId;

  const ReviewsList({
    super.key,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<ReviewProvider>().watchPlaceReviews(placeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final cachedReviews =
              context.watch<ReviewProvider>().reviewsForPlace(placeId);

          if (cachedReviews.isNotEmpty) {
            return _ReviewsColumn(
              reviews: cachedReviews,
              placeId: placeId,
            );
          }

          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE26D45),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          final cachedReviews =
              context.watch<ReviewProvider>().reviewsForPlace(placeId);

          if (cachedReviews.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CachedNotice(),
                const SizedBox(height: 10),
                _ReviewsColumn(
                  reviews: cachedReviews,
                  placeId: placeId,
                ),
              ],
            );
          }

          return _ErrorCard(message: snapshot.error.toString());
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const _EmptyReviewsCard();
        }

        return _ReviewsColumn(
          reviews: reviews,
          placeId: placeId,
        );
      },
    );
  }
}

class _ReviewsColumn extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final String placeId;

  const _ReviewsColumn({
    required this.reviews,
    required this.placeId,
  });

  @override
  Widget build(BuildContext context) {
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
          reviewId: review['id']?.toString() ?? '',
          placeId: placeId,
        );
      },
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEDDD2)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Color(0xFFE26D45),
            size: 30,
          ),
          SizedBox(height: 8),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: Color(0xFF1F1F28),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first to review this place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A6D66),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedNotice extends StatelessWidget {
  const _CachedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            color: Color(0xFFE26D45),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing saved reviews.',
              style: TextStyle(
                color: Color(0xFF1F1F28),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEDDD2)),
      ),
      child: Text(
        'Could not load reviews: $message',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}
