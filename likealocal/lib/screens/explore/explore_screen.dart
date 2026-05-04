import 'package:flutter/material.dart';
import '../../services/place_service.dart';
import '../../models/place.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PlaceService();

    return Scaffold(
      appBar: AppBar(title: const Text("Explore")),
      body: StreamBuilder<List<Place>>(
        stream: service.getPlaces(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No places yet"));
          }

          final places = snapshot.data!;

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];

              return ListTile(
                title: Text(place.name),
                subtitle: Text(place.category),
              );
            },
          );
        },
      ),
    );
  }
}
