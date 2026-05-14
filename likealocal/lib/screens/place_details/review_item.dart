import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/place_service.dart';

class ReviewItem extends StatefulWidget {
  final Map<String, dynamic> review;
  final String reviewId;
  final String placeId;
  final VoidCallback? onReviewUpdated;

  const ReviewItem({
    super.key,
    required this.review,
    required this.reviewId,
    required this.placeId,
    this.onReviewUpdated,
  });

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> {
  final PlaceService _placeService = PlaceService();
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: widget.review['text'] ?? '');
    _rating = widget.review['rating'] ?? 5;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && widget.review['userId'] == currentUser.uid;
  }

  Future<void> _updateReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _placeService.editReview(widget.placeId, widget.reviewId, {
        'text': _commentController.text.trim(),
        'rating': _rating,
      });

      setState(() => _isEditing = false);
      widget.onReviewUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _placeService.deleteReview(widget.placeId, widget.reviewId);

      widget.onReviewUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.review['createdAt'] as DateTime?;
    final dateText = timestamp != null
        ? '${timestamp.day}/${timestamp.month}/${timestamp.year}'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and date
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index <
                              (_isEditing
                                  ? _rating
                                  : (widget.review['rating'] ?? 5))
                          ? Icons.star
                          : Icons.star_border,
                      size: 20,
                      color: Colors.amber,
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  dateText,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment
            if (_isEditing) ...[
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              // Rating selector for editing
              const Text('Rating:'),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
            ] else ...[
              Text(widget.review['text'] ?? ''),
            ],

            const SizedBox(height: 8),

            // Action buttons
            if (_isOwner) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isEditing) ...[
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateReview,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _deleteReview,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
