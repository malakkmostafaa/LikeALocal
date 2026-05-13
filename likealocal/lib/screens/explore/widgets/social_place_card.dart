import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/place.dart';
import 'post_user_header.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialPlaceCard extends StatefulWidget {
  final Place place;
  final double? distanceInMeters;
  final VoidCallback? onTap;

  const SocialPlaceCard({
    Key? key,
    required this.place,
    this.distanceInMeters,
    this.onTap,
  }) : super(key: key);

  @override
  State<SocialPlaceCard> createState() => _SocialPlaceCardState();
}

class _SocialPlaceCardState extends State<SocialPlaceCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isSaved = false;
  bool _isLoadingSaved = true;

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
          
      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  void _handleLike() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? 'Liked' : 'Unliked'),
        duration: const Duration(seconds: 1),
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

    final wasSaved = _isSaved;
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
            const SnackBar(content: Text('Saved to pins'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await docRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from pins'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaved = wasSaved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleMapTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open the Map tab to view this place')),
    );
  }

  void _handleCommentTap() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.place.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Reviews/comments will be connected by Member 2'),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showDetailsSheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.red),
            title: const Text('Report', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted for review')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: widget.place.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.place.images.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 80, color: Colors.grey),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(widget.place.category, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              padding: EdgeInsets.zero,
                            ),
                            const Spacer(),
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.place.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.place.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        if (widget.distanceInMeters != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatDistance(widget.distanceInMeters!)} away',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final validLocation = widget.place.lat != 0 && widget.place.lng != 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with avatar and name
            PostUserHeader(
              userId: widget.place.createdBy,
              subtitle: widget.place.category.isNotEmpty ? widget.place.category : 'General',
              onMorePressed: _showMoreMenu,
            ),
            // Main image or map placeholder
            SizedBox(
              height: 260,
              child: widget.place.images.isNotEmpty && widget.place.images.first.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.place.images.first,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 80),
                    )
                  : validLocation
                      ? IgnorePointer(
                          child: FlutterMap(
                            options: MapOptions(
                              center: LatLng(widget.place.lat, widget.place.lng),
                              zoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.likealocal',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(widget.place.lat, widget.place.lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const Icon(Icons.image, size: 80),
            ),
            // Action bar
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _handleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: _handleCommentTap,
                ),
                if (_isLoadingSaved)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? Theme.of(context).primaryColor : null,
                    ),
                    onPressed: _handleSave,
                  ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _handleMapTap,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.place.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Post content (Caption)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.place.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(widget.place.category, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                      if (widget.distanceInMeters != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              _formatDistance(widget.distanceInMeters!),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      if (_likeCount > 0)
                        Text(
                          '$_likeCount likes',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
