import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final List<String> categories;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedCategory == null,
            onSelected: (val) {
              if (val) onCategorySelected(null);
            },
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(cat),
                selected: selectedCategory == cat,
                onSelected: (val) {
                  onCategorySelected(val ? cat : null);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
