import 'package:flutter/material.dart';
import '../../utils/seed_data.dart';

class AddPlaceScreen extends StatelessWidget {
  const AddPlaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('Developer Tools'),
        backgroundColor: const Color(0xFFF7F4EF),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await SeedService().seedAll();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seed data added successfully'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seed failed: $e'),
                    duration: const Duration(seconds: 6),
                  ),
                );
              }

              debugPrint('SEED ERROR: $e');
            }
          },
          child: const Text('Seed Test Data'),
        ),
      ),
    );
  }
}
