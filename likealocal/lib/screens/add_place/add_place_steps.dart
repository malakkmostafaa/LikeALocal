import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../utils/categories.dart';
import 'add_place_widgets.dart';

class AddPlaceMainInfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickLocation;

  const AddPlaceMainInfoStep({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.latController,
    required this.lngController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onPickLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepTitle(
            icon: Icons.place_rounded,
            title: 'Main information',
            subtitle: 'Tell locals what this place is and where to find it.',
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              LabeledField(
                label: 'Place name',
                child: TextField(
                  controller: nameController,
                  decoration: AddPlaceInputs.decoration(
                    'e.g. Souq El-Attarine',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Description',
                child: TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: AddPlaceInputs.decoration(
                    'What makes this place worth visiting?',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Category',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: Categories.all.map((category) {
                    final isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () => onCategoryChanged(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AddPlaceColors.primary
                              : AddPlaceColors.inputFill,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isSelected
                                ? AddPlaceColors.primary
                                : AddPlaceColors.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AddPlaceColors.primary
                                        .withOpacity(0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AddPlaceColors.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  color: AddPlaceColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: TextInputType.number,
                      decoration: AddPlaceInputs.decoration('Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: TextInputType.number,
                      decoration: AddPlaceInputs.decoration('Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onPickLocation,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Pick from Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AddPlaceColors.primary,
                    side: const BorderSide(color: AddPlaceColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddPlaceLocalDetailsStep extends StatelessWidget {
  final List<TextEditingController> tipControllers;
  final List<DishDraftControllers> dishControllers;
  final VoidCallback onAddTip;
  final ValueChanged<int> onRemoveTip;
  final VoidCallback onAddDish;
  final ValueChanged<int> onRemoveDish;

  const AddPlaceLocalDetailsStep({
    super.key,
    required this.tipControllers,
    required this.dishControllers,
    required this.onAddTip,
    required this.onRemoveTip,
    required this.onAddDish,
    required this.onRemoveDish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepTitle(
            icon: Icons.lightbulb_rounded,
            title: 'Local details',
            subtitle: 'Add tips and dishes to make the post more useful.',
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Local tips',
                      style: TextStyle(
                        color: AddPlaceColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddTip,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...tipControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLines: 2,
                          decoration: AddPlaceInputs.decoration(
                            'Tip ${index + 1} — e.g. Go before sunset',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SmallIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => onRemoveTip(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recommended dishes',
                      style: TextStyle(
                        color: AddPlaceColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddDish,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...dishControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final dish = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AddPlaceColors.inputFill.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dish ${index + 1}',
                              style: const TextStyle(
                                color: AddPlaceColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SmallIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => onRemoveDish(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dish.name,
                        decoration: AddPlaceInputs.decoration('Dish name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dish.description,
                        maxLines: 2,
                        decoration: AddPlaceInputs.decoration(
                          'Short description',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class AddPlaceMediaStep extends StatelessWidget {
  final List<String> existingImages;
  final List<File> selectedImages;
  final List<String> existingVideos;
  final List<File> selectedVideos;

  final VoidCallback onPickImages;
  final VoidCallback onPickSingleImage;
  final VoidCallback onPickVideos;

  final ValueChanged<int> onRemoveExistingImage;
  final ValueChanged<int> onRemoveNewImage;
  final ValueChanged<int> onRemoveExistingVideo;
  final ValueChanged<int> onRemoveNewVideo;

  final String summaryName;
  final String summaryCategory;
  final int tipsCount;
  final int dishesCount;

  const AddPlaceMediaStep({
    super.key,
    required this.existingImages,
    required this.selectedImages,
    required this.existingVideos,
    required this.selectedVideos,
    required this.onPickImages,
    required this.onPickSingleImage,
    required this.onPickVideos,
    required this.onRemoveExistingImage,
    required this.onRemoveNewImage,
    required this.onRemoveExistingVideo,
    required this.onRemoveNewVideo,
    required this.summaryName,
    required this.summaryCategory,
    required this.tipsCount,
    required this.dishesCount,
  });

  @override
  Widget build(BuildContext context) {
    final imagesCount = existingImages.length + selectedImages.length;
    final videosCount = existingVideos.length + selectedVideos.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepTitle(
            icon: Icons.photo_library_rounded,
            title: 'Photos and videos',
            subtitle: 'Attach media to make the place more visual.',
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              const Text(
                'Photos',
                style: TextStyle(
                  color: AddPlaceColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPickImages,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Multiple'),
                      style: AddPlaceButtons.primary(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPickSingleImage,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('One'),
                      style: AddPlaceButtons.primary(),
                    ),
                  ),
                ],
              ),
              if (imagesCount > 0) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...existingImages.asMap().entries.map((entry) {
                        return ImageThumbnail(
                          imageWidget: Image.network(
                            entry.value,
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                          ),
                          onRemove: () => onRemoveExistingImage(entry.key),
                        );
                      }),
                      ...selectedImages.asMap().entries.map((entry) {
                        return ImageThumbnail(
                          imageWidget: Image.file(
                            entry.value,
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                          ),
                          onRemove: () => onRemoveNewImage(entry.key),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            children: [
              const Text(
                'Videos',
                style: TextStyle(
                  color: AddPlaceColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Max 5 min · mp4, mov supported',
                style: TextStyle(
                  color: AddPlaceColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onPickVideos,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Pick a Video'),
                  style: AddPlaceButtons.primary(),
                ),
              ),
              if (videosCount > 0) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...existingVideos.asMap().entries.map((entry) {
                        return VideoThumbnail(
                          label: 'Video ${entry.key + 1}',
                          onRemove: () => onRemoveExistingVideo(entry.key),
                        );
                      }),
                      ...selectedVideos.asMap().entries.map((entry) {
                        return VideoThumbnail(
                          label: path.basename(entry.value.path),
                          onRemove: () => onRemoveNewVideo(entry.key),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SummaryCard(
            name: summaryName,
            category: summaryCategory,
            imagesCount: imagesCount,
            videosCount: videosCount,
            tipsCount: tipsCount,
            dishesCount: dishesCount,
          ),
        ],
      ),
    );
  }
}
