import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  LatLng? _currentLocation;

  bool _isLoadingLocation = true;

  static const LatLng _defaultLocation = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);

    if (widget.initialLat != null && widget.initialLng != null) {
      final initial = LatLng(widget.initialLat!, widget.initialLng!);

      setState(() {
        _selectedLocation = initial;
        _currentLocation = initial;
        _isLoadingLocation = false;
      });

      return;
    }

    try {
      final position = await _getCurrentPositionOrNull();

      final current = position == null
          ? _defaultLocation
          : LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = current;
        _selectedLocation = current;
        _isLoadingLocation = false;
      });
    } catch (_) {
      setState(() {
        _currentLocation = _defaultLocation;
        _selectedLocation = _defaultLocation;
        _isLoadingLocation = false;
      });
    }
  }

  Future<Position?> _getCurrentPositionOrNull() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage('Location services are disabled. Using Cairo as default.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied. Using Cairo as default.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. Using Cairo as default.',
      );
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Selected location'),
        ),
      );
    }

    if (_currentLocation != null &&
        _currentLocation!.latitude != _selectedLocation?.latitude &&
        _currentLocation!.longitude != _selectedLocation?.longitude) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Current location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _moveCamera(LatLng location, {double zoom = 16}) async {
    final controller = _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoom,
        ),
      ),
    );
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });

    _showMessage(
      'Selected: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
    );
  }

  void _useCurrentLocation() {
    final current = _currentLocation;

    if (current == null) return;

    setState(() {
      _selectedLocation = current;
    });

    _moveCamera(current);
  }

  void _confirmLocation() {
    final selected = _selectedLocation;

    if (selected == null) return;

    Navigator.of(context).pop({
      'lat': selected.latitude,
      'lng': selected.longitude,
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD96B41);
    const bgColor = Color(0xFFF7F4EF);

    final initialCamera = CameraPosition(
      target: _selectedLocation ?? _defaultLocation,
      zoom: 15,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Pick Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoadingLocation ? null : _useCurrentLocation,
            child: const Text(
              'Use Current',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCamera,
            markers: _markers(),
            onMapCreated: (controller) {
              _mapController = controller;

              final selected = _selectedLocation;
              if (selected != null) {
                _moveCamera(selected);
              }
            },
            onTap: _onMapTap,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
          ),
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 14),
                    Text('Getting your location...'),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedLocation == null
                          ? 'Tap the map to select a place location.'
                          : 'Selected: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: _selectedLocation == null || _isLoadingLocation
                  ? null
                  : _confirmLocation,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Confirm Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
