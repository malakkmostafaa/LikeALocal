import 'package:flutter/material.dart';
import '../../services/place_service.dart';

class ReviewForm extends StatefulWidget {
  final String placeId;
  final VoidCallback? onReviewAdded;

  const ReviewForm({
    super.key,
    required this.placeId,
    this.onReviewAdded,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final PlaceService _placeService = PlaceService();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 5;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please write a comment');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _placeService.addReviewToPlace(widget.placeId, {
        'text': _commentController.text.trim(),
        'rating': _rating,
      });

      _commentController.clear();
      setState(() => _rating = 5);

      widget.onReviewAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to add review: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Rating selector
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

            const SizedBox(height: 16),

            // Comment field
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Your review',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}