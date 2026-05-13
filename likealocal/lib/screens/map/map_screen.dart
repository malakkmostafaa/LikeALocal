import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../services/place_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PlaceService _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Column(
        children: [
          // Green banner
          Container(
            width: double.infinity,
            color: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              'Member 1 Map Active',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Place>>(
              stream: _placeService.getPlaces(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Map error: ${snapshot.error}'));
                }
                final places = snapshot.data ?? [];
                // Filter valid places with non-zero coordinates
                final validPlaces = places.where((p) => p.lat != 0 && p.lng != 0).toList();
                if (validPlaces.isEmpty) {
                  return const Center(child: Text('No valid place locations found'));
                }
                return FlutterMap(
                  options: MapOptions(
                    center: LatLng(validPlaces.first.lat, validPlaces.first.lng),
                    zoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.likealocal',
                    ),
                    MarkerLayer(
                      markers: validPlaces.map((place) {
                        return Marker(
                          point: LatLng(place.lat, place.lng),
                          width: 160,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: Text(
                                  place.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.location_pin, color: Colors.red, size: 36),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
