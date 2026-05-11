import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../services/place_service.dart';
import '../../services/user_service.dart';
import '../../models/place.dart';
import '../../utils/categories.dart';
import 'location_picker_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final PlaceService _placeService = PlaceService();
  final UserService _userService = UserService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String _selectedCategory = Categories.all.first;
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  // Design constants
  static const Color backgroundColor = Color(0xFFF7F4EF);
  static const Color inputFillColor = Color(0xFFEDEDE6);
  static const Color mainColor = Color(0xFFD45A38);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _cleanupTempImages();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (images.isNotEmpty && mounted) {
        List<File> validFiles = [];

        for (final xFile in images) {
          try {
            final file = File(xFile.path);
            if (await file.exists() && await file.length() > 0) {
              final copiedFile = await _copyImageToAppDirectory(file);
              if (copiedFile != null) {
                validFiles.add(copiedFile);
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validFiles);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected ${validFiles.length} image(s)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to pick images';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant gallery access in app settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickSingleImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        if (await file.exists()) {
          final copiedFile = await _copyImageToAppDirectory(file);
          final fileToUse = copiedFile ?? file;

          setState(() {
            _selectedImages.add(fileToUse);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<File?> _copyImageToAppDirectory(File originalFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'temp_images'));

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalFile.path)}';
      final newPath = path.join(imagesDir.path, fileName);

      await originalFile.copy(newPath);
      final copiedFile = File(newPath);

      if (await copiedFile.exists() && await copiedFile.length() > 0) {
        return copiedFile;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickLocationFromMap() async {
    // Get current coordinates from text fields
    final currentLat = double.tryParse(_latController.text);
    final currentLng = double.tryParse(_lngController.text);

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: currentLat,
          initialLng: currentLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latController.text = result['lat']!.toStringAsFixed(6);
        _lngController.text = result['lng']!.toStringAsFixed(6);
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPlace() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Place name is required');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorDialog('Description is required');
      return;
    }

    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      _showErrorDialog('Please enter valid coordinates');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showErrorDialog('Please add at least one image');
      return;
    }

    for (final image in _selectedImages) {
      if (!await image.exists()) {
        _showErrorDialog('One or more selected images are no longer available');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final place = Place(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        images: [],
        location: GeoPoint(lat, lng),
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      await _placeService.addPlace(
        place,
        localImagePaths: _selectedImages.map((file) => file.path).toList(),
      );

      await _userService.updateUser(user.uid, {'placesAdded': FieldValue.increment(1)});

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Success!'),
            content: const Text('Place added successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to add place';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your authentication.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error. Please check your internet connection.';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'Storage quota exceeded. Please try with smaller images.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanupTempImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'temp_images'));

      if (await imagesDir.exists()) {
        final files = imagesDir.listSync();
        for (final file in files) {
          if (file is File) {
            try {
              await file.delete();
            } catch (e) {
              // Ignore cleanup errors
            }
          }
        }

        try {
          await imagesDir.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Add New Place',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.add_location_alt, color: mainColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Share a Hidden Gem',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Help others discover amazing places in your city',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Place Details Section
              _buildSectionTitle('Place Details'),
              const SizedBox(height: 16),

              // Name field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Place Name',
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description (what makes this place special?)',
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: Categories.all.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Location Section
              _buildSectionTitle('Location'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Latitude',
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lngController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Longitude',
                        filled: true,
                        fillColor: inputFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _pickLocationFromMap,
                  icon: Icon(Icons.map, color: mainColor),
                  label: const Text('Pick from Map'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Images Section
              _buildSectionTitle('Photos'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick Multiple'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickSingleImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Pick One'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tip: If multi-image selection fails, use "Pick One"',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),

              // Selected images preview
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      final imageFile = _selectedImages[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                imageFile,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Place',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}