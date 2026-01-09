import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:collection/collection.dart';
import 'dart:math' show cos, sin, sqrt, atan2;
import 'dart:async' show Timer;
import 'package:provider/provider.dart';
import '../services/ademe_api_service.dart';
import '../services/dvf_api_service.dart';
import '../services/geo_api_service.dart';
import '../services/backend_api_service.dart';
import '../models/dpe_data.dart';
import '../models/parcel_data.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/dpe_marker_with_badge.dart';
import '../widgets/grouped_dpe_bottom_sheet.dart';
import '../widgets/property_info_card.dart';
import '../widgets/dvf_marker_with_badge.dart';
import '../widgets/grouped_dvf_bottom_sheet.dart';
import '../widgets/dvf_info_card.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';
//import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
// ignore_for_file: avoid_print

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
  final BackendApiService _backendService = BackendApiService();
  final GeoApiService _geoService = GeoApiService();
  final MapController _mapController = MapController();
  Timer? _mapMovementDebounce;
  LatLng? _lastLoadPosition;
  List<Marker> _dpeMarkers = [];
  List<Marker> _dvfMarkers = [];
  List<Marker> _parcelTransactionMarkers = [];
  List<Polygon> _departmentBoundaries = [];
  List<Polygon> _communeBoundaries = [];
  List<Polygon> _parcelBoundaries = [];
  LatLng _center = const LatLng(48.8566, 2.3522);
  final DpeGrade _selectedGrade = DpeGrade.all;
  DataLayer _selectedLayer = DataLayer.both;
  Department? _selectedDepartment;
  Commune? _selectedCommune;
  bool _isLoadingBoundaries = false;
  bool _isLoadingData = false;
  bool _showParcels = true;
  bool _showSearchBar = false;
  String? _selectedParcelId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
        _loadDataBasedOnZoom(15);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _center = const LatLng(48.8566, 2.3522);
        _mapController.move(_center, 15);
      });
      _loadDataBasedOnZoom(15);
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
      if (_showParcels && _selectedCommune != null) {
        await _loadParcels(_selectedCommune!.code);
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadDataBasedOnZoom(double zoom) async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Clear existing boundaries and data
      setState(() {
        _departmentBoundaries.clear();
        _communeBoundaries.clear();
        _parcelBoundaries.clear();
        _dpeMarkers.clear();
        _dvfMarkers.clear();
        _parcelTransactionMarkers.clear();
      });

      if (zoom < 8) {
        // Low zoom: Show only departments
        print('load all department boundaries');
        await _loadAllDepartmentBoundaries();
      } else if (zoom < 12) {
        // Medium zoom: Show departments and detect commune
        print(
            'load all department boundaries and detect commune for current position');
        await _loadAllDepartmentBoundaries();
        await _loadCommunesForCurrentPosition();
      } else {
        // High zoom: Show departments, detect commune, and parcels
        print(
            'load all department boundaries, detect commune and parcels for current position');
        await _loadAllDepartmentBoundaries();
        await _loadCommunesForCurrentPosition();
        await _loadParcelsForCurrentPosition();
      }

      // Load DPE and DVF data based on selected layer
      if (_selectedLayer == DataLayer.dpe || _selectedLayer == DataLayer.both) {
        await _loadDpeData();
      }
      if (_selectedLayer == DataLayer.dvf || _selectedLayer == DataLayer.both) {
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

      // Load parcels when commune is selected
      if (_showParcels) {
        await _loadParcels(commune.code);
      }
    } catch (e) {
      debugPrint('Error loading department: $e');
    } finally {
      setState(() {
        _isLoadingBoundaries = false;
      });
    }
  }

  Future<void> _loadParcels(String communeCode) async {
    try {
      final parcels = await _dvfService.getParcelles(communeCode);
      final List<Polygon> parcelPolygons = [];
      final List<Marker> transactionMarkers = [];

      for (final parcel in parcels) {
        // Load all DVF data for this commune once
        List<ImmoDataDvf> allDvfData = [];
        try {
          allDvfData = await _dvfService.getDvfData(
              communeCode: communeCode,
              parcelCode: parcel.prefix +
                  parcel.section); // Get all data for the commune
        } catch (e) {
          debugPrint('Error loading DVF data for commune: $e');
        }
        final polygonPoints = parcel.getPolygonPoints();
        if (polygonPoints.isNotEmpty) {
          parcelPolygons.add(
            Polygon(
              points: polygonPoints.first,
              color: parcel.id == _selectedParcelId
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.blue.withOpacity(0.1),
              borderColor: parcel.id == _selectedParcelId
                  ? Colors.blue.shade700
                  : Colors.blue.shade300,
              borderStrokeWidth: parcel.id == _selectedParcelId ? 2.0 : 0.5,
              isDotted: false,
              label: parcel.id,
            ),
          );

          // Check if this parcel has transactions using the pre-loaded data
          _checkParcelTransactionsFromData(
              parcel, allDvfData, transactionMarkers);
        }
      }

      setState(() {
        _parcelBoundaries = parcelPolygons;
        _parcelTransactionMarkers = transactionMarkers;
      });
    } catch (e) {
      debugPrint('Error loading parcels: $e');
    }
  }

  Future<void> _loadCommunesForCurrentPosition() async {
    try {
      print('load communes for current position');
      // Find the department that contains the current position
      final departments = await _geoService.getDepartments();
      Department? containingDepartment;

      for (final department in departments) {
        if (department.geometry != null &&
            _isPointInDepartment(_center, department)) {
          containingDepartment = department;
          break;
        }
      }
      print('containingDepartment: ${containingDepartment?.code}');
      if (containingDepartment != null) {
        // Load communes for this department
        final communes = await _geoService
            .getCommunesByDepartment(containingDepartment.code);

        // Find the closest commune to current position
        // Since communes are points, we'll find the closest one
        Commune? closestCommune;
        double minDistance = double.infinity;

        for (final commune in communes) {
          final distance = _calculateDistance(
              _center, LatLng(commune.latitude, commune.longitude));
          if (distance < minDistance) {
            minDistance = distance;
            closestCommune = commune;
          }
        }

        print(
            'closestCommune: ${closestCommune?.name} (${closestCommune?.code})');

        setState(() {
          _selectedDepartment = containingDepartment;
          _selectedCommune = closestCommune;
          // Clear commune boundaries since we don't have polygon data
          _communeBoundaries.clear();
        });
      }
    } catch (e) {
      debugPrint('Error loading communes for current position: $e');
    }
  }

  Future<void> _loadParcelsForCurrentPosition() async {
    if (_selectedCommune != null) {
      await _loadParcels(_selectedCommune!.code);
    }
  }

  void _checkParcelTransactionsFromData(ParcelData parcel,
      List<ImmoDataDvf> allDvfData, List<Marker> transactionMarkers) {
    try {
      // Filter transactions for this specific parcel
      final parcelTransactions = allDvfData
          .where((dvf) => dvf.location.addressId == parcel.id)
          .toList();

      // If there are transactions, add a marker
      if (parcelTransactions.isNotEmpty) {
        final polygonPoints = parcel.getPolygonPoints();
        if (polygonPoints.isNotEmpty) {
          // Calculate the center of the parcel polygon
          final center = _calculatePolygonCenter(polygonPoints.first);

          transactionMarkers.add(
            Marker(
              point: center,
              width: 20,
              height: 20,
              child: GestureDetector(
                onTap: () =>
                    _showParcelTransactionInfo(parcel, parcelTransactions),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.euro,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking parcel transactions: $e');
    }
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    double latSum = 0;
    double lngSum = 0;

    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return LatLng(latSum / points.length, lngSum / points.length);
  }

  void _showParcelTransactionInfo(
      ParcelData parcel, List<ImmoDataDvf> transactions) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parcel with Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Parcel ID: ${parcel.id}'),
              Text('Commune: ${parcel.communeCode}'),
              Text('Area: ${parcel.area}m²'),
              const SizedBox(height: 16),
              Text(
                'Transactions (${transactions.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...transactions.map((dvf) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${dvf.txDate}'),
                          Text('Price: ${dvf.price.toStringAsFixed(2)}€'),
                          Text('Type: ${dvf.realtyType}'),
                          if (dvf.attributes.livingArea! > 0)
                            Text('Area: ${dvf.attributes.livingArea}m²'),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPointInDepartment(LatLng point, Department department) {
    if (department.geometry == null) return false;

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

    for (final polygon in polygons) {
      if (_isPointInPolygon(point, polygon)) {
        return true;
      }
    }
    return false;
  }

  void _showParcelInfo(ParcelData parcel) async {
    setState(() {
      _selectedParcelId = parcel.id;
    });
    _loadParcels(_selectedCommune?.code ?? "75111");

    // Load DVF data for the selected parcel
    try {
      // Load DVF data using parcel ID
      final dvfDataList = await _dvfService.getDvfData(
          communeCode: parcel.communeCode,
          parcelCode: parcel.prefix + parcel.section);
      // Sort transactions by date, most recent first
      final filteredDvfDataList = dvfDataList
          .where((dvf) => dvf.location.addressId == parcel.id)
          .toList()
        ..sort((a, b) => b.txDate.compareTo(a.txDate));

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parcel Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('ID: ${parcel.id}'),
                Text('Commune: ${parcel.communeCode}'),
                Text('Section: ${parcel.section}'),
                Text('Number: ${parcel.number}'),
                Text('Area: ${parcel.area}m²'),
                if (dvfDataList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Transaction History (${filteredDvfDataList.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...filteredDvfDataList.map((dvf) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${dvf.txDate}'),
                              Text('Price: ${dvf.price.toStringAsFixed(2)}€'),
                              Text('Type: ${dvf.realtyType}'),
                              if (dvf.attributes.livingArea! > 0)
                                Text('Area: ${dvf.attributes.livingArea}m²'),
                            ],
                          ),
                        ),
                      )),
                ] else
                  const Text('No transaction history found for this parcel'),
              ],
            ),
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedParcelId = null;
        });
        _loadParcels(_selectedCommune?.code ?? "75111");
      });
    } catch (e) {
      debugPrint('Error loading DVF data for parcel: $e');
      // Show parcel info without DVF data if there's an error
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parcel Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('ID: ${parcel.id}'),
              Text('Commune: ${parcel.communeCode}'),
              Text('Section: ${parcel.section}'),
              Text('Number: ${parcel.number}'),
              Text('Area: ${parcel.area}m²'),
              const Text('Error loading transaction history'),
            ],
          ),
        ),
      ).then((_) {
        setState(() {
          _selectedParcelId = null;
        });
        _loadParcels(_selectedCommune?.code ?? "75111");
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

  /// Group DPE records by EXACT normalized full address
  ///
  /// Returns a map where keys are normalized FULL addresses (trimmed, lowercase)
  /// and values are lists of DPE records at that EXACT address only.
  /// Only groups if addresses match exactly, not by proximity.
  /// Skips invalid coordinates (default Paris coordinates) and empty addresses.
  Map<String, List<DpeData>> _groupDpeByAddress(List<DpeData> dpeList) {
    final Map<String, List<DpeData>> grouped = {};

    for (final dpe in dpeList) {
      // Skip invalid coordinates (default Paris)
      if ((dpe.latitude - 48.8566).abs() < 0.0001 &&
          (dpe.longitude - 2.3522).abs() < 0.0001) {
        continue;
      }

      // Normalize FULL address for exact matching
      final normalizedAddress = dpe.address.trim().toLowerCase();

      // Skip if address is empty or too short (less than 5 characters)
      if (normalizedAddress.isEmpty || normalizedAddress.length < 5) {
        continue;
      }

      // Only group if EXACT address match
      grouped.putIfAbsent(normalizedAddress, () => []).add(dpe);
    }

    return grouped;
  }

  /// Group DVF transactions by EXACT normalized full address
  ///
  /// Returns a map where keys are normalized FULL addresses (number + street + postal code + city)
  /// and values are lists of DVF transactions at that EXACT address only.
  /// Only groups if addresses match exactly, not by proximity.
  Map<String, List<ImmoDataDvf>> _groupDvfByAddress(List<ImmoDataDvf> dvfList) {
    final Map<String, List<ImmoDataDvf>> grouped = {};

    for (final dvf in dvfList) {
      // Build complete normalized address: number + street + postal code + city
      // Only group if EXACT address match
      final addressParts = [
        dvf.location.streetNumber.trim(),
        dvf.location.streetName.trim(),
        dvf.location.postCode.trim(),
        dvf.location.cityName.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      final normalizedAddress = addressParts.toLowerCase();

      // Skip if address is empty or invalid
      if (normalizedAddress.isEmpty) {
        continue;
      }

      grouped.putIfAbsent(normalizedAddress, () => []).add(dvf);
    }

    return grouped;
  }

  Future<void> _loadDpeData() async {
    try {
      // Get map bounds for backend API
      final bounds = _mapController.camera.visibleBounds;
      final north = bounds.north;
      final south = bounds.south;
      final east = bounds.east;
      final west = bounds.west;

      print(
          'Loading DPE data from backend for bounds: N=$north, S=$south, E=$east, W=$west');

      // Use backend API instead of direct ADEME API
      final dpeDataList = await _backendService.getDpeRecords(
        north: north,
        south: south,
        east: east,
        west: west,
      );

      print('Loaded ${dpeDataList.length} DPE entries from backend');
      final markers = _getFilteredDpeMarkers(dpeDataList);
      print('Created ${markers.length} DPE markers');
      setState(() {
        _dpeMarkers = markers;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading DPE data: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback to direct API if backend is unavailable
      debugPrint('Attempting fallback to direct ADEME API...');
      try {
        final bbox = _calculateBoundingBox();
        final settings = context.read<SettingsProvider>();
        final dpeDataList = await _dpeService.getDpeDataV1(
            lat: _center.latitude,
            lng: _center.longitude,
            bbox: bbox,
            settings: settings);
        print('Loaded ${dpeDataList.length} DPE entries from fallback API');
        final markers = _getFilteredDpeMarkers(dpeDataList);
        setState(() {
          _dpeMarkers = markers;
        });
      } catch (fallbackError) {
        debugPrint('Fallback also failed: $fallbackError');
      }
    }
  }

  Future<void> _loadDvfData() async {
    try {
      // Get map bounds for backend API
      final bounds = _mapController.camera.visibleBounds;
      final north = bounds.north;
      final south = bounds.south;
      final east = bounds.east;
      final west = bounds.west;

      print(
          'Loading DVF data from backend for bounds: N=$north, S=$south, E=$east, W=$west');

      // Use backend API instead of direct DVF API
      final dvfDataList = await _backendService.getDvfTransactions(
        north: north,
        south: south,
        east: east,
        west: west,
      );

      print('Loaded ${dvfDataList.length} DVF transactions from backend');
      setState(() {
        _dvfMarkers = _getDvfMarkers(dvfDataList);
      });
    } catch (e) {
      debugPrint('Error loading DVF data: $e');

      // Fallback to direct API if backend is unavailable
      if (_selectedCommune != null) {
        debugPrint('Attempting fallback to direct DVF API...');
        try {
          final dvfDataList = await _dvfService.getDvfData(
              communeCode: _selectedCommune!.code,
              parcelCode: _selectedParcelId ?? "000BK");
          print(
              'Loaded ${dvfDataList.length} DVF transactions from fallback API');
          setState(() {
            _dvfMarkers = _getDvfMarkers(dvfDataList);
          });
        } catch (fallbackError) {
          debugPrint('Fallback also failed: $fallbackError');
        }
      }
    }
  }

  /// Create DPE markers with grouping by address and count badges
  ///
  /// Filters by selected grade, groups by address, and creates markers
  /// with DpeMarkerWithBadge widget showing property count.
  List<Marker> _getFilteredDpeMarkers(List<DpeData> dpeDataList) {
    print(
        'Filtering ${dpeDataList.length} DPE entries, selected grade: ${_selectedGrade.name}');

    // 1. Filter by grade first (existing logic)
    final filtered = dpeDataList.where((dpe) {
      final matches = _selectedGrade == DpeGrade.all ||
          dpe.energyGrade.toLowerCase() == _selectedGrade.name;
      if (!matches) {
        print(
            'Filtered out DPE: grade=${dpe.energyGrade}, lat=${dpe.latitude}, lng=${dpe.longitude}');
      }
      return matches;
    }).toList();

    print('Filtered to ${filtered.length} DPE entries');

    // 2. NEW: Group by EXACT address
    final grouped = _groupDpeByAddress(filtered);
    print('Grouped into ${grouped.length} unique addresses (EXACT match only)');

    // Log grouped addresses with multiple properties
    for (final entry in grouped.entries) {
      if (entry.value.length > 1) {
        print(
            '  → Address "${entry.key}" has ${entry.value.length} DPE records (will show badge)');
      }
    }

    // 3. NEW: Create markers with badges
    final markers = grouped.entries.map((entry) {
      final dpeList = entry.value;
      final count = dpeList.length;

      // Use first DPE for coordinates and primary grade
      final primaryDpe = dpeList.first;

      return Marker(
        point: LatLng(primaryDpe.latitude, primaryDpe.longitude),
        width: 40, // Increased from 30 for better touch target
        height: 40,
        child: GestureDetector(
          onTap: () => count > 1
              ? _showGroupedDpeInfo(dpeList)
              : _showDpeInfo(primaryDpe),
          child: DpeMarkerWithBadge(
            energyGrade: primaryDpe.energyGrade,
            count: count,
            color: _getDpeColor(primaryDpe.energyGrade),
          ),
        ),
      );
    }).toList();

    print('Created ${markers.length} grouped DPE markers');
    return markers;
  }

  /// Create DVF markers with grouping by address and count badges
  ///
  /// Groups transactions by address and creates markers
  /// with DvfMarkerWithBadge widget showing transaction count.
  List<Marker> _getDvfMarkers(List<ImmoDataDvf> dvfDataList) {
    print('Creating DVF markers for ${dvfDataList.length} transactions');

    // Group by EXACT address
    final grouped = _groupDvfByAddress(dvfDataList);
    print('Grouped into ${grouped.length} unique addresses (EXACT match only)');

    // Log grouped addresses with multiple transactions
    for (final entry in grouped.entries) {
      if (entry.value.length > 1) {
        print(
            '  → Address "${entry.key}" has ${entry.value.length} DVF transactions (will show badge)');
      }
    }

    // Create markers with badges
    final markers = grouped.entries.map((entry) {
      final dvfList = entry.value;
      final count = dvfList.length;

      // Use first transaction for coordinates
      final primaryDvf = dvfList.first;

      return Marker(
        point: LatLng(
            primaryDvf.location.latitude, primaryDvf.location.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => count > 1
              ? _showGroupedDvfInfo(dvfList)
              : _showDvfInfo(primaryDvf),
          child: DvfMarkerWithBadge(
            count: count,
            color: Colors.blue,
          ),
        ),
      );
    }).toList();

    print('Created ${markers.length} grouped DVF markers');
    return markers;
  }

  /// Show bottom sheet for grouped DPE data (multiple properties at same address)
  ///
  /// Displays modern Material 3 sheet with:
  /// - Address header
  /// - Statistics (count, avg energy)
  /// - Grade distribution
  /// - Scrollable list of all properties
  void _showGroupedDpeInfo(List<DpeData> dpeList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GroupedDpeBottomSheet(
          dpeList: dpeList,
        ),
      ),
    );
  }

  /// Show bottom sheet for single DPE data
  ///
  /// Displays simplified Material 3 sheet using PropertyInfoCard
  /// for consistency with grouped view.
  void _showDpeInfo(DpeData dpe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Use PropertyInfoCard widget for consistency
            PropertyInfoCard(
              dpe: dpe,
              index: 1,
              color: _getDpeColor(dpe.energyGrade),
            ),
          ],
        ),
      ),
    );
  }

  /// Show bottom sheet for grouped DVF transactions (multiple at same address)
  ///
  /// Displays modern Material 3 sheet with:
  /// - Address header
  /// - Statistics (count, avg price, price range)
  /// - Property type distribution
  /// - Scrollable list of all transactions
  void _showGroupedDvfInfo(List<ImmoDataDvf> dvfList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GroupedDvfBottomSheet(
          dvfList: dvfList,
        ),
      ),
    );
  }

  /// Show bottom sheet for single DVF transaction
  ///
  /// Displays simplified Material 3 sheet using DvfInfoCard
  /// for consistency with grouped view.
  void _showDvfInfo(ImmoDataDvf dvf) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Use DvfInfoCard widget for consistency
            DvfInfoCard(
              dvf: dvf,
              index: 1,
            ),
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
                  borderColor: Colors.black54,
                  borderStrokeWidth: 0.5,
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

    // Get the current center and zoom
    final currentCenter = position.center!;
    final currentZoom = position.zoom;

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
        _loadDataBasedOnZoom(currentZoom ?? 15);
      });
    }
  }

  // Add this helper method to check if a point is inside a polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int i = 0, j = polygon.length - 1;

    for (i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
          // Add parcel toggle switch
          if (_selectedCommune != null)
            Switch(
              value: _showParcels,
              onChanged: (value) async {
                setState(() {
                  _showParcels = value;
                  if (!value) {
                    _parcelBoundaries.clear();
                  }
                });
                if (value && _selectedCommune != null) {
                  await _loadParcels(_selectedCommune!.code);
                }
              },
              activeColor: Colors.orange,
            ),
          PopupMenuButton<DataLayer>(
            icon: const Icon(Icons.layers),
            tooltip: 'Select layers',
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
          const SizedBox(width: 8), // Add some padding at the end
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
              onTap: (tapPosition, point) {
                // Find tapped parcel
                for (final polygon in _parcelBoundaries) {
                  if (polygon.label != null &&
                      _isPointInPolygon(point, polygon.points)) {
                    // Find and show parcel info
                    _dvfService
                        .getParcelles(_selectedCommune?.code ?? "75111")
                        .then((parcels) {
                      final tappedParcel = parcels.firstWhereOrNull(
                        (p) => p.id == polygon.label,
                      );
                      if (tappedParcel != null) {
                        _showParcelInfo(tappedParcel);
                      }
                    });
                    break;
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.digiwiz.immotools',
              ),
              PolygonLayer(
                polygons: [
                  ..._departmentBoundaries,
                  ..._communeBoundaries,
                  ..._parcelBoundaries,
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLayer == DataLayer.dpe ||
                      _selectedLayer == DataLayer.both)
                    ..._dpeMarkers,
                  if (_selectedLayer == DataLayer.dvf ||
                      _selectedLayer == DataLayer.both)
                    ..._dvfMarkers,
                  // Always show parcel transaction markers when parcels are visible
                  if (_showParcels && _parcelTransactionMarkers.isNotEmpty)
                    ..._parcelTransactionMarkers,
                ],
              ),
            ],
          ),
          if (_showSearchBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LocationSearchBar(
                onCommuneSelected: (commune) {
                  setState(() {
                    _center = LatLng(commune.latitude, commune.longitude);
                    _mapController.move(_center, 15);
                    _showSearchBar = false; // Hide search bar after selection
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
