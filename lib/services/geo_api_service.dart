import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;

class Department {
  final String code;
  final String name;
  final String region;
  final Map<String, dynamic>? geometry;

  Department({
    required this.code,
    required this.name,
    required this.region,
    this.geometry,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: json['code'] ?? '',
      name: json['nom'] ?? '',
      region: json['region'] ?? '',
      geometry: json['geometry'],
    );
  }
}

class Commune {
  final String code;
  final String name;
  final String postalCode;
  final String department;
  final double latitude;
  final double longitude;
  final int population;
  final Map<String, dynamic>? geometry;

  Commune({
    required this.code,
    required this.name,
    required this.postalCode,
    required this.department,
    required this.latitude,
    required this.longitude,
    required this.population,
    this.geometry,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      code: json['code'] ?? '',
      name: json['nom'] ?? '',
      postalCode: json['codesPostaux']?.first ?? '',
      department: json['codeDepartement'] ?? '',
      latitude: double.tryParse(
              json['geometry']?['coordinates']?[1]?.toString() ?? '0') ??
          0,
      longitude: double.tryParse(
              json['geometry']?['coordinates']?[0]?.toString() ?? '0') ??
          0,
      population: json['population'] ?? 0,
      geometry: json['geometry'],
    );
  }
}

class GeoApiService {
  static const String baseUrl = 'https://geo.api.gouv.fr';
  static const String dvfBaseUrl = 'https://app.dvf.etalab.gouv.fr';

  // Cache for department geometries
  final Map<String, Map<String, dynamic>> _departmentGeometryCache = {};
  // Cache for departments list
  List<Department>? _departmentsCache;
  // Cache for commune geometries
  final Map<String, Map<String, dynamic>> _communeGeometryCache = {};

  // Get all departments with geometry
  Future<List<Department>> getDepartments() async {
    // Check cache first
    if (_departmentsCache != null) {
      print('Returning cached departments');
      return _departmentsCache!;
    }

    try {
      // First get the basic department info
      final deptResponse = await http.get(Uri.parse('$baseUrl/departements'));

      if (deptResponse.statusCode != 200) {
        throw Exception(
            'Failed to load departments: ${deptResponse.statusCode}');
      }

      final List<dynamic> deptData = json.decode(deptResponse.body);
      final departments =
          deptData.map((json) => Department.fromJson(json)).toList();

      // Then get the geometries from DVF API
      final geoResponse = await http
          .get(Uri.parse('$dvfBaseUrl/donneesgeo/departements-100m.geojson'));

      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        final features = geoData['features'] as List;
        // Match geometries with departments
        for (var i = 0; i < departments.length; i++) {
          final dept = departments[i];
          final geoFeature = features.firstWhere(
            (feature) => feature['properties']['code'] == dept.code,
            orElse: () => null,
          );

          if (geoFeature != null) {
            departments[i] = Department(
              code: dept.code,
              name: dept.name,
              region: dept.region,
              geometry: geoFeature['geometry'],
            );
            // Store in cache
            _departmentGeometryCache[dept.code] = geoFeature['geometry'];
          }
        }
      }

      // Store in cache
      _departmentsCache = departments;
      return departments;
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      return [];
    }
  }

  // Get department geometry from cache or DVF API
  Future<Map<String, dynamic>?> getDepartmentGeometry(String code) async {
    // Check cache first
    if (_departmentGeometryCache.containsKey(code)) {
      print('Returning cached department geometry');
      return _departmentGeometryCache[code];
    }

    try {
      final response = await http
          .get(Uri.parse('$dvfBaseUrl/donneesgeo/departements-100m.geojson'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        final feature = features.firstWhere(
          (feature) => feature['properties']['code'] == code,
          orElse: () => null,
        );

        if (feature != null) {
          final geometry = feature['geometry'] as Map<String, dynamic>;
          // Store in cache
          _departmentGeometryCache[code] = geometry;
          return geometry;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching department geometry: $e');
      return null;
    }
  }

  // Get communes by department code with caching
  Future<List<Commune>> getCommunesByDepartment(String departmentCode) async {
    final uri = Uri.parse(
        '$baseUrl/departements/$departmentCode/communes?format=geojson');

    print('Fetching communes by department: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['features'] as List).map((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;

          // Store commune geometry in cache
          final communeCode = properties['code'] as String;
          _communeGeometryCache[communeCode] = geometry;

          properties['geometry'] = geometry;
          return Commune.fromJson(properties);
        }).toList();
      } else {
        throw Exception('Failed to load communes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching communes: $e');
    }
  }

  // Search communes by name with caching
  Future<List<Commune>> searchCommunes(String query) async {
    if (query.length < 3) return [];

    final uri = Uri.parse('$baseUrl/communes').replace(
      queryParameters: {
        'nom': query,
        'boost': 'population',
        'limit': '5',
        'format': 'geojson',
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['features'] as List).map((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;

          // Store commune geometry in cache
          final communeCode = properties['code'] as String;
          _communeGeometryCache[communeCode] = geometry;

          properties['geometry'] = geometry;
          return Commune.fromJson(properties);
        }).toList();
      } else {
        throw Exception('Failed to search communes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching communes: $e');
    }
  }

  // Get commune by postal code with boundaries
  Future<List<Commune>> getCommunesByPostalCode(String postalCode) async {
    final uri = Uri.parse('$baseUrl/communes').replace(
      queryParameters: {
        'codePostal': postalCode,
        'format': 'geojson',
      },
    );

    print('Fetching communes by postal code: $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['features'] as List).map((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          properties['geometry'] = feature['geometry'];
          return Commune.fromJson(properties);
        }).toList();
      } else {
        throw Exception('Failed to load communes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching communes: $e');
    }
  }

  // Clear caches (useful when data might be stale)
  void clearCaches() {
    _departmentGeometryCache.clear();
    _departmentsCache = null;
    _communeGeometryCache.clear();
  }
}
