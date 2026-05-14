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

  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(30.0444, 31.2357),
    zoom: 12,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  CameraPosition _initialCamera(List<Place> validPlaces) {
    final initial = widget.initialPlace;

    if (initial != null && initial.lat != 0 && initial.lng != 0) {
      return CameraPosition(
        target: LatLng(initial.lat, initial.lng),
        zoom: 15,
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

  Set<Marker> _markers(List<Place> places) {
    return places.map((place) {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: '${place.category} • ${place.rating.toStringAsFixed(1)} ★',
        ),
        onTap: () => _showPlaceSheet(place),
      );
    }).toSet();
  }

  Future<void> _moveToPlace(Place place) async {
    final controller = _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.lat, place.lng),
          zoom: 16,
        ),
      ),
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

  void _showPlaceSheet(Place place) {
    const primaryColor = Color(0xFFD96B41);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8F6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              runSpacing: 14,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE5A11A),
                    ),
                    Text(
                      '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  place.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF7F4EF),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<PlaceProvider>(
        builder: (context, placeProvider, child) {
          if (placeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final validPlaces = placeProvider.places
              .where((place) => place.lat != 0 && place.lng != 0)
              .toList();

          if (validPlaces.isEmpty) {
            return const Center(
              child: Text('No valid place locations found'),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialCamera(validPlaces),
                markers: _markers(validPlaces),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: true,
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, color: primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${validPlaces.length} places found',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
