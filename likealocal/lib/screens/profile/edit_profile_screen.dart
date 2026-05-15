import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';

import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';

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
  final StorageService _storageService = StorageService();

  late TextEditingController nameController;
  late TextEditingController bioController;

  bool isLoading = false;

  final List<String> allPreferences = [
    'Food',
    'Cafés',
    'Hidden Gems',
    'Art',
    'Nature',
    'Nightlife',
    'Shopping',
    'History',
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

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 900,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Future<String> _getUpdatedProfileImageUrl() async {
    if (_imageFile == null) {
      return widget.user.profileImageUrl;
    }

    final isOffline = context.read<ConnectivityProvider>().isOffline;

    if (isOffline) {
      throw Exception(
        'Profile image upload is not available offline. Please reconnect.',
      );
    }

    final imageUrl = await _storageService.uploadCurrentUserProfileImage(
      _imageFile!,
    );

    return imageUrl;
  }

  Future<void> saveProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (nameController.text.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (selectedPreferences.isEmpty) {
        throw Exception('Please select at least one interest');
      }

      final imageUrl = await _getUpdatedProfileImageUrl();

      await _userService.updateCurrentUser({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'preferences': selectedPreferences,
        'maxDistance': maxDistance,
        'priceRange': priceRange,
        'profileImageUrl': imageUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

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
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
                onTap: isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: primaryColor.withOpacity(0.12),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : widget.user.profileImageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    widget.user.profileImageUrl,
                                  )
                                : null,
                        child: _imageFile == null &&
                                widget.user.profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 56,
                                color: primaryColor,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton(
                onPressed: isLoading ? null : _pickImage,
                child: const Text(
                  'Change profile picture',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =====================
            // NAME
            // =====================
            const Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: nameController,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Your name',
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
              'Bio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: bioController,
              enabled: !isLoading,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell people a little about yourself',
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
              'Preferences',
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
                  onTap: isLoading
                      ? null
                      : () {
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
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                      ),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Distance: ${maxDistance.toInt()} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: maxDistance,
                    min: 1,
                    max: 100,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.15),
                    onChanged: isLoading
                        ? null
                        : (val) {
                            setState(() {
                              maxDistance = val;
                            });
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =====================
            // PRICE RANGE
            // =====================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    inactiveColor: primaryColor.withOpacity(0.15),
                    onChanged: isLoading
                        ? null
                        : (val) {
                            setState(() {
                              priceRange = val.toInt();
                            });
                          },
                  ),
                ],
              ),
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
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
