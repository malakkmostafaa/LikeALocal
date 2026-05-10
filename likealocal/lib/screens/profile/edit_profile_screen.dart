import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  double maxDistance = 10.0;
  int priceRange = 1;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user.name);

    bioController = TextEditingController(text: widget.user.bio);

    selectedPreferences = List.from(widget.user.preferences);
    maxDistance = widget.user.maxDistance;
    priceRange = widget.user.priceRange;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return widget.user.profileImageUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profiles')
          .child('${widget.user.uid}.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return widget.user.profileImageUrl;
    }
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

      final imageUrl = await _uploadImage();

      await _userService.updateCurrentUser({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'preferences': selectedPreferences,
        'maxDistance': maxDistance,
        'priceRange': priceRange,
        'profileImageUrl': imageUrl ?? '',
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
            // PROFILE PICTURE
            // =====================
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (widget.user.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                              : null),
                      child: _imageFile == null && widget.user.profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

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

            const SizedBox(height: 24),

            // =====================
            // MAX DISTANCE
            // =====================
            Text(
              "Max Distance: ${maxDistance.toInt()} km",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: maxDistance,
              min: 1,
              max: 100,
              activeColor: primaryColor,
              onChanged: (val) {
                setState(() {
                  maxDistance = val;
                });
              },
            ),

            const SizedBox(height: 14),

            // =====================
            // PRICE RANGE
            // =====================
            Text(
              "Price Range: ${List.filled(priceRange, '\$').join('')}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: priceRange.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              activeColor: primaryColor,
              onChanged: (val) {
                setState(() {
                  priceRange = val.toInt();
                });
              },
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
