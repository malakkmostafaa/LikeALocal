import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../providers/place_provider.dart';
import '../../providers/connectivity_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _recommendationService.trackViewPlace(widget.place.id, widget.place.category);
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Place?>(
      stream: _placeService.getPlaceById(widget.place.id),
      builder: (context, snapshot) {
        final place = snapshot.data ?? widget.place;

        return _PlaceDetailsContent(
          place: place,
          distanceInMeters: widget.distanceInMeters,
          formatDistance: _formatDistance,
          onPinChanged: (pinned) {
            if (pinned) {
              _recommendationService.trackSavePlace(place.id, place.category);
            }
          },
        );
      },
    );
  }
}

class _PlaceDetailsContent extends StatelessWidget {
  final Place place;
  final double? distanceInMeters;
  final String Function(double meters) formatDistance;
  final ValueChanged<bool> onPinChanged;

  const _PlaceDetailsContent({
    required this.place,
    required this.distanceInMeters,
    required this.formatDistance,
    required this.onPinChanged,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF7F2);
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);
    const textColor = Color(0xFF1F1F28);
    const mutedText = Color(0xFF777777);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(place: place),
            ),
            leading: _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: PinButton(
                  placeId: place.id,
                  activeColor: primaryColor,
                  inactiveColor: textColor,
                  onChanged: onPinChanged,
                ),
              ),
              if (place.createdBy == FirebaseAuth.instance.currentUser?.uid)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
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
                      icon: const Icon(Icons.more_vert_rounded, color: textColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPlaceScreen(placeToEdit: place),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Place'),
                              content: const Text('Are you sure you want to delete this place? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              
                              final provider = context.read<PlaceProvider>();
                              final isOffline = context.read<ConnectivityProvider>().isOffline;
                              
                              await provider.deletePlace(place, isOffline: isOffline);
                              
                              if (context.mounted) {
                                Navigator.pop(context); // pop loading
                                Navigator.pop(context); // pop place details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Place deleted successfully.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // pop loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20, color: textColor),
                              SizedBox(width: 10),
                              Text('Edit Post'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete Post', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleAndRating(place: place),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        icon: Icons.category_rounded,
                        label: place.category,
                        color: primaryColor,
                        backgroundColor: lightPrimary,
                      ),
                      if (distanceInMeters != null)
                        _Chip(
                          icon: Icons.location_on_rounded,
                          label: formatDistance(distanceInMeters!),
                          color: mutedText,
                          backgroundColor: Colors.grey.shade100,
                        ),
                      _Chip(
                        icon: Icons.rate_review_rounded,
                        label: '${place.reviewCount} reviews',
                        color: mutedText,
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (place.createdBy != null && place.createdBy!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: PostUserHeader(
                        userId: place.createdBy,
                        subtitle: 'Place Contributor',
                        onMorePressed: () {},
                      ),
                    ),
                  if (place.description.isNotEmpty) ...[
                    _SectionTitle('About this place'),
                    const SizedBox(height: 10),
                    Text(
                      place.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.55,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (place.videos.isNotEmpty) ...[
                    _SectionTitle('Videos'),
                    const SizedBox(height: 14),
                    ...place.videos.map((videoUrl) {
                      return Container(
                        height: 220,
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: VideoPlayerWidget(url: videoUrl),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                  _LocationPreviewButton(place: place),

                  const SizedBox(height: 26),
                  if (place.recommendedDishes.isNotEmpty) ...[
                    _SectionTitle('Local favorites'),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 115,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: place.recommendedDishes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final dish = place.recommendedDishes[index];

                          return Container(
                            width: 170,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightPrimary.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: lightPrimary),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dish.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (dish.description != null &&
                                    dish.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    dish.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryColor.withOpacity(0.75),
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (place.tips.isNotEmpty) ...[
                    _SectionTitle('Locals’ tips'),
                    const SizedBox(height: 14),
                    ...place.tips.map(
                      (tip) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip.text,
                                style: const TextStyle(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _SectionTitle('Reviews'),
                  const SizedBox(height: 14),
                  ReviewForm(placeId: place.id),
                  const SizedBox(height: 16),
                  ReviewsList(placeId: place.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final Place place;

  const _HeroImage({required this.place});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);

    if (place.images.isEmpty || place.images.first.isEmpty) {
      return Container(
        color: lightPrimary,
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            size: 80,
            color: primaryColor,
          ),
        ),
      );
    }

    return Hero(
      tag: 'place_image_${place.id}',
      child: CachedNetworkImage(
        imageUrl: place.images.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: lightPrimary),
        errorWidget: (_, __, ___) => Container(
          color: lightPrimary,
          child: const Icon(
            Icons.broken_image_rounded,
            size: 70,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(9),
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
        child: Icon(icon, color: const Color(0xFF1F1F28), size: 20),
      ),
    );
  }
}

class _TitleAndRating extends StatelessWidget {
  final Place place;

  const _TitleAndRating({required this.place});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1F1F28);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            place.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFE5A11A),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                place.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5A11A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreviewButton extends StatelessWidget {
  final Place place;

  const _LocationPreviewButton({required this.place});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapScreen(initialPlace: place),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryColor.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View on Google Maps',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Open the map centered on this place',
                    style: TextStyle(color: Color(0xFF777777)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
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
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1F1F28),
        letterSpacing: -0.3,
      ),
    );
  }
}
