import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/place.dart';
import '../../map/map_screen.dart';
import '../../place/place_details_screen.dart';
import 'place_map_preview.dart';
import 'post_user_header.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialPlaceCard extends StatefulWidget {
  final Place place;
  final double? distanceInMeters;
  final VoidCallback? onTap;

  const SocialPlaceCard({
    super.key,
    required this.place,
    this.distanceInMeters,
    this.onTap,
  });

  @override
  State<SocialPlaceCard> createState() => _SocialPlaceCardState();
}

class _SocialPlaceCardState extends State<SocialPlaceCard> {
  bool _isSaved = false;
  bool _isLoadingSaved = true;

  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoadingSaved = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pins')
          .doc(widget.place.id)
          .get();

      if (!mounted) return;

      setState(() {
        _isSaved = doc.exists;
        _isLoadingSaved = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: widget.place,
          distanceInMeters: widget.distanceInMeters,
        ),
      ),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(initialPlace: widget.place),
      ),
    );
  }

  Future<void> _handleSave() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final previous = _isSaved;

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pins')
          .doc(widget.place.id);

      if (_isSaved) {
        await docRef.set({
          'savedAt': FieldValue.serverTimestamp(),
          'placeId': widget.place.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to pins'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await docRef.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from pins'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaved = previous;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _openDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('View on Map'),
              onTap: () {
                Navigator.pop(context);
                _openMap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted for review')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    final hasImage =
        widget.place.images.isNotEmpty && widget.place.images.first.isNotEmpty;

    if (hasImage) {
      return Hero(
        tag: 'place_image_${widget.place.id}',
        child: CachedNetworkImage(
          imageUrl: widget.place.images.first,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: softPrimary),
          errorWidget: (_, __, ___) => PlaceMapPreview(
            lat: widget.place.lat,
            lng: widget.place.lng,
            placeName: widget.place.name,
            onTap: _openMap,
          ),
        ),
      );
    }

    return PlaceMapPreview(
      lat: widget.place.lat,
      lng: widget.place.lng,
      placeName: widget.place.name,
      onTap: _openMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    const cardColor = Color(0xFFFFFBF7);
    const borderColor = Color(0xFFF0E4DC);
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: widget.onTap ?? _openDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: PostUserHeader(
                userId: place.createdBy,
                subtitle:
                    place.category.isNotEmpty ? place.category : 'General',
                onMorePressed: _showMoreMenu,
              ),
            ),

            // Image styled like Super User card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                children: [
                  Container(
                    height: 235,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: softPrimary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildImageArea(),
                  ),

                  // Category pill
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        place.category.isEmpty ? 'General' : place.category,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // Map icon
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _FloatingCircleButton(
                      icon: Icons.map_outlined,
                      onTap: _openMap,
                    ),
                  ),

                  // Save icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _isLoadingSaved
                        ? Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : _FloatingCircleButton(
                            icon: _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isSaved ? primaryColor : textColor,
                            onTap: _handleSave,
                          ),
                  ),
                ],
              ),
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE5A11A),
                        size: 19,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.rate_review_outlined,
                        size: 15,
                        color: mutedText.withOpacity(0.75),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${place.reviewCount}',
                        style: const TextStyle(
                          color: mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.distanceInMeters != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: mutedText.withOpacity(0.75),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDistance(widget.distanceInMeters!),
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (place.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FloatingCircleButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF1F1F28),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
    );
  }
}
