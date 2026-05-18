import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/dish.dart';
import '../../models/place.dart';
import '../../models/tip.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/place_provider.dart';
import '../../services/user_service.dart';
import '../../utils/categories.dart';
import 'add_place_steps.dart';
import 'add_place_widgets.dart';
import 'location_picker_screen.dart';

class AddPlaceScreen extends StatefulWidget {
  final Place? placeToEdit;

  const AddPlaceScreen({
    super.key,
    this.placeToEdit,
  });

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final UserService _userService = UserService();
  final PageController _pageController = PageController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  final List<TextEditingController> tipControllers = [];
  final List<DishDraftControllers> dishControllers = [];

  String selectedCategory = Categories.all.first;
  int selectedBudgetLevel = 1;
  int currentStep = 0;
  bool isLoading = false;

  final List<File> selectedImages = [];
  List<String> existingImages = [];
  final List<String> removedImages = [];

  final List<File> selectedVideos = [];
  List<String> existingVideos = [];
  final List<String> removedVideos = [];

  bool get isEditing => widget.placeToEdit != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final p = widget.placeToEdit!;

      nameController.text = p.name;
      descriptionController.text = p.description;
      latController.text = p.lat.toString();
      lngController.text = p.lng.toString();

      if (Categories.all.contains(p.category)) {
        selectedCategory = p.category;
      }
      selectedBudgetLevel = p.budgetLevel;
      existingImages = List<String>.from(p.images);
      existingVideos = List<String>.from(p.videos);

      for (final tip in p.tips) {
        tipControllers.add(TextEditingController(text: tip.text));
      }

