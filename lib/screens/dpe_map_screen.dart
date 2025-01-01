import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' show pi, log, tan, cos;
import '../services/ademe_api_service.dart';
import '../models/dpe_data.dart';

enum DpeGrade { all, a, b, c, d, e, f, g }

class DpeMapScreen extends StatefulWidget {
  const DpeMapScreen({super.key});

  @override
  State<DpeMapScreen> createState() => _DpeMapScreenState();
}

class _DpeMapScreenState extends State<DpeMapScreen> {
  final AdemeApiService _apiService = AdemeApiService();
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng _center = const LatLng(48.8566, 2.3522);
  DpeGrade _selectedGrade = DpeGrade.all;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        
        // Update center and move map in setState to ensure proper rebuild
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          // Move map to new position
          _mapController.move(_center, 15);
        });

        // Load DPE data after map has moved
        _loadDpeData();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Fallback to default location (Paris)
      setState(() {
        _center = const LatLng(48.8566, 2.3522);
        _mapController.move(_center, 15);
      });
      _loadDpeData();
    }
  }

  Future<Position> _getCurrentLocationWeb() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Fallback to Paris coordinates if location access is denied
      return Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<void> _loadDpeData() async {
    try {
      final xyz = _calculateXYZ();
      final dpeDataList = await _apiService.getDpeData(
        lat: _center.latitude,
        lng: _center.longitude,
        xyz: xyz,
      );

      setState(() {
        _markers = _getFilteredMarkers(dpeDataList);
      });
    } catch (e) {
      debugPrint('Error loading DPE data: $e');
    }
  }

  List<Marker> _getFilteredMarkers(List<DpeData> dpeDataList) {
    return dpeDataList
        .where((dpe) => _selectedGrade == DpeGrade.all || 
            dpe.energyGrade.toLowerCase() == _selectedGrade.name)
        .map((dpe) {
          return Marker(
            point: LatLng(dpe.latitude, dpe.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showDpeInfo(dpe),
              child: Container(
                decoration: BoxDecoration(
                  color: _getMarkerColor(dpe.energyGrade).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    dpe.energyGrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList();
  }

  void _showDpeInfo(DpeData dpe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DPE Grade: ${dpe.energyGrade}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getMarkerColor(dpe.energyGrade),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dpe.formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dpe.geoAddress.isNotEmpty) ...[
              Text(
                'Geo Address:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(dpe.geoAddress),
              const SizedBox(height: 8),
            ],
            Text(
              'DATE:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(dpe.dpeDate),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Consumption',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text('${dpe.energyValue} kWh/m²/an'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GES Grade',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text('${dpe.gesGrade} - ${dpe.gesValue} kgCO₂/m²/an'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarkerColor(String energyGrade) {
    switch (energyGrade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      case 'G':
        return Colors.red[900] ?? Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _calculateXYZ() {
    final zoom = _mapController.camera.zoom.round();
    final center = _mapController.camera.center;
    
    // Convert lat/lon to tile coordinates
    final x = ((center.longitude + 180.0) / 360.0 * (1 << zoom)).floor();
    final y = ((1.0 - log(tan(center.latitude * pi/180.0) + 
        1.0/cos(center.latitude * pi/180.0))/pi) / 2.0 * (1 << zoom)).floor();
    
    print('Calculated XYZ: $x,$y,$zoom'); // Debug print
    return '$x,$y,$zoom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte DPE'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<DpeGrade>(
              value: _selectedGrade,
              dropdownColor: Theme.of(context).primaryColor,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: DpeGrade.values.map((DpeGrade grade) {
                return DropdownMenuItem<DpeGrade>(
                  value: grade,
                  child: Text(
                    grade == DpeGrade.all ? 'Tous' : grade.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (DpeGrade? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedGrade = newValue;
                    _loadDpeData();
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDpeData,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocation();
              _mapController.move(_center, 15);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onMapEvent: (event) {
                if (event is MapEventMove) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _center = _mapController.camera.center;
                      _loadDpeData();
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: _markers,
                rotate: true, // Enable marker rotation if needed
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  tooltip: 'Zoom in',
                  child: const Icon(Icons.add),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 