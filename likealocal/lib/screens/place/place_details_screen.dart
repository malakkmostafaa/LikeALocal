import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../map/place_map_screen.dart';
import '../../models/place.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/place_provider.dart';
import '../../services/place_service.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/pin_button.dart';
import '../../widgets/video_player_widget.dart';
import '../add_place/add_place_screen.dart';
import '../explore/widgets/post_user_header.dart';
import '../map/map_screen.dart';
import '../place_details/review_form.dart';
import '../place_details/reviews_list.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;
  final double? distanceInMeters;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    this.distanceInMeters,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final PlaceService _placeService = PlaceService();
  final RecommendationService _recommendationService = RecommendationService();

  int _selectedTab = 0;

  static const Color bgColor = Color(0xFFF7F4EF);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFBE8DF);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);
  static const Color goldColor = Color(0xFFE5A11A);

  @override
  void initState() {
    super.initState();

    _recommendationService.trackViewPlace(
      widget.place.id,
      widget.place.category,
      budgetLevel: widget.place.budgetLevel,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return 'place.distance_m'.tr(namedArgs: {'meters': meters.round().toString()});
    return 'place.distance_km'.tr(namedArgs: {'km': (meters / 1000).toStringAsFixed(1)});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Place?>(
      stream: _placeService.getPlaceById(widget.place.id),
      builder: (context, snapshot) {
        final place = snapshot.data ?? widget.place;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroHeader(
                          place: place,
                          onBack: () => Navigator.pop(context),
                          onPinChanged: (pinned) {
                            if (pinned) {
                              _recommendationService.trackSavePlace(
                                place.id,
                                place.category,
                                budgetLevel: place.budgetLevel,
                              );
                            }
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPlaceScreen(
                                  placeToEdit: place,
                                ),
                              ),
                            );
                          },
                          onDelete: () => _deletePlace(context, place),
                        ),
                        const SizedBox(height: 18),
                        _PlaceIdentityBlock(
                          place: place,
                          distanceInMeters: widget.distanceInMeters,
                          formatDistance: _formatDistance,
                        ),
                        const SizedBox(height: 16),
                        _DetailsTabBar(
                          selectedIndex: _selectedTab,
                          onChanged: (index) {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _buildSelectedSection(place),
                        ),
                      ],
                    ),
                  ),
                ),
                _BottomActionBar(place: place),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedSection(Place place) {
    switch (_selectedTab) {
      case 1:
        return _ReviewsSection(
          key: const ValueKey('reviews'),
          place: place,
        );
      case 2:
        return _TipsSection(
          key: const ValueKey('tips'),
          place: place,
        );
      case 3:
        return _DishesSection(
          key: const ValueKey('dishes'),
          place: place,
        );
      case 0:
      default:
        return _OverviewSection(
          key: const ValueKey('overview'),
          place: place,
        );
    }
  }

  Future<void> _deletePlace(BuildContext context, Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('common.delete'.tr()),
          content: Text(
            'Are you sure you want to delete this place? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'common.delete'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        },
      );

      final provider = context.read<PlaceProvider>();
      final isOffline = context.read<ConnectivityProvider>().isOffline;

      await provider.deletePlace(place, isOffline: isOffline);

      if (!context.mounted) return;

      Navigator.pop(context); // loading
      Navigator.pop(context); // details

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Place deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context); // loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'common.error_prefix'.tr(namedArgs: {'error': e.toString().replaceFirst('Exception: ', '')}),
          ),
        ),
      );
    }
  }
}

