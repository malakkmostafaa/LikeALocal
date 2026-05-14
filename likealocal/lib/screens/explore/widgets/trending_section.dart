import 'package:flutter/material.dart';
import '../../../models/place.dart';
import '../../place/place_details_screen.dart';
import 'trending_story_item.dart';

class TrendingSection extends StatelessWidget {
  final List<Place> trendingPlaces;
  final double? Function(Place) getDistance;

  const TrendingSection({
    super.key,
    required this.trendingPlaces,
    required this.getDistance,
  });

  @override
  Widget build(BuildContext context) {
    if (trendingPlaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Trending Places',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F1F28),
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: trendingPlaces.length,
            itemBuilder: (context, index) {
              final place = trendingPlaces[index];
              return TrendingStoryItem(
                place: place,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailsScreen(
                        place: place,
                        distanceInMeters: getDistance(place),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Explore Feed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F1F28),
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
