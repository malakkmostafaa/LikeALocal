import 'package:flutter/material.dart';
import '../../../services/place_service.dart';
import '../../../services/ai_service.dart';

class ReviewSummaryWidget extends StatefulWidget {
  final String placeId;

  const ReviewSummaryWidget({super.key, required this.placeId});

  @override
  State<ReviewSummaryWidget> createState() => _ReviewSummaryWidgetState();
}

class _ReviewSummaryWidgetState extends State<ReviewSummaryWidget> {
  final AiService _aiService = AiService();
  final PlaceService _placeService = PlaceService();

  String? _summary;
  bool _loading = false;
  bool _generated = false;

  Future<void> _generateSummary() async {
    setState(() => _loading = true);

    try {
      // Placeholder reviews for testing
      // Member 2 will replace this with real data later
      final reviewTexts = [
        'Amazing place, loved the atmosphere!',
        'Great food and friendly staff.',
        'A bit crowded but worth the visit.',
      ];

      final summary = await _aiService.summarizeReviews(reviewTexts);

      setState(() {
        _summary = summary;
        _loading = false;
        _generated = true;
      });
    } catch (e) {
      setState(() {
        _summary = 'Could not generate summary.';
        _loading = false;
        _generated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAECE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD85A30).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome,
                  color: Color(0xFFD85A30), size: 16),
              SizedBox(width: 6),
              Text('AI Summary',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFFD85A30))),
            ],
          ),
          const SizedBox(height: 10),
          if (!_generated && !_loading)
            GestureDetector(
              onTap: _generateSummary,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD85A30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('Summarize Reviews',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: Color(0xFFD85A30), strokeWidth: 2),
              ),
            ),
          if (_generated && !_loading && _summary != null)
            Text(_summary!,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5)),
        ],
      ),
    );
  }
}