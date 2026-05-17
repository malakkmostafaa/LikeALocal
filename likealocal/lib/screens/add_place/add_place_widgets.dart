import 'package:flutter/material.dart';

class AddPlaceColors {
  static const Color background = Color(0xFFFAF7F2);
  static const Color card = Color(0xFFFFFBF7);
  static const Color inputFill = Color(0xFFEDEDE6);
  static const Color primary = Color(0xFFD45A38);
  static const Color text = Color(0xFF1F1F28);
  static const Color muted = Color(0xFF7A6D66);
  static const Color border = Color(0xFFEEDDD2);
}

class AddPlaceInputs {
  static InputDecoration decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AddPlaceColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class AddPlaceButtons {
  static ButtonStyle primary() {
    return ElevatedButton.styleFrom(
      backgroundColor: AddPlaceColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}

class DishDraftControllers {
  final TextEditingController name;
  final TextEditingController description;

  DishDraftControllers({
    required this.name,
    required this.description,
  });

  void dispose() {
    name.dispose();
    description.dispose();
  }
}

class AddPlaceStepHeader extends StatelessWidget {
  final int currentStep;
  final bool isEditing;

  const AddPlaceStepHeader({
    super.key,
    required this.currentStep,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: const BoxDecoration(
        color: AddPlaceColors.background,
        border: Border(
          bottom: BorderSide(color: AddPlaceColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Update your place' : 'Share a hidden gem',
            style: const TextStyle(
              color: AddPlaceColors.text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              final selected = index == currentStep;
              final completed = index < currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 6,
                        decoration: BoxDecoration(
                          color: selected || completed
                              ? AddPlaceColors.primary
                              : AddPlaceColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class StepTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const StepTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AddPlaceColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AddPlaceColors.primary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AddPlaceColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AddPlaceColors.muted,
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AddPlaceColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AddPlaceColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.022),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AddPlaceColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SmallIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AddPlaceColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AddPlaceColors.border),
          ),
          child: Icon(
            icon,
            color: AddPlaceColors.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class RemoveBadge extends StatelessWidget {
  final VoidCallback onTap;

  const RemoveBadge({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          size: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ImageThumbnail extends StatelessWidget {
  final Widget imageWidget;
  final VoidCallback onRemove;

  const ImageThumbnail({
    super.key,
    required this.imageWidget,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddPlaceColors.border),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: imageWidget,
          ),
          Positioned(
            top: 5,
            right: 5,
            child: RemoveBadge(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class VideoThumbnail extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const VideoThumbnail({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white70,
                    size: 32,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: RemoveBadge(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String name;
  final String category;
  final int imagesCount;
  final int videosCount;
  final int tipsCount;
  final int dishesCount;

  const SummaryCard({
    super.key,
    required this.name,
    required this.category,
    required this.imagesCount,
    required this.videosCount,
    required this.tipsCount,
    required this.dishesCount,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      children: [
        const Text(
          'Quick summary',
          style: TextStyle(
            color: AddPlaceColors.text,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        SummaryRow(
          label: 'Place',
          value: name.isEmpty ? 'Not entered yet' : name,
        ),
        SummaryRow(
          label: 'Category',
          value: category,
        ),
        SummaryRow(
          label: 'Photos',
          value: '$imagesCount selected',
        ),
        SummaryRow(
          label: 'Videos',
          value: '$videosCount selected',
        ),
        SummaryRow(
          label: 'Tips',
          value: '$tipsCount added',
        ),
        SummaryRow(
          label: 'Dishes',
          value: '$dishesCount added',
        ),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AddPlaceColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AddPlaceColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPlaceBottomNavigation extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const AddPlaceBottomNavigation({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.isEditing,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(
        color: AddPlaceColors.background,
        border: Border(
          top: BorderSide(color: AddPlaceColors.border),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AddPlaceColors.text,
                  side: const BorderSide(color: AddPlaceColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: onBack == null ? 1 : 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AddPlaceColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast
                          ? isEditing
                              ? 'Save Changes'
                              : 'Add Place'
                          : 'Continue',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
