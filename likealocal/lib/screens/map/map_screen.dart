import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../providers/place_provider.dart';
import '../place/place_details_screen.dart';

class MapScreen extends StatefulWidget {
  final Place? initialPlace;

  const MapScreen({
    super.key,
    this.initialPlace,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPlaceId;

  MapType _mapType = MapType.normal;

  static const Color bgColor = Color(0xFFF6EFE8);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color borderColor = Color(0xFFF0E4DC);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();

    if (widget.initialPlace != null) {
      _selectedPlaceId = widget.initialPlace!.id;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  CameraPosition _initialCamera(List<Place> validPlaces) {
    final initial = widget.initialPlace;

    if (initial != null && initial.lat != 0 && initial.lng != 0) {
      return CameraPosition(
        target: LatLng(initial.lat, initial.lng),
        zoom: 16,
      );
    }

    if (validPlaces.isNotEmpty) {
      return CameraPosition(
        target: LatLng(validPlaces.first.lat, validPlaces.first.lng),
        zoom: 13,
      );
    }

    return _defaultCameraPosition;
  }

  List<String> _categories(List<Place> places) {
    final categories = places
        .map((place) => place.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();

    return categories;
  }

  List<Place> _filterPlaces(List<Place> places) {
    final query = _searchQuery.trim().toLowerCase();

    return places.where((place) {
      final matchesSearch = query.isEmpty ||
          place.name.toLowerCase().contains(query) ||
          place.category.toLowerCase().contains(query) ||
          place.description.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == null || place.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Set<Marker> _markers(List<Place> places) {
    return places.map((place) {
      final isSelected = place.id == _selectedPlaceId;

      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: '${place.category} • ${place.rating.toStringAsFixed(1)} ★',
        ),
        onTap: () {
          setState(() {
            _selectedPlaceId = place.id;
          });

          _showPlaceSheet(place);
        },
      );
    }).toSet();
  }

  Future<void> _moveToPlace(Place place, {double zoom = 16}) async {
    final controller = _mapController;

    if (controller == null) return;

    setState(() {
      _selectedPlaceId = place.id;
    });

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.lat, place.lng),
          zoom: zoom,
        ),
      ),
    );
  }

  Future<void> _fitPlaces(List<Place> places) async {
    final controller = _mapController;

    if (controller == null || places.isEmpty) return;

    if (places.length == 1) {
      await _moveToPlace(places.first, zoom: 15);
      return;
    }

    double minLat = places.first.lat;
    double maxLat = places.first.lat;
    double minLng = places.first.lng;
    double maxLng = places.first.lng;

    for (final place in places) {
      if (place.lat < minLat) minLat = place.lat;
      if (place.lat > maxLat) maxLat = place.lat;
      if (place.lng < minLng) minLng = place.lng;
      if (place.lng > maxLng) maxLng = place.lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await Future.delayed(const Duration(milliseconds: 250));

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  void _openDetails(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPlaceId = null;
    });
  }

  void _showPlaceSheet(Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final hasImage =
            place.images.isNotEmpty && place.images.first.isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Wrap(
              runSpacing: 14,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Image.network(
                        place.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: _imageFallback(),
                    ),
                  ),
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    _InfoPill(
                      label:
                          place.category.isEmpty ? 'General' : place.category,
                      color: primaryColor,
                      backgroundColor: softPrimary,
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(width: 8),
                    _InfoPill(
                      label:
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                      color: mutedText,
                      backgroundColor: Colors.grey.shade100,
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFE5A11A),
                    ),
                  ],
                ),
                if (place.description.trim().isNotEmpty)
                  Text(
                    place.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF444444),
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _moveToPlace(place);
                        },
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('Center'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openDetails(place);
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      color: softPrimary,
      child: const Center(
        child: Icon(
          Icons.place_rounded,
          color: primaryColor,
          size: 44,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<PlaceProvider>(
        builder: (context, placeProvider, child) {
          if (placeProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final validPlaces = placeProvider.places
              .where((place) => place.lat != 0 && place.lng != 0)
              .toList();

          if (validPlaces.isEmpty) {
            return const Center(
              child: Text(
                'No valid place locations found',
                style: TextStyle(color: mutedText),
              ),
            );
          }

          final filteredPlaces = _filterPlaces(validPlaces);
          final categories = _categories(validPlaces);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialCamera(validPlaces),
                markers: _markers(filteredPlaces),
                mapType: _mapType,
                onMapCreated: (controller) async {
                  _mapController = controller;

                  if (widget.initialPlace != null) {
                    await Future.delayed(const Duration(milliseconds: 400));
                    _moveToPlace(widget.initialPlace!);
                  }
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: true,
              ),

              // Top search area
              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    _MapSearchBar(
                      controller: _searchController,
                      resultCount: filteredPlaces.length,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _CategoryChip(
                              label: 'All',
                              selected: _selectedCategory == null,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            );
                          }

                          final category = categories[index - 1];

                          return _CategoryChip(
                            label: category,
                            selected: _selectedCategory == category,
                            onTap: () {
                              setState(() {
                                _selectedCategory =
                                    _selectedCategory == category
                                        ? null
                                        : category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Side controls
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 126,
                child: Column(
                  children: [
                    _FloatingMapButton(
                      icon: Icons.layers_rounded,
                      onTap: _toggleMapType,
                    ),
                    const SizedBox(height: 10),
                    _FloatingMapButton(
                      icon: Icons.fit_screen_rounded,
                      onTap: () => _fitPlaces(filteredPlaces),
                    ),
                  ],
                ),
              ),

              // Empty filtered state
              if (filteredPlaces.isEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 175,
                  left: 20,
                  right: 20,
                  child: _EmptySearchCard(
                    onClear: _clearSearch,
                  ),
                ),

              // Bottom carousel
              if (filteredPlaces.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredPlaces.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final place = filteredPlaces[index];

                        return _MapPlaceCard(
                          place: place,
                          selected: place.id == _selectedPlaceId,
                          onTap: () => _moveToPlace(place),
                          onDetails: () => _openDetails(place),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final int resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _MapSearchBar({
    required this.controller,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MapScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _MapScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: _MapScreenState.textColor,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search places on map...',
          hintStyle: const TextStyle(
            color: _MapScreenState.mutedText,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _MapScreenState.primaryColor,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _MapScreenState.mutedText,
                  ),
                  onPressed: onClear,
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '$resultCount',
                      style: const TextStyle(
                        color: _MapScreenState.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? _MapScreenState.primaryColor : _MapScreenState.cardColor,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? _MapScreenState.primaryColor
                  : _MapScreenState.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _MapScreenState.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingMapButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MapScreenState.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _MapScreenState.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: _MapScreenState.textColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _MapPlaceCard extends StatelessWidget {
  final Place place;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  const _MapPlaceCard({
    required this.place,
    required this.selected,
    required this.onTap,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = place.images.isNotEmpty && place.images.first.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _MapScreenState.cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected
                ? _MapScreenState.primaryColor
                : _MapScreenState.borderColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 92,
                height: 102,
                child: hasImage
                    ? Image.network(
                        place.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackImage(),
                      )
                    : _fallbackImage(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _MapScreenState.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.category.isEmpty ? 'General' : place.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _MapScreenState.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE5A11A),
                        size: 17,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _MapScreenState.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '(${place.reviewCount})',
                        style: const TextStyle(
                          color: _MapScreenState.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: onDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _MapScreenState.softPrimary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'View details',
                          style: TextStyle(
                            color: _MapScreenState.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: _MapScreenState.softPrimary,
      child: const Center(
        child: Icon(
          Icons.place_rounded,
          color: _MapScreenState.primaryColor,
          size: 34,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final Color? iconColor;

  const _InfoPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor ?? color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptySearchCard({
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _MapScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _MapScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: _MapScreenState.primaryColor,
            size: 34,
          ),
          const SizedBox(height: 8),
          const Text(
            'No places found on the map',
            style: TextStyle(
              color: _MapScreenState.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try another search or clear your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _MapScreenState.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear filters',
              style: TextStyle(
                color: _MapScreenState.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
