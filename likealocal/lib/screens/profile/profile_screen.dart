import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: StreamBuilder<AppUser?>(
        stream: userService.getCurrentUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 8),
                Text(user.email),
                const SizedBox(height: 20),
                Text("Interests:",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: user.preferences
                      .map((p) => Chip(label: Text(p)))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text("Pins: ${user.pinsCount}"),
                Text("Super User: ${user.isSuperUser ? "Yes" : "No"}"),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text("Logout"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
