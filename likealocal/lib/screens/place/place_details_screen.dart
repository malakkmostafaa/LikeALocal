import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/place.dart';
import '../explore/widgets/post_user_header.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;
  final double? distanceInMeters;

  const PlaceDetailsScreen({
    Key? key,
    required this.place,
    this.distanceInMeters,
  }) : super(key: key);

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF7F2);
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);
    const textColor = Color(0xFF1F1F28);
    const mutedText = Color(0xFF777777);

    final place = widget.place;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                child: Hero(
                  tag: 'place_image_${place.id}',
                  child: place.images.isNotEmpty && place.images.first.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: lightPrimary),
                          errorWidget: (context, url, error) => Container(
                            color: lightPrimary,
                            child: const Icon(Icons.broken_image, size: 50, color: primaryColor),
                          ),
                        )
                      : Container(
                          color: lightPrimary,
                          child: const Icon(Icons.image, size: 80, color: primaryColor),
                        ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _isLoadingSaved 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                      : Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved ? primaryColor : textColor,
                          size: 20,
                        ),
                ),
                onPressed: _handleSave,
              ),
              const SizedBox(width: 8),
            ],
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: textColor, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Row(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFE5A11A), size: 20),
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
                    ),
                    const SizedBox(height: 12),
                    
                    // Tags and Distance
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: lightPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            place.category,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.distanceInMeters != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: mutedText),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistance(widget.distanceInMeters!),
                                  style: const TextStyle(
                                    color: mutedText, 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Poster Info
                    if (place.createdBy != null && place.createdBy!.isNotEmpty) ...[
                      Container(
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
                      const SizedBox(height: 28),
                    ],

                    // Description
                    if (place.description.isNotEmpty) ...[
                      const Text(
                        'About this Place',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        place.description,
                        style: const TextStyle(
                          fontSize: 16, 
                          height: 1.6, 
                          color: Color(0xFF444444),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Recommended Dishes
                    if (place.recommendedDishes.isNotEmpty) ...[
                      const Text(
                        'Local Favorites',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: place.recommendedDishes.length,
                          itemBuilder: (context, index) {
                            final dish = place.recommendedDishes[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: lightPrimary.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: lightPrimary),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dish.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800, 
                                      fontSize: 15,
                                      color: primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (dish.description != null && dish.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      dish.description!,
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: primaryColor.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Tips
                    if (place.tips.isNotEmpty) ...[
                      const Text(
                        'Locals’ Tips',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: place.tips.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tip = place.tips[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.tips_and_updates, color: primaryColor, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip.text,
                                    style: const TextStyle(
                                      fontSize: 15, 
                                      height: 1.5,
                                      color: Color(0xFF555555),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE26D45), Color(0xFFF08E6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening map...')),
                    );
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text(
                    'Open Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.share_rounded,
              onTap: () {},
              primaryColor: primaryColor,
              lightPrimary: lightPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color lightPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: lightPrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: primaryColor),
      ),
    );
  }
}
