import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  LatLng? _currentLocation;

  bool _isLoadingLocation = true;
  bool _isSearching = false;

  String? _selectedAddress;

  static const LatLng _defaultLocation = LatLng(30.0444, 31.2357);

  static const Color primaryColor = Color(0xFFD96B41);
  static const Color bgColor = Color(0xFFF7F4EF);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);
  static const Color borderColor = Color(0xFFEEDDD2);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;

    setState(() => _isLoadingLocation = true);

    if (widget.initialLat != null && widget.initialLng != null) {
      final initial = LatLng(widget.initialLat!, widget.initialLng!);

      if (!mounted) return;

      setState(() {
        _selectedLocation = initial;
        _currentLocation = initial;
        _selectedAddress = 'Existing selected location';
        _isLoadingLocation = false;
      });

      return;
    }

    try {
      final position = await _getCurrentPositionOrNull();

      final current = position == null
          ? _defaultLocation
          : LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentLocation = current;
        _selectedLocation = current;
        _selectedAddress =
            position == null ? 'Default location: Cairo' : 'Current location';
        _isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentLocation = _defaultLocation;
        _selectedLocation = _defaultLocation;
        _selectedAddress = 'Default location: Cairo';
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
        _selectedLocation != null &&
        (_currentLocation!.latitude != _selectedLocation!.latitude ||
            _currentLocation!.longitude != _selectedLocation!.longitude)) {
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

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showMessage('Type a place name or address first.');
      return;
    }

    FocusScope.of(context).unfocus();

    if (!mounted) return;

    setState(() => _isSearching = true);

    try {
      final results = await locationFromAddress(query);

      if (!mounted) return;

      if (results.isEmpty) {
        _showMessage('No location found. Try a more specific search.');
        return;
      }

      final first = results.first;
      final location = LatLng(first.latitude, first.longitude);

      setState(() {
        _selectedLocation = location;
        _selectedAddress = query;
      });

      await _moveCamera(location, zoom: 16);

      _showMessage('Location found. You can adjust it by tapping the map.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not find this location. Try another search.');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _reverseGeocodeSelected(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (!mounted || placemarks.isEmpty) return;

      final place = placemarks.first;

      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.country,
      ].where((part) => part != null && part.trim().isNotEmpty).toList();

      setState(() {
        _selectedAddress =
            parts.isEmpty ? 'Selected map location' : parts.join(', ');
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedAddress = 'Selected map location';
      });
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = 'Selected map location';
    });

    _reverseGeocodeSelected(point);
  }

  Future<void> _useCurrentLocation() async {
    LatLng? current = _currentLocation;

    if (current == null) {
      setState(() => _isLoadingLocation = true);

      final position = await _getCurrentPositionOrNull();

      if (!mounted) return;

      current = position == null
          ? _defaultLocation
          : LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = current;
        _isLoadingLocation = false;
      });
    }

    setState(() {
      _selectedLocation = current;
      _selectedAddress = 'Current location';
    });

    await _moveCamera(current);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    setState(() {});
  }

  void _confirmLocation() {
    final selected = _selectedLocation;

    if (selected == null) {
      _showMessage('Choose a location first.');
      return;
    }

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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = CameraPosition(
      target: _selectedLocation ?? _defaultLocation,
      zoom: 15,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Pick Location',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _SearchCard(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  isSearching: _isSearching,
                  onSearch: _searchLocation,
                  onClear: _clearSearch,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _HelperCard(
                  selectedLocation: _selectedLocation,
                  selectedAddress: _selectedAddress,
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 106,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Use current location',
                  onTap: _isLoadingLocation ? null : _useCurrentLocation,
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: 'Center selected location',
                  onTap: _selectedLocation == null
                      ? null
                      : () => _moveCamera(_selectedLocation!),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _ConfirmLocationButton(
              enabled: _selectedLocation != null && !_isLoadingLocation,
              onPressed: _confirmLocation,
            ),
          ),
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.84),
              child: const Center(
                child: _LoadingLocationCard(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  const _SearchCard({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _LocationPickerScreenState.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _LocationPickerScreenState.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search place, street, or area...',
            hintStyle: const TextStyle(
              color: _LocationPickerScreenState.mutedText,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _LocationPickerScreenState.primaryColor,
            ),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _LocationPickerScreenState.primaryColor,
                      ),
                    ),
                  )
                : hasText
                    ? IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : IconButton(
                        onPressed: onSearch,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  final LatLng? selectedLocation;
  final String? selectedAddress;

  const _HelperCard({
    required this.selectedLocation,
    required this.selectedAddress,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedLocation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _LocationPickerScreenState.cardColor.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _LocationPickerScreenState.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _LocationPickerScreenState.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: _LocationPickerScreenState.primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: selected == null
                ? const Text(
                    'Search or tap the map to select the exact location.',
                    style: TextStyle(
                      color: _LocationPickerScreenState.textColor,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress ?? 'Selected location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _LocationPickerScreenState.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: _LocationPickerScreenState.mutedText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.white.withOpacity(0.55)
                  : _LocationPickerScreenState.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _LocationPickerScreenState.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: onTap == null
                  ? Colors.grey
                  : _LocationPickerScreenState.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmLocationButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ConfirmLocationButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.check_circle_rounded),
      label: const Text('Confirm Location'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _LocationPickerScreenState.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class _LoadingLocationCard extends StatelessWidget {
  const _LoadingLocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: _LocationPickerScreenState.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _LocationPickerScreenState.borderColor),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: _LocationPickerScreenState.primaryColor,
          ),
          SizedBox(height: 14),
          Text(
            'Getting your location...',
            style: TextStyle(
              color: _LocationPickerScreenState.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
