import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show pi, log, tan, cos;
import '../services/ademe_api_service.dart';
import '../services/dvf_api_service.dart';
import '../models/dpe_data.dart';
import '../models/dvf_data.dart';

enum DataLayer { dpe, dvf, both }
enum DpeGrade { all, a, b, c, d, e, f, g }

class PropertyMapScreen extends StatefulWidget {
  const PropertyMapScreen({super.key});

  @override
  State<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  final AdemeApiService _dpeService = AdemeApiService();
  final DvfApiService _dvfService = DvfApiService();
  final MapController _mapController = MapController();
  List<Marker> _dpeMarkers = [];
  List<Marker> _dvfMarkers = [];
  LatLng _center = const LatLng(48.8566, 2.3522);
  DpeGrade _selectedGrade = DpeGrade.all;
  DataLayer _selectedLayer = DataLayer.both;

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
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _mapController.move(_center, 15);
        });
        _loadData();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _center = const LatLng(48.8566, 2.3522);
        _mapController.move(_center, 15);
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selectedLayer == DataLayer.dpe || _selectedLayer == DataLayer.both) {
      await _loadDpeData();
    }
    if (_selectedLayer == DataLayer.dvf || _selectedLayer == DataLayer.both) {
      await _loadDvfData();
    }
  }

  Future<void> _loadDpeData() async {
    try {
      final xyz = _calculateXYZ();
      final dpeDataList = await _dpeService.getDpeData(
        lat: _center.latitude,
        lng: _center.longitude,
        xyz: xyz,
      );

      setState(() {
        _dpeMarkers = _getFilteredDpeMarkers(dpeDataList);
      });
    } catch (e) {
      debugPrint('Error loading DPE data: $e');
    }
  }

  Future<void> _loadDvfData() async {
    try {
      final dvfDataList = await _dvfService.getDvfData(
        lat: _center.latitude,
        lng: _center.longitude,
        radius: 1000,
      );

      setState(() {
        _dvfMarkers = _getDvfMarkers(dvfDataList);
      });
    } catch (e) {
      debugPrint('Error loading DVF data: $e');
    }
  }

  List<Marker> _getFilteredDpeMarkers(List<DpeData> dpeDataList) {
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
                  color: _getDpeColor(dpe.energyGrade).withOpacity(0.8),
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

  List<Marker> _getDvfMarkers(List<DvfData> dvfDataList) {
    return dvfDataList.map((dvf) {
      return Marker(
        point: LatLng(dvf.latitude, dvf.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showDvfInfo(dvf),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.euro,
                color: Colors.white,
                size: 20,
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
            Text(
              'DPE Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Grade: ${dpe.energyGrade}'),
            Text('Energy: ${dpe.energyValue} kWh/m²/an'),
            Text('GES: ${dpe.gesGrade} - ${dpe.gesValue} kgCO₂/m²/an'),
            Text('Address: ${dpe.geoAddress}'),
            Text('Date: ${dpe.formattedDate}'),
          ],
        ),
      ),
    );
  }

  void _showDvfInfo(DvfData dvf) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Price: ${dvf.price.toStringAsFixed(2)}€'),
            Text('Type: ${dvf.propertyType}'),
            Text('Rooms: ${dvf.numberOfRooms}'),
            Text('Area: ${dvf.buildingArea}m²'),
            Text('Address: ${dvf.fullAddress}'),
            Text('Date: ${dvf.formattedDate}'),
          ],
        ),
      ),
    );
  }

  Color _getDpeColor(String energyGrade) {
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
    final x = ((center.longitude + 180.0) / 360.0 * (1 << zoom)).floor();
    final y = ((1.0 - log(tan(center.latitude * pi/180.0) + 
        1.0/cos(center.latitude * pi/180.0))/pi) / 2.0 * (1 << zoom)).floor();
    return '$x,$y,$zoom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Map'),
        actions: [
          PopupMenuButton<DataLayer>(
            initialValue: _selectedLayer,
            onSelected: (DataLayer layer) {
              setState(() {
                _selectedLayer = layer;
                _loadData();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: DataLayer.both,
                child: Text('Show Both'),
              ),
              const PopupMenuItem(
                value: DataLayer.dpe,
                child: Text('DPE Only'),
              ),
              const PopupMenuItem(
                value: DataLayer.dvf,
                child: Text('DVF Only'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _center,
              zoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _loadData();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLayer == DataLayer.dpe || _selectedLayer == DataLayer.both)
                    ..._dpeMarkers,
                  if (_selectedLayer == DataLayer.dvf || _selectedLayer == DataLayer.both)
                    ..._dvfMarkers,
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  onPressed: () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
} 