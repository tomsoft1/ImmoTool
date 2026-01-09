import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dpe_data.dart';
import '../models/immo_data_dvf.dart';

/// Backend API service that centralizes all data fetching through the backend
/// instead of calling external APIs directly.
///
/// This service provides:
/// - Unified interface for DVF and DPE data
/// - Rate limiting (500ms between requests)
/// - Error handling and graceful fallbacks
/// - Backend-based caching (handled by backend MongoDB)
class BackendApiService {
  // Rate limiting
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 500);

  // Singleton pattern
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;
  BackendApiService._internal();

  /// Apply rate limiting before making requests
  Future<void> _applyRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final waitTime = _minRequestInterval - elapsed;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Check backend health status
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthEndpoint),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }

  /// Fetch DPE records by bounding box
  ///
  /// Parameters:
  /// - north, south, east, west: Map boundaries
  ///
  /// Returns a list of DpeData objects
  Future<List<DpeData>> getDpeRecords({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    try {
      await _applyRateLimit();

      final uri = Uri.parse(ApiConfig.dpeRecordsEndpoint).replace(queryParameters: {
        'north': north.toString(),
        'south': south.toString(),
        'east': east.toString(),
        'west': west.toString(),
      });

      debugPrint('🔄 Fetching DPE records from backend: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final records = (jsonData['data'] as List)
              .map((record) => _parseDpeRecord(record))
              .where((record) => record != null)
              .cast<DpeData>()
              .toList();

          debugPrint('✅ Fetched ${records.length} DPE records from backend');
          return records;
        } else {
          debugPrint('⚠️ Backend returned unsuccessful response');
          return [];
        }
      } else {
        debugPrint('❌ Backend request failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching DPE records from backend: $e');
      return [];
    }
  }

  /// Fetch DVF transactions by bounding box
  ///
  /// Parameters:
  /// - north, south, east, west: Map boundaries
  ///
  /// Returns a list of ImmoDataDvf objects
  Future<List<ImmoDataDvf>> getDvfTransactions({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    try {
      await _applyRateLimit();

      final uri = Uri.parse(ApiConfig.dvfTransactionsEndpoint).replace(queryParameters: {
        'north': north.toString(),
        'south': south.toString(),
        'east': east.toString(),
        'west': west.toString(),
      });

      debugPrint('🔄 Fetching DVF transactions from backend: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final transactions = (jsonData['data'] as List)
              .map((transaction) => _parseDvfTransaction(transaction))
              .where((transaction) => transaction != null)
              .cast<ImmoDataDvf>()
              .toList();

          debugPrint('✅ Fetched ${transactions.length} DVF transactions from backend');
          return transactions;
        } else {
          debugPrint('⚠️ Backend returned unsuccessful response');
          return [];
        }
      } else {
        debugPrint('❌ Backend request failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching DVF transactions from backend: $e');
      return [];
    }
  }

  /// Parse DPE record from backend response to DpeData model
  DpeData? _parseDpeRecord(Map<String, dynamic> record) {
    try {
      // Backend response format
      final id = record['id']?.toString() ?? '';
      final address = record['address']?.toString() ?? '';
      final lat = _parseDouble(record['lat']);
      final lon = _parseDouble(record['lon']);

      // Validate coordinates
      if (lat == null || lon == null) {
        debugPrint('⚠️ Skipping DPE record with invalid coordinates');
        return null;
      }

      // Skip default Paris coordinates (48.8566, 2.3522)
      if ((lat - 48.8566).abs() < 0.0001 && (lon - 2.3522).abs() < 0.0001) {
        return null;
      }

      return DpeData(
        id: id,
        address: address,
        geoAddress: address,
        dpeDate: record['dateEtablissementDpe']?.toString() ?? '',
        latitude: lat,
        longitude: lon,
        energyGrade: record['energyClass']?.toString() ?? '',
        energyValue: _parseInt(record['energyConsumption']) ?? 0,
        gesGrade: record['ghgClass']?.toString() ?? '',
        surface: _parseDouble(record['surfaceThermiqueLot']) ?? 0.0,
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing DPE record: $e');
      return null;
    }
  }

  /// Parse DVF transaction from backend response to ImmoDataDvf model
  ImmoDataDvf? _parseDvfTransaction(Map<String, dynamic> transaction) {
    try {
      // Backend response format
      final lat = _parseDouble(transaction['lat']);
      final lon = _parseDouble(transaction['lon']);

      // Validate coordinates
      if (lat == null || lon == null) {
        debugPrint('⚠️ Skipping DVF transaction with invalid coordinates');
        return null;
      }

      final price = _parseDouble(transaction['price']) ?? 0.0;
      final surface = _parseDouble(transaction['surface']) ?? 0.0;
      final id = transaction['id']?.toString() ?? '';

      return ImmoDataDvf(
        txDate: transaction['date']?.toString() ?? '',
        txType: 1, // Sale
        realtyType: _mapPropertyType(transaction['propertyType']?.toString()),
        price: price,
        attributes: DvfAttributes(
          livingArea: surface,
          rooms: _parseInt(transaction['rooms']),
          landArea: 0.0,
        ),
        txId: id,
        txGroupId: id, // Use same ID for group
        slug: id, // Use same ID for slug
        squareMeterPrice: surface > 0 ? price / surface : 0.0,
        location: DvfLocation(
          addressId: id,
          streetNumber: '',
          streetSuffix: '',
          streetType: '',
          streetName: transaction['address']?.toString() ?? '',
          streetCode: '',
          postCode: transaction['postalCode']?.toString() ?? '',
          cityName: transaction['commune']?.toString() ?? '',
          departmentCode: transaction['department']?.toString() ?? '',
          inseeCode: transaction['communeCode']?.toString() ?? '',
          districtCode: '',
          subdistrictCode: '',
          longitude: lon,
          latitude: lat,
          isDefault: false,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing DVF transaction: $e');
      return null;
    }
  }

  /// Map backend property type to DVF realtyType code
  int _mapPropertyType(String? type) {
    if (type == null) return 1;

    switch (type.toLowerCase()) {
      case 'appartement':
      case 'apartment':
        return 1;
      case 'maison':
      case 'house':
        return 2;
      case 'local':
      case 'commercial':
        return 3;
      case 'dépendance':
      case 'dependency':
        return 4;
      default:
        return 1;
    }
  }

  /// Parse double from dynamic value
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse int from dynamic value
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
