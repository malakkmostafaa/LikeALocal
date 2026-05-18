import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';
import '../../providers/review_provider.dart';

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
  bool _isEditing = false;

  late TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();

    _commentController = TextEditingController(
      text: widget.review['text']?.toString() ?? '',
    );

    _rating = ((widget.review['rating'] as num?)?.toInt() ?? 5).clamp(1, 5);
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
    final text = _commentController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review.write'.tr())),
      );
      return;
    }

    final isOffline = context.read<ConnectivityProvider>().isOffline;

    try {
      await context.read<ReviewProvider>().editReview(
            placeId: widget.placeId,
            reviewId: widget.reviewId,
            text: text,
            rating: _rating.toDouble(),
            isOffline: isOffline,
          );

      if (!mounted) return;

      setState(() => _isEditing = false);

      widget.onReviewUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review.updated'.tr())),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBF7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('review.delete_title'.tr()),
          content: Text('review.delete_confirm'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'common.delete'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final isOffline = context.read<ConnectivityProvider>().isOffline;

    try {
      await context.read<ReviewProvider>().deleteReview(
            placeId: widget.placeId,
            reviewId: widget.reviewId,
            isOffline: isOffline,
          );

      if (!mounted) return;

      widget.onReviewUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review.deleted'.tr())),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _dateText(dynamic date) {
    if (date is! DateTime) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);
    const mutedText = Color(0xFF7A6D66);
    const cardColor = Color(0xFFFFFBF7);
    const borderColor = Color(0xFFEEDDD2);
    const textColor = Color(0xFF1F1F28);

    final reviewProvider = context.watch<ReviewProvider>();
    final isLoading = reviewProvider.isLoading;

    final userName = widget.review['userName']?.toString() ?? 'Local User';
    final dateText = _dateText(widget.review['createdAt']);
    final displayRating = _isEditing
        ? _rating
        : ((widget.review['rating'] as num?)?.toInt() ?? 5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.018),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFFE6D8),
                child: Text(
                  userName.isEmpty ? '?' : userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < displayRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: const Color(0xFFE5A11A),
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 10),
          if (_isEditing) ...[
            TextField(
              controller: _commentController,
              enabled: !isLoading,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFF3EC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFE5A11A),
                  ),
                );
              }),
            ),
          ] else
            Text(
              widget.review['text']?.toString() ?? '',
              style: const TextStyle(
                color: textColor,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_isOwner) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isEditing) ...[
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _isEditing = false;
                              _commentController.text =
                                  widget.review['text']?.toString() ?? '';
                              _rating =
                                  ((widget.review['rating'] as num?)?.toInt() ??
                                          5)
                                      .clamp(1, 5);
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : _updateReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('common.save'.tr()),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('common.edit'.tr()),
                  ),
                  TextButton.icon(
                    onPressed: isLoading ? null : _deleteReview,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
