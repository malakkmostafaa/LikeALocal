//placeholderuse the real one now 
import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../chat/widgets/review_summary_widget.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String category;
  final String description;

  const PlaceDetailsScreen({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: Text(placeName,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder image banner
            Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFFAECE7),
              child: const Center(
                child: Icon(Icons.image_outlined,
                    size: 60, color: Color(0xFFD85A30)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD85A30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(category,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),

                  // Place name
                  Text(placeName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Description
                  Text(description,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5)),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 12),

                  // AI Summary
                  ReviewSummaryWidget(placeId: placeId),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 12),

                  // Reviews section - placeholder
                  const Text('Reviews',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final names = ['Sarah', 'Omar', 'Youssef'];
                      final texts = [
                        'Amazing place, loved the atmosphere!',
                        'Great food and friendly staff.',
                        'A bit crowded but worth the visit.',
                      ];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFAECE7),
                          child: Text(names[i][0],
                              style: const TextStyle(
                                  color: Color(0xFFD85A30))),
                        ),
                        title: Text(names[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle: Text(texts[i],
                            style: const TextStyle(fontSize: 13)),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // Chat with contributor button at bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUid: 'test_contributor_uid',
                  otherName: 'Contributor',
                  placeId: placeId,
                  placeName: placeName,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C34),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Chat with Contributor',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}