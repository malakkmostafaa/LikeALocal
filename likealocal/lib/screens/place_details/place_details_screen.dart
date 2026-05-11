import 'package:flutter/material.dart';
import '../../models/place.dart';
import 'tips_list.dart';
import 'review_form.dart';
import 'reviews_list.dart';
import 'dishes_section.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late Place _currentPlace;

  @override
  void initState() {
    super.initState();
    _currentPlace = widget.place;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlace.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place images
            if (_currentPlace.images.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentPlace.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_currentPlace.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Place info
            Text(
              _currentPlace.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  _currentPlace.category,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text('${_currentPlace.rating} (${_currentPlace.reviewCount})'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(_currentPlace.description),

            const SizedBox(height: 24),

            // Tips section
            TipsList(place: _currentPlace),

            const SizedBox(height: 24),

            // Dishes section (if applicable)
            DishesSection(
              placeId: _currentPlace.id,
              category: _currentPlace.category,
            ),

            const SizedBox(height: 24),

            // Reviews section
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Review form
            ReviewForm(
              placeId: _currentPlace.id,
              onReviewAdded: () => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Reviews list
            ReviewsList(placeId: _currentPlace.id),
          ],
        ),
      ),
    );
  }
}