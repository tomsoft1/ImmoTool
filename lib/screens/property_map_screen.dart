import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show pi, log, tan, cos, sin, sqrt, atan2;
import 'dart:async' show Timer;
import '../services/ademe_api_service.dart';
import '../services/dvf_api_service.dart';
import '../services/geo_api_service.dart';
import '../models/dpe_data.dart';
import '../models/dvf_data.dart';
import '../widgets/location_search_bar.dart';

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
  final GeoApiService _geoService = GeoApiService();
  final MapController _mapController = MapController();
  Timer? _mapMovementDebounce;
  LatLng? _lastLoadPosition;
  List<Marker> _dpeMarkers = [];
  List<Marker> _dvfMarkers = [];
  List<Polygon> _departmentBoundaries = [];
  List<Polygon> _communeBoundaries = [];
  LatLng _center = const LatLng(48.8566, 2.3522);
  DpeGrade _selectedGrade = DpeGrade.all;
  DataLayer _selectedLayer = DataLayer.both;
  Department? _selectedDepartment;
  Commune? _selectedCommune;
  bool _isLoadingBoundaries = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAllDepartmentBoundaries();
  }

  @override
  void dispose() {
    _mapMovementDebounce?.cancel();
    super.dispose();
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
    setState(() {
      _isLoadingData = true;
    });

    try {
      if (_selectedLayer == DataLayer.dpe || _selectedLayer == DataLayer.both) {
        await _loadDpeData();
      }
      if (_selectedLayer == DataLayer.dvf || _selectedLayer == DataLayer.both) {
        print('load DVF');
        await _loadDvfData();
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  List<LatLng> _convertCoordinates(List<dynamic> coordinates) {
    return coordinates.map<LatLng>((coord) {
      if (coord is List && coord.length >= 2) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }
      return const LatLng(0, 0);
    }).toList();
  }

  List<List<LatLng>> _processMultiPolygon(List<dynamic> coordinates) {
    return coordinates.map<List<LatLng>>((polygon) {
      if (polygon is List && polygon.isNotEmpty && polygon[0] is List) {
        return _convertCoordinates(polygon[0]);
      }
      return <LatLng>[];
    }).toList();
  }

  void _updateBoundaries(Map<String, dynamic>? geometry,
      {bool isDepartment = true}) {
    if (geometry == null) return;

    final List<List<LatLng>> polygons = [];
    if (geometry['type'] == 'MultiPolygon') {
      final coordinates = geometry['coordinates'] as List;
      polygons.addAll(_processMultiPolygon(coordinates));
    } else if (geometry['type'] == 'Polygon') {
      final coordinates = geometry['coordinates'] as List;
      if (coordinates.isNotEmpty) {
        polygons.add(_convertCoordinates(coordinates[0]));
      }
    }

    setState(() {
      if (isDepartment) {
        _departmentBoundaries = polygons
            .map((points) => Polygon(
                  points: points,
                  color: Colors.blue.withOpacity(0.1),
                  borderColor: Colors.blue.shade700,
                  borderStrokeWidth: 3,
                  isDotted: false,
                ))
            .toList();
      } else {
        _communeBoundaries = polygons
            .map((points) => Polygon(
                  points: points,
                  color: Colors.green.withOpacity(0.15),
                  borderColor: Colors.green.shade600,
                  borderStrokeWidth: 2,
                  isDotted: false,
                ))
            .toList();
      }
    });
  }

  Future<void> _loadDepartmentBoundaries(Department department) async {
    setState(() {
      _isLoadingBoundaries = true;
    });

    try {
      _selectedDepartment = department;

      // First, restore all department boundaries with default style
      await _loadAllDepartmentBoundaries();

      // Then highlight the selected department
      if (department.geometry != null) {
        final List<List<LatLng>> polygons = [];
        if (department.geometry!['type'] == 'MultiPolygon') {
          final coordinates = department.geometry!['coordinates'] as List;
          polygons.addAll(_processMultiPolygon(coordinates));
        } else if (department.geometry!['type'] == 'Polygon') {
          final coordinates = department.geometry!['coordinates'] as List;
          if (coordinates.isNotEmpty) {
            polygons.add(_convertCoordinates(coordinates[0]));
          }
        }

        setState(() {
          // Add highlighted polygon on top of others
          _departmentBoundaries.addAll(
            polygons.map((points) => Polygon(
                  points: points,
                  color: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue.shade900,
                  borderStrokeWidth: 3,
                  isDotted: false,
                )),
          );
        });
      }

      final communes =
          await _geoService.getCommunesByDepartment(department.code);
      if (communes.isNotEmpty) {
        _selectedCommune = communes.first;
        _updateBoundaries(_selectedCommune?.geometry, isDepartment: false);
      }
    } catch (e) {
      debugPrint('Error loading communes: $e');
    } finally {
      setState(() {
        _isLoadingBoundaries = false;
      });
    }
  }

  Future<void> _loadCommuneBoundaries(Commune commune) async {
    setState(() {
      _isLoadingBoundaries = true;
    });

    try {
      _selectedCommune = commune;
      _updateBoundaries(commune.geometry, isDepartment: false);

      final departments = await _geoService.getDepartments();
      _selectedDepartment = departments.firstWhere(
        (d) => d.code == commune.department,
        orElse: () => Department(code: '', name: '', region: ''),
      );
      _updateBoundaries(_selectedDepartment?.geometry, isDepartment: true);
    } catch (e) {
      debugPrint('Error loading department: $e');
    } finally {
      setState(() {
        _isLoadingBoundaries = false;
      });
    }
  }

  String _calculateBoundingBox() {
    final bounds = _mapController.camera.visibleBounds;
    final swCorner = bounds.southWest;
    final neCorner = bounds.northEast;

    // Format: "west,south,east,north"
    return '${swCorner.longitude},${swCorner.latitude},${neCorner.longitude},${neCorner.latitude}';
  }

  Future<void> _loadDpeData() async {
    try {
      final bbox = _calculateBoundingBox();
      final dpeDataList = await _dpeService.getDpeData(
          lat: _center.latitude, lng: _center.longitude, bbox: bbox);
      print(dpeDataList);
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
        .where((dpe) =>
            _selectedGrade == DpeGrade.all ||
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
    final zoom = _mapController.camera.zoom.round() - 1;
    final center = _mapController.camera.center;
    final x = ((center.longitude + 180.0) / 360.0 * (1 << zoom)).floor();
    final y = ((1.0 -
                log(tan(center.latitude * pi / 180.0) +
                        1.0 / cos(center.latitude * pi / 180.0)) /
                    pi) /
            2.0 *
            (1 << zoom))
        .floor();
    return '$x,$y,$zoom';
  }

  Future<void> _loadAllDepartmentBoundaries() async {
    setState(() {
      _isLoadingBoundaries = true;
    });

    try {
      final departments = await _geoService.getDepartments();
      final List<Polygon> boundaries = [];

      for (final department in departments) {
        if (department.geometry != null) {
          final List<List<LatLng>> polygons = [];
          if (department.geometry!['type'] == 'MultiPolygon') {
            final coordinates = department.geometry!['coordinates'] as List;
            polygons.addAll(_processMultiPolygon(coordinates));
          } else if (department.geometry!['type'] == 'Polygon') {
            final coordinates = department.geometry!['coordinates'] as List;
            if (coordinates.isNotEmpty) {
              polygons.add(_convertCoordinates(coordinates[0]));
            }
          }

          boundaries.addAll(
            polygons.map((points) => Polygon(
                  points: points,
                  color: Colors.blue.withOpacity(0.1),
                  borderColor: Colors.blue.shade700,
                  borderStrokeWidth: 2,
                  isDotted: false,
                )),
          );
        }
      }

      setState(() {
        _departmentBoundaries = boundaries;
      });
    } catch (e) {
      debugPrint('Error loading department boundaries: $e');
    } finally {
      setState(() {
        _isLoadingBoundaries = false;
      });
    }
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1 = point1.latitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double dLat = (point2.latitude - point1.latitude) * pi / 180;
    final double dLon = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  void _handleMapMovement(MapPosition position, bool hasGesture) {
    if (!hasGesture) return;

    // Cancel any pending debounce
    _mapMovementDebounce?.cancel();

    // Get the current center
    final currentCenter = position.center!;

    // If this is the first load or we've moved significantly (more than 500 meters)
    final shouldLoad = _lastLoadPosition == null ||
        _calculateDistance(_lastLoadPosition!, currentCenter) > 500;

    if (shouldLoad) {
      // Debounce the load for 500ms
      _mapMovementDebounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _center = currentCenter;
          _lastLoadPosition = currentCenter;
        });
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Map'),
        actions: [
          if (_isLoadingData || _isLoadingBoundaries)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
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
              onPositionChanged: _handleMapMovement,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolygonLayer(
                polygons: [..._departmentBoundaries, ..._communeBoundaries],
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLayer == DataLayer.dpe ||
                      _selectedLayer == DataLayer.both)
                    ..._dpeMarkers,
                  if (_selectedLayer == DataLayer.dvf ||
                      _selectedLayer == DataLayer.both)
                    ..._dvfMarkers,
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LocationSearchBar(
              onCommuneSelected: (commune) {
                setState(() {
                  _center = LatLng(commune.latitude, commune.longitude);
                  _mapController.move(_center, 15);
                });
                _loadCommuneBoundaries(commune);
                _loadData();
              },
            ),
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
