import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceMapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final String placeName;
  final VoidCallback? onTap;

  const PlaceMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    required this.placeName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE26D45);
    const lightPrimary = Color(0xFFFBE8DF);

    final hasValidLocation = lat != 0 && lng != 0;

    if (!hasValidLocation) {
      return Container(
        color: lightPrimary,
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            size: 70,
            color: primaryColor,
          ),
        ),
      );
    }

    final position = LatLng(lat, lng);

    return Stack(
      children: [
        IgnorePointer(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('place_preview'),
                position: position,
                infoWindow: InfoWindow(title: placeName),
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}
