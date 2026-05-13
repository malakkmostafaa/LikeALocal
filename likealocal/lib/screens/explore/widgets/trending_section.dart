import 'package:flutter/material.dart';
import '../../../models/place.dart';
import 'place_card.dart';

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
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Trending Places',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: trendingPlaces.length,
            itemBuilder: (context, index) {
              final place = trendingPlaces[index];
              return Container(
                width: 260,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: PlaceCard(
                  place: place,
                  distanceInMeters: getDistance(place),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Text(
            'All Places',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
