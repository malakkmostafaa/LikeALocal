import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();

  late TextEditingController nameController;
  late TextEditingController bioController;

  bool isLoading = false;

  final List<String> allPreferences = [
    "Food",
    "Cafe",
    "Nature",
    "Shopping",
    "History",
    "Nightlife",
  ];

  late List<String> selectedPreferences;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user.name);

    bioController = TextEditingController(text: widget.user.bio);

    selectedPreferences = List.from(widget.user.preferences);
  }

  Future<void> saveProfile() async {
    try {
      print("🔥 SAVE STARTED");

      setState(() {
        isLoading = true;
      });

      if (nameController.text.trim().isEmpty) {
        throw Exception("Name cannot be empty");
      }

      await _userService.updateCurrentUser({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'preferences': selectedPreferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ FIRESTORE UPDATE FINISHED");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated"),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ ERROR:");
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================
            // NAME
            // =====================
            const Text(
              "Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =====================
            // BIO
            // =====================
            const Text(
              "Bio",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =====================
            // PREFERENCES
            // =====================
            const Text(
              "Preferences",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allPreferences.map((pref) {
                final isSelected = selectedPreferences.contains(pref);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedPreferences.remove(pref);
                      } else {
                        selectedPreferences.add(pref);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      pref,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // =====================
            // SAVE BUTTON
            // =====================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
