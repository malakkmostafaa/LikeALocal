import 'package:flutter/material.dart';

import '../../services/place_service.dart';
import '../../models/dish.dart';
import '../../utils/categories.dart';

class DishesSection extends StatelessWidget {
  final String placeId;
  final String? category;

  const DishesSection({Key? key, required this.placeId, this.category})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Categories.isFoodCategory(category)) return const SizedBox.shrink();

    final service = PlaceService();

    return StreamBuilder<List<Dish>>(
      stream: service.getDishes(placeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final dishes = snapshot.data ?? [];
        if (dishes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Recommended dishes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dishes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = dishes[index];
                return ListTile(
                  title: Text(d.name),
                  subtitle: d.description != null ? Text(d.description!) : null,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
