import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../providers/place_provider.dart';
import '../../services/user_service.dart';
import '../../providers/connectivity_provider.dart';
import '../../models/place.dart';
import '../../utils/categories.dart';
import 'location_picker_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  final Place? placeToEdit;

  const AddPlaceScreen({super.key, this.placeToEdit});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final UserService _userService = UserService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String _selectedCategory = Categories.all.first;

  final List<File> _selectedImages = [];
  List<String> _existingImages = [];
  final List<String> _removedImages = [];

  final List<File> _selectedVideos = [];
  List<String> _existingVideos = [];
  final List<String> _removedVideos = [];

  bool _isLoading = false;

  // Design constants
  static const Color backgroundColor = Color(0xFFF7F4EF);
  static const Color inputFillColor = Color(0xFFEDEDE6);
  static const Color mainColor = Color(0xFFD45A38);

  bool get isEditing => widget.placeToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.placeToEdit!;
      _nameController.text = p.name;
      _descriptionController.text = p.description;
      _latController.text = p.lat.toString();
      _lngController.text = p.lng.toString();
      if (Categories.all.contains(p.category)) {
        _selectedCategory = p.category;
      }
      _existingImages = List<String>.from(p.images);
      _existingVideos = List<String>.from(p.videos);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _cleanupTempMedia();
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
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to pick images');
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
          setState(() {
            _selectedImages.add(copiedFile ?? file);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to pick image');
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedImages.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  Future<void> _pickVideos() async {
    if (_isLoading) return;

    try {
      final isOffline = context.read<ConnectivityProvider>().isOffline;

      if (isOffline) {
        _showErrorDialog(
          'Video uploads are not available offline. Please reconnect and try again.',
        );
        return;
      }

      final ImagePicker picker = ImagePicker();

      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (!mounted || video == null) return;

      final file = File(video.path);

      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorDialog('Selected video file was not found.');
        return;
      }

      final fileSize = await file.length();

      if (!mounted) return;

      if (fileSize == 0) {
        _showErrorDialog('Selected video file is empty.');
        return;
      }

      if (fileSize > 200 * 1024 * 1024) {
        _showErrorDialog(
            'Video is too large. Please choose a video under 200MB.');
        return;
      }

      final copied = await _copyVideoToAppDirectory(file);

      if (!mounted) return;

      if (copied == null) {
        _showErrorDialog('Could not prepare the selected video for upload.');
        return;
      }

      setState(() {
        _selectedVideos.add(copied);
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to pick video: $e');
    }
  }

  Future<File?> _copyVideoToAppDirectory(File originalFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'temp_videos'));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      final rawExt =
          originalFile.path.split('.').last.split('?').first.toLowerCase();
      final extension =
          ['mp4', 'mov', 'mkv', 'm4v', 'avi'].contains(rawExt) ? rawExt : 'mp4';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final newPath = path.join(videosDir.path, fileName);
      await originalFile.copy(newPath);
      final copied = File(newPath);
      if (await copied.exists() && await copied.length() > 0) return copied;
      return null;
    } catch (e) {
      debugPrint('Failed to copy video: $e');
      return null;
    }
  }

  void _removeNewVideo(int index) {
    setState(() => _selectedVideos.removeAt(index));
  }

  void _removeExistingVideo(int index) {
    setState(() {
      _removedVideos.add(_existingVideos[index]);
      _existingVideos.removeAt(index);
    });
  }

  Future<File?> _copyImageToAppDirectory(File originalFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'temp_images'));

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalFile.path)}';
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
    if (_isLoading) return;

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

    final provider = context.read<PlaceProvider>();
    final isOffline = context.read<ConnectivityProvider>().isOffline;

    final hasMediaChanges = _selectedImages.isNotEmpty ||
        _selectedVideos.isNotEmpty ||
        _removedImages.isNotEmpty ||
        _removedVideos.isNotEmpty;

    if (isOffline && hasMediaChanges) {
      _showErrorDialog(
        'Media uploads are not available offline. Please reconnect and try again.',
      );
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (isEditing) {
        final updatedPlace = Place(
          id: widget.placeToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          images: _existingImages,
          videos: _existingVideos,
          location: GeoPoint(lat, lng),
          createdBy: widget.placeToEdit!.createdBy,
          createdAt: widget.placeToEdit!.createdAt,
          recommendedDishes: widget.placeToEdit!.recommendedDishes,
          rating: widget.placeToEdit!.rating,
          reviewCount: widget.placeToEdit!.reviewCount,
          tips: widget.placeToEdit!.tips,
        );

        await provider.updatePlace(
          updatedPlace,
          newLocalImagePaths: _selectedImages.map((f) => f.path).toList(),
          removeImageUrls: _removedImages,
          newLocalVideoPaths: _selectedVideos.map((f) => f.path).toList(),
          removeVideoUrls: _removedVideos,
          isOffline: isOffline,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place updated successfully')),
        );

        Navigator.of(context).pop();
      } else {
        final place = Place(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          images: const [],
          videos: const [],
          location: GeoPoint(lat, lng),
          createdBy: user.uid,
          createdAt: DateTime.now(),
        );

        await provider.addPlace(
          place,
          localImagePaths: _selectedImages.map((file) => file.path).toList(),
          localVideoPaths: _selectedVideos.map((file) => file.path).toList(),
          isOffline: isOffline,
        );

        await _userService.updateUser(
          user.uid,
          {
            'placesAdded': FieldValue.increment(1),
          },
        );

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Place added successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        setState(() {
          _nameController.clear();
          _descriptionController.clear();
          _latController.clear();
          _lngController.clear();
          _selectedImages.clear();
          _selectedVideos.clear();
          _removedImages.clear();
          _removedVideos.clear();
          _existingImages.clear();
          _existingVideos.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Operation failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanupTempMedia() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final tempDirs = [
        Directory(path.join(directory.path, 'temp_images')),
        Directory(path.join(directory.path, 'temp_videos')),
      ];

      for (final dir in tempDirs) {
        if (await dir.exists()) {
          final files = dir.listSync();

          for (final file in files) {
            if (file is File) {
              try {
                await file.delete();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Place' : 'Add New Place',
          style: const TextStyle(
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
              Row(
                children: [
                  Icon(
                      isEditing
                          ? Icons.edit_location_alt_rounded
                          : Icons.add_location_alt,
                      color: mainColor,
                      size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Update Details' : 'Share a Hidden Gem',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Place Details'),
              const SizedBox(height: 16),
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
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description',
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  icon: const Icon(Icons.map, color: mainColor),
                  label: const Text('Pick from Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mainColor,
                    side: const BorderSide(color: mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
                  )),
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
                  )),
                ],
              ),
              if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Images',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        return _buildImageThumbnail(
                          imageWidget: Image.network(url,
                              fit: BoxFit.cover, width: 100, height: 100),
                          onRemove: () => _removeExistingImage(index),
                        );
                      }),
                      ..._selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return _buildImageThumbnail(
                          imageWidget: Image.file(file,
                              fit: BoxFit.cover, width: 100, height: 100),
                          onRemove: () => _removeNewImage(index),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('Videos'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _pickVideos,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Pick a Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Max 5 min · mp4, mov supported',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              if (_existingVideos.isNotEmpty || _selectedVideos.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingVideos.asMap().entries.map((entry) {
                        return _buildVideoThumbnail(
                          label: 'Video ${entry.key + 1}',
                          onRemove: () => _removeExistingVideo(entry.key),
                        );
                      }),
                      ..._selectedVideos.asMap().entries.map((entry) {
                        return _buildVideoThumbnail(
                          label: entry.value.path.split('/').last,
                          onRemove: () => _removeNewVideo(entry.key),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Add Place',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildImageThumbnail(
      {required Widget imageWidget, required VoidCallback onRemove}) {
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
            child: imageWidget,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
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
  }

  Widget _buildVideoThumbnail(
      {required String label, required VoidCallback onRemove}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_rounded,
                    color: Colors.white70, size: 32),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
