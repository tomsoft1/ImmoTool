import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/dvf_data.dart';
import '../models/parcel_data.dart';

class DvfApiService {
  static const String baseUrl = 'https://app.dvf.etalab.gouv.fr/api';
  static const String cadastreUrl = 'https://cadastre.data.gouv.fr';

  // Cache for parcel data
  final Map<String, List<ParcelData>> _parcelCache = {};
  final Map<String, DateTime> _parcelCacheTimestamp = {};
  // Cache for DVF data
  final Map<String, List<DvfData>> _dvfCache = {};
  final Map<String, DateTime> _dvfCacheTimestamp = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  String _getDvfCacheKey(String communeCode, String parcelCode) {
    return '${communeCode}_${parcelCode}';
  }

  Future<List<DvfData>> getDvfData({
    required String communeCode,
    required String parcelCode,
    String? startDate,
    String? endDate,
  }) async {
    final cacheKey = _getDvfCacheKey(communeCode, parcelCode);

    // Check cache first
    if (_dvfCache.containsKey(cacheKey)) {
      final timestamp = _dvfCacheTimestamp[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        debugPrint('Returning cached DVF data for $cacheKey');
        return _dvfCache[cacheKey]!;
      }
    }

    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse('$baseUrl/mutations3/$communeCode/$parcelCode')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Fetching DVF data from: ${uri.toString()}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Found ${data['mutations']?.length ?? 0} DVF entries');

        if (data['mutations'] == null) {
          return [];
        }

        final List<DvfData> dvfDataList = (data['mutations'] as List)
            .where((json) =>
                json != null &&
                json['latitude'] != null &&
                json['longitude'] != null)
            .map((json) => DvfData.fromJson(json))
            .toList();

        // Update cache
        _dvfCache[cacheKey] = dvfDataList;
        _dvfCacheTimestamp[cacheKey] = DateTime.now();

        return dvfDataList;
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load DVF data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Exception: $e');
      throw Exception('Error fetching DVF data: $e');
    }
  }

  Future<List<ParcelData>> getParcelles(String communeCode) async {
    // Check cache first
    if (_parcelCache.containsKey(communeCode)) {
      final timestamp = _parcelCacheTimestamp[communeCode];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        debugPrint('Returning cached parcels for commune $communeCode');
        return _parcelCache[communeCode]!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$cadastreUrl/bundler/cadastre-etalab/communes/$communeCode/geojson/parcelles'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ParcelData> parcels = [];

        if (data['features'] != null) {
          for (var feature in data['features']) {
            if (feature['properties'] != null) {
              final properties =
                  Map<String, dynamic>.from(feature['properties']);
              properties['geometry'] = feature['geometry'];
              parcels.add(ParcelData.fromJson(properties));
            }
          }
        }

        // Update cache
        _parcelCache[communeCode] = parcels;
        _parcelCacheTimestamp[communeCode] = DateTime.now();

        return parcels;
      } else {
        debugPrint('Failed to load parcelles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching parcelles: $e');
      return [];
    }
  }

  void clearCache() {
    _parcelCache.clear();
    _parcelCacheTimestamp.clear();
    _dvfCache.clear();
    _dvfCacheTimestamp.clear();
  }
}