class _HeroHeader extends StatelessWidget {
  final Place place;
  final VoidCallback onBack;
  final ValueChanged<bool> onPinChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroHeader({
    required this.place,
    required this.onBack,
    required this.onPinChanged,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isOwner {
    return place.createdBy == FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 285,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _PlaceDetailsScreenState.softPrimary,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _HeroMedia(place: place),
          ),

          // Top-only soft overlay so buttons stay readable.
          // No bottom title/white gradient.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 95,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 14,
            child: _CircleActionButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),

          Positioned(
            top: 14,
            right: 14,
            child: Row(
              children: [
                if (_isOwner)
                  _OwnerMenuButton(
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                const SizedBox(width: 8),
                PinButton(
                  placeId: place.id,
                  activeColor: _PlaceDetailsScreenState.primaryColor,
                  inactiveColor: _PlaceDetailsScreenState.textColor,
                  onChanged: onPinChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMedia extends StatelessWidget {
  final Place place;

  const _HeroMedia({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = place.images.isNotEmpty && place.images.first.isNotEmpty;

    if (!hasImage) {
      return Container(
        color: _PlaceDetailsScreenState.softPrimary,
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            size: 78,
            color: _PlaceDetailsScreenState.primaryColor,
          ),
        ),
      );
    }

    return Hero(
      tag: 'place_image_${place.id}',
      child: CachedNetworkImage(
        imageUrl: place.images.first,
        fit: BoxFit.cover,
        placeholder: (_, __) {
          return Container(color: _PlaceDetailsScreenState.softPrimary);
        },
        errorWidget: (_, __, ___) {
          return Container(
            color: _PlaceDetailsScreenState.softPrimary,
            child: const Icon(
              Icons.broken_image_rounded,
              size: 70,
              color: _PlaceDetailsScreenState.primaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _PlaceIdentityBlock extends StatelessWidget {
  final Place place;
  final double? distanceInMeters;
  final String Function(double meters) formatDistance;

  const _PlaceIdentityBlock({
    required this.place,
    required this.distanceInMeters,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryPill(label: place.category),
          const SizedBox(height: 10),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PlaceDetailsScreenState.textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (place.createdBy != null && place.createdBy!.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: _PlaceDetailsScreenState.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _PlaceDetailsScreenState.borderColor,
                ),
              ),
              child: PostUserHeader(
                userId: place.createdBy,
                subtitle: 'place.contributor'.tr(),
                onMorePressed: () {},
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: _PlaceDetailsScreenState.goldColor,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                place.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: _PlaceDetailsScreenState.mutedText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${place.reviewCount})',
                style: const TextStyle(
                  color: _PlaceDetailsScreenState.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.payments_rounded,
                color: _PlaceDetailsScreenState.mutedText,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                place.budgetLabel,
                style: const TextStyle(
                  color: _PlaceDetailsScreenState.mutedText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (distanceInMeters != null) ...[
                const SizedBox(width: 14),
                const Icon(
                  Icons.location_on_outlined,
                  color: _PlaceDetailsScreenState.mutedText,
                  size: 18,
                ),
                const SizedBox(width: 3),
                Text(
                  formatDistance(distanceInMeters!),
                  style: const TextStyle(
                    color: _PlaceDetailsScreenState.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DetailsTabBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _DetailsTabData('place.about_short'.tr(), Icons.info_outline_rounded),
      _DetailsTabData('place.reviews_title'.tr(), Icons.star_border_rounded),
      _DetailsTabData('place.tips_title'.tr(), Icons.lightbulb_outline_rounded),
      _DetailsTabData('place.local_favorites'.tr(), Icons.restaurant_menu_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBE6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? _PlaceDetailsScreenState.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? _PlaceDetailsScreenState.textColor
                        : _PlaceDetailsScreenState.mutedText,
                    fontSize: 12.2,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final Place place;

  const _OverviewSection({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (place.description.isNotEmpty) ...[
          _InfoCard(
            child: Text(
              place.description,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.55,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (place.images.length > 1) ...[
          _SectionTitle('add_place.section_photos'.tr()),
          const SizedBox(height: 12),
          _PhotosStrip(place: place),
          const SizedBox(height: 18),
        ],
        if (place.videos.isNotEmpty) ...[
          const _SectionTitle('Videos'),
          const SizedBox(height: 12),
          ...place.videos.map((videoUrl) {
            return Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: 14),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: VideoPlayerWidget(url: videoUrl),
            );
          }),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final Place place;

  const _ReviewsSection({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('place.reviews_title'.tr()),
        const SizedBox(height: 12),
        ReviewForm(placeId: place.id),
        const SizedBox(height: 16),
        ReviewsList(placeId: place.id),
      ],
    );
  }
}

class _TipsSection extends StatelessWidget {
  final Place place;

  const _TipsSection({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    if (place.tips.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.lightbulb_outline_rounded,
        title: 'No tips yet',
        message: 'Local tips added by contributors will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('place.tips_title'.tr()),
        const SizedBox(height: 12),
        ...place.tips.map((tip) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _PlaceDetailsScreenState.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _PlaceDetailsScreenState.borderColor,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _PlaceDetailsScreenState.softPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _PlaceDetailsScreenState.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip.text,
                    style: const TextStyle(
                      color: _PlaceDetailsScreenState.textColor,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DishesSection extends StatelessWidget {
  final Place place;

  const _DishesSection({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    if (place.recommendedDishes.isEmpty) {
      return _EmptyStateCard(
        icon: Icons.restaurant_menu_rounded,
        title: 'No dishes added',
        message: 'Recommended dishes will appear here for food places.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('place.local_favorites'.tr()),
        const SizedBox(height: 12),
        ...place.recommendedDishes.map((dish) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _PlaceDetailsScreenState.softPrimary.withOpacity(0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _PlaceDetailsScreenState.softPrimary,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _PlaceDetailsScreenState.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          color: _PlaceDetailsScreenState.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
                      if (dish.description != null &&
                          dish.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dish.description!,
                          style: TextStyle(
                            color: _PlaceDetailsScreenState.primaryColor
                                .withOpacity(0.72),
                            height: 1.35,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PhotosStrip extends StatelessWidget {
  final Place place;

  const _PhotosStrip({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final photos = place.images;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = photos[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              placeholder: (_, __) {
                return Container(
                  width: 104,
                  height: 104,
                  color: _PlaceDetailsScreenState.softPrimary,
                );
              },
              errorWidget: (_, __, ___) {
                return Container(
                  width: 104,
                  height: 104,
                  color: _PlaceDetailsScreenState.softPrimary,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: _PlaceDetailsScreenState.primaryColor,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LocationPreviewButton extends StatelessWidget {
  final Place place;

  const _LocationPreviewButton({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaceMapScreen(place: place)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _PlaceDetailsScreenState.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _PlaceDetailsScreenState.primaryColor.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                color: _PlaceDetailsScreenState.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'place.view_on_maps'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      color: _PlaceDetailsScreenState.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'place.view_on_maps_sub'.tr(),
                    style: const TextStyle(
                      color: _PlaceDetailsScreenState.mutedText,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _PlaceDetailsScreenState.textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Place place;

  const _BottomActionBar({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: _PlaceDetailsScreenState.bgColor,
        border: Border(
          top: BorderSide(
            color: _PlaceDetailsScreenState.borderColor,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaceMapScreen(place: place)),
                  );
                },
                icon: const Icon(Icons.map_rounded),
                label: Text('map_screen.view_details'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _PlaceDetailsScreenState.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
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

class _OwnerMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OwnerMenuButton({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.more_vert_rounded,
          color: _PlaceDetailsScreenState.textColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: _PlaceDetailsScreenState.textColor,
                  ),
                  const SizedBox(width: 10),
                  Text('common.edit'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'common.delete'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: _PlaceDetailsScreenState.textColor,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _PlaceDetailsScreenState.softPrimary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label.isEmpty ? 'Place' : label,
        style: const TextStyle(
          color: _PlaceDetailsScreenState.primaryColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PlaceDetailsScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _PlaceDetailsScreenState.borderColor,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        children: [
          Icon(
            icon,
            color: _PlaceDetailsScreenState.primaryColor,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _PlaceDetailsScreenState.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PlaceDetailsScreenState.mutedText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: _PlaceDetailsScreenState.textColor,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _DetailsTabData {
  final String label;
  final IconData icon;

  const _DetailsTabData(
    this.label,
    this.icon,
  );
}
