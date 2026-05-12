import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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
  late MapController _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;

  final List<Marker> _markers = [];
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled. Please enable them in settings.');
        _setDefaultLocation();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied.');
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied.');
        _setDefaultLocation();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = widget.initialLat != null && widget.initialLng != null
              ? LatLng(widget.initialLat!, widget.initialLng!)
              : _currentLocation;
          _isLoadingLocation = false;
        });

        // Move camera to location after a brief delay to ensure map is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _selectedLocation != null) {
            _mapController.move(_selectedLocation!, 15);
          }
          _updateMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showLocationError('Unable to get current location. Using default location.');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentLocation = const LatLng(30.0444, 31.2357); // Cairo, Egypt
        _selectedLocation = widget.initialLat != null && widget.initialLng != null
            ? LatLng(widget.initialLat!, widget.initialLng!)
            : _currentLocation;
        _isLoadingLocation = false;
      });

      _updateMarkers();
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Add marker for selected location
    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          point: _selectedLocation!,
          width: 80,
          height: 80,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }

    // Add marker for current location
    if (_currentLocation != null && _selectedLocation != _currentLocation) {
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    setState(() {});
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _updateMarkers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop({
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      });
    }
  }

  void _useCurrentLocation() {
    if (_currentLocation != null) {
      setState(() {
        _selectedLocation = _currentLocation;
      });
      _updateMarkers();

      _mapController.move(_selectedLocation!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _selectedLocation ??
        (widget.initialLat != null && widget.initialLng != null
            ? LatLng(widget.initialLat!, widget.initialLng!)
            : const LatLng(30.0444, 31.2357)); // Default to Cairo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          if (_currentLocation != null)
            TextButton(
              onPressed: _useCurrentLocation,
              child: const Text(
                'Use Current',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialPosition,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.likealocal',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),

          // Loading overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                  ],
                ),
              ),
            ),

          // Instructions overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tap on the map to select a location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedLocation != null
                          ? 'Selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                          : 'No location selected',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? _confirmLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD45A38),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}