      for (final dish in p.recommendedDishes) {
        dishControllers.add(
          DishDraftControllers(
            name: TextEditingController(text: dish.name),
            description: TextEditingController(text: dish.description ?? ''),
          ),
        );
      }
    }

    if (tipControllers.isEmpty) {
      tipControllers.add(TextEditingController());
    }

    if (dishControllers.isEmpty) {
      dishControllers.add(
        DishDraftControllers(
          name: TextEditingController(),
          description: TextEditingController(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    nameController.dispose();
    descriptionController.dispose();
    latController.dispose();
    lngController.dispose();

    for (final controller in tipControllers) {
      controller.dispose();
    }

    for (final dish in dishControllers) {
      dish.dispose();
    }

    _cleanupTempMedia();

    super.dispose();
  }

  Future<void> goToStep(int step) async {
    if (step < 0 || step > 2) return;

    if (step > currentStep && !validateCurrentStep()) {
      return;
    }

    setState(() => currentStep = step);

    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool validateCurrentStep() {
    if (currentStep == 0) {
      if (nameController.text.trim().isEmpty) {
        showErrorDialog('add_place.name_required'.tr());
        return false;
      }

      if (descriptionController.text.trim().isEmpty) {
        showErrorDialog('add_place.description_required'.tr());
        return false;
      }

      final lat = double.tryParse(latController.text);
      final lng = double.tryParse(lngController.text);

      if (lat == null || lng == null) {
        showErrorDialog('add_place.invalid_coords'.tr());
        return false;
      }
    }

    return true;
  }

  Future<void> pickLocationFromMap() async {
    final currentLat = double.tryParse(latController.text);
    final currentLng = double.tryParse(lngController.text);

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: currentLat,
          initialLng: currentLng,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      latController.text = result['lat']!.toStringAsFixed(6);
      lngController.text = result['lng']!.toStringAsFixed(6);
    });
  }

  Future<void> pickImages() async {
    if (isLoading) return;

    try {
      final picker = ImagePicker();

      final images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (!mounted || images.isEmpty) return;

      final validFiles = <File>[];

      for (final xFile in images) {
        final file = File(xFile.path);

        if (await file.exists() && await file.length() > 0) {
          final copiedFile = await copyImageToAppDirectory(file);

          if (copiedFile != null) {
            validFiles.add(copiedFile);
          }
        }
      }

      if (!mounted) return;

      if (validFiles.isNotEmpty) {
        setState(() {
          selectedImages.addAll(validFiles);
        });
      }
    } catch (_) {
      if (!mounted) return;
      showErrorDialog('add_place.multi_pick_failed'.tr());
    }
  }

  Future<void> pickSingleImage() async {
    if (isLoading) return;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (!mounted || image == null) return;

      final file = File(image.path);

      if (!await file.exists()) {
        if (!mounted) return;
        showErrorDialog('add_place.image_unavailable'.tr());
        return;
      }

      final copiedFile = await copyImageToAppDirectory(file);

      if (!mounted) return;

      setState(() {
        selectedImages.add(copiedFile ?? file);
      });
    } catch (_) {
      if (!mounted) return;
      showErrorDialog('add_place.image_pick_failed'.tr(namedArgs: {'error': ''}));
    }
  }

  Future<void> pickVideos() async {
    if (isLoading) return;

    try {
      final isOffline = context.read<ConnectivityProvider>().isOffline;

      if (isOffline) {
        showErrorDialog('add_place.multi_pick_failed'.tr());
        return;
      }

      final picker = ImagePicker();

      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (!mounted || video == null) return;

      final file = File(video.path);

      if (!await file.exists()) {
        if (!mounted) return;
        showErrorDialog('add_place.image_unavailable'.tr());
        return;
      }

      final fileSize = await file.length();

      if (!mounted) return;

      if (fileSize == 0) {
        showErrorDialog('add_place.image_unavailable'.tr());
        return;
      }

      if (fileSize > 200 * 1024 * 1024) {
        showErrorDialog('add_place.image_unavailable'.tr());
        return;
      }

      final copied = await copyVideoToAppDirectory(file);

      if (!mounted) return;

      if (copied == null) {
        showErrorDialog('add_place.image_unavailable'.tr());
        return;
      }

      setState(() {
        selectedVideos.add(copied);
      });
    } catch (e) {
      if (!mounted) return;
      showErrorDialog('add_place.image_pick_failed'.tr(namedArgs: {'error': e.toString()}));
    }
  }

  Future<File?> copyImageToAppDirectory(File originalFile) async {
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
    } catch (_) {
      return null;
    }
  }

  Future<File?> copyVideoToAppDirectory(File originalFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'temp_videos'));

      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final rawExt =
          originalFile.path.split('.').last.split('?').first.toLowerCase();

      final extension = ['mp4', 'mov', 'm4v'].contains(rawExt) ? rawExt : 'mp4';

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final newPath = path.join(videosDir.path, fileName);

      await originalFile.copy(newPath);

      final copied = File(newPath);

      if (await copied.exists() && await copied.length() > 0) {
        return copied;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to copy video: $e');
      return null;
    }
  }

  void removeNewImage(int index) {
    setState(() => selectedImages.removeAt(index));
  }

  void removeExistingImage(int index) {
    setState(() {
      removedImages.add(existingImages[index]);
      existingImages.removeAt(index);
    });
  }

  void removeNewVideo(int index) {
    setState(() => selectedVideos.removeAt(index));
  }

  void removeExistingVideo(int index) {
    setState(() {
      removedVideos.add(existingVideos[index]);
      existingVideos.removeAt(index);
    });
  }

  void addTipField() {
    setState(() {
      tipControllers.add(TextEditingController());
    });
  }

  void removeTipField(int index) {
    if (tipControllers.length == 1) {
      tipControllers[index].clear();
      return;
    }

    final removed = tipControllers.removeAt(index);
    removed.dispose();

    setState(() {});
  }

  void addDishField() {
    setState(() {
      dishControllers.add(
        DishDraftControllers(
          name: TextEditingController(),
          description: TextEditingController(),
        ),
      );
    });
  }

  void removeDishField(int index) {
    if (dishControllers.length == 1) {
      dishControllers[index].name.clear();
      dishControllers[index].description.clear();
      return;
    }

    final removed = dishControllers.removeAt(index);
    removed.dispose();

    setState(() {});
  }

  List<Tip> buildTips() {
    final user = FirebaseAuth.instance.currentUser;

    return tipControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .map(
          (text) => Tip(
            text: text,
            authorId: user?.uid,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }

  List<Dish> buildDishes() {
    final user = FirebaseAuth.instance.currentUser;

    return dishControllers
        .where((dish) => dish.name.text.trim().isNotEmpty)
        .map(
          (dish) => Dish(
            name: dish.name.text.trim(),
            description: dish.description.text.trim().isEmpty
                ? null
                : dish.description.text.trim(),
            authorId: user?.uid,
          ),
        )
        .toList();
  }

  Future<void> submitPlace() async {
    if (isLoading) return;
    if (!validateCurrentStep()) return;

    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);

    if (lat == null || lng == null) {
      showErrorDialog('add_place.invalid_coords'.tr());
      return;
    }

    final provider = context.read<PlaceProvider>();
    final isOffline = context.read<ConnectivityProvider>().isOffline;

    final hasMediaChanges = selectedImages.isNotEmpty ||
        selectedVideos.isNotEmpty ||
        removedImages.isNotEmpty ||
        removedVideos.isNotEmpty;

    if (isOffline && hasMediaChanges) {
      showErrorDialog('add_place.multi_pick_failed'.tr());
      return;
    }

    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated.');
      }

      final tips = buildTips();
      final dishes = buildDishes();

      if (isEditing) {
        final oldPlace = widget.placeToEdit!;

        final updatedPlace = Place(
          id: oldPlace.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
          images: existingImages,
          videos: existingVideos,
          location: GeoPoint(lat, lng),
          createdBy: oldPlace.createdBy,
          createdAt: oldPlace.createdAt,
          tips: tips,
          recommendedDishes: dishes,
          rating: oldPlace.rating,
          reviewCount: oldPlace.reviewCount,
          budgetLevel: selectedBudgetLevel,
        );

        await provider.updatePlace(
          updatedPlace,
          newLocalImagePaths: selectedImages.map((f) => f.path).toList(),
          removeImageUrls: removedImages,
          newLocalVideoPaths: selectedVideos.map((f) => f.path).toList(),
          removeVideoUrls: removedVideos,
          isOffline: isOffline,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('add_place.added_success'.tr())),
        );

        Navigator.of(context).pop();
      } else {
        final place = Place(
          id: '',
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
          images: const [],
          videos: const [],
          location: GeoPoint(lat, lng),
          createdBy: user.uid,
          createdAt: DateTime.now(),
          tips: tips,
          recommendedDishes: dishes,
          budgetLevel: selectedBudgetLevel,
        );

        await provider.addPlace(
          place,
          localImagePaths: selectedImages.map((file) => file.path).toList(),
          localVideoPaths: selectedVideos.map((file) => file.path).toList(),
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
              title: Text('common.success'.tr()),
              content: Text('add_place.added_success'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('common.ok'.tr()),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        clearForm();
      }
    } catch (e) {
      if (!mounted) return;
      showErrorDialog('common.error_prefix'.tr(namedArgs: {'error': e.toString()}));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void clearForm() {
    setState(() {
      currentStep = 0;

      nameController.clear();
      descriptionController.clear();
      latController.clear();
      lngController.clear();

      selectedCategory = Categories.all.first;
      selectedBudgetLevel = 1;

      selectedImages.clear();
      selectedVideos.clear();
      removedImages.clear();
      removedVideos.clear();
      existingImages.clear();
      existingVideos.clear();

      for (final controller in tipControllers) {
        controller.dispose();
      }

      tipControllers.clear();
      tipControllers.add(TextEditingController());

      for (final dish in dishControllers) {
        dish.dispose();
      }

      dishControllers.clear();
      dishControllers.add(
        DishDraftControllers(
          name: TextEditingController(),
          description: TextEditingController(),
        ),
      );
    });

    _pageController.jumpToPage(0);
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

  void showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AddPlaceColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('common.error'.tr()),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('common.ok'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isEditing ? 'common.edit'.tr() : 'add_place.title'.tr();

    return Scaffold(
      backgroundColor: AddPlaceColors.background,
      appBar: AppBar(
        backgroundColor: AddPlaceColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AddPlaceColors.text),
        title: Text(
          title,
          style: const TextStyle(
            color: AddPlaceColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AddPlaceStepHeader(
              currentStep: currentStep,
              isEditing: isEditing,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  AddPlaceMainInfoStep(
                    nameController: nameController,
                    descriptionController: descriptionController,
                    latController: latController,
                    lngController: lngController,
                    selectedCategory: selectedCategory,
                    selectedBudgetLevel: selectedBudgetLevel,
                    onCategoryChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedCategory = value);
                    },
                    onBudgetChanged: (value) {
                      setState(() => selectedBudgetLevel = value);
                    },
                    onPickLocation: pickLocationFromMap,
                  ),
                  AddPlaceLocalDetailsStep(
                    tipControllers: tipControllers,
                    dishControllers: dishControllers,
                    onAddTip: addTipField,
                    onRemoveTip: removeTipField,
                    onAddDish: addDishField,
                    onRemoveDish: removeDishField,
                  ),
                  AddPlaceMediaStep(
                    existingImages: existingImages,
                    selectedImages: selectedImages,
                    existingVideos: existingVideos,
                    selectedVideos: selectedVideos,
                    onPickImages: pickImages,
                    onPickSingleImage: pickSingleImage,
                    onPickVideos: pickVideos,
                    onRemoveExistingImage: removeExistingImage,
                    onRemoveNewImage: removeNewImage,
                    onRemoveExistingVideo: removeExistingVideo,
                    onRemoveNewVideo: removeNewVideo,
                    summaryName: nameController.text.trim(),
                    summaryCategory: selectedCategory,
                    summaryBudgetLevel: selectedBudgetLevel,
                    tipsCount: buildTips().length,
                    dishesCount: buildDishes().length,
                  ),
                ],
              ),
            ),
            AddPlaceBottomNavigation(
              currentStep: currentStep,
              isLoading: isLoading,
              isEditing: isEditing,
              onBack: currentStep == 0 ? null : () => goToStep(currentStep - 1),
              onNext: currentStep == 2
                  ? submitPlace
                  : () => goToStep(currentStep + 1),
            ),
          ],
        ),
      ),
    );
  }
}
