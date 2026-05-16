import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/place.dart';

class PlaceMapScreen extends StatefulWidget {
  final Place place;

  const PlaceMapScreen({
    super.key,
    required this.place,
  });

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  GoogleMapController? _mapController;

  static const Color backgroundColor = Color(0xFFF7F4EF);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _placeLocation {
    return LatLng(widget.place.lat, widget.place.lng);
  }

  Set<Marker> get _markers {
    return {
      Marker(
        markerId: MarkerId(widget.place.id),
        position: _placeLocation,
        infoWindow: InfoWindow(
          title: widget.place.name,
          snippet: widget.place.category,
        ),
      ),
    };
  }

  Future<void> _recenter() async {
    final controller = _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _placeLocation,
          zoom: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _placeLocation,
              zoom: 16,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _PlaceMapInfoCard(
              place: place,
              onRecenter: _recenter,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 145,
            child: _MapFloatingButton(
              icon: Icons.center_focus_strong_rounded,
              onTap: _recenter,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceMapInfoCard extends StatelessWidget {
  final Place place;
  final VoidCallback onRecenter;

  const _PlaceMapInfoCard({
    required this.place,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _PlaceMapScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _PlaceMapScreenState.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _PlaceMapScreenState.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: _PlaceMapScreenState.primaryColor,
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
                    color: _PlaceMapScreenState.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PlaceMapScreenState.mutedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${place.lat.toStringAsFixed(5)}, ${place.lng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: _PlaceMapScreenState.mutedText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRecenter,
            icon: const Icon(
              Icons.my_location_rounded,
              color: _PlaceMapScreenState.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFloatingButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _PlaceMapScreenState.cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _PlaceMapScreenState.borderColor,
            ),
          ),
          child: const Icon(
            Icons.center_focus_strong_rounded,
            color: _PlaceMapScreenState.primaryColor,
          ),
        ),
      ),
    );
  }
}
