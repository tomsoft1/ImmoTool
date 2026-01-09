import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Backend API configuration
  static const String backendBaseUrl = 'http://localhost:3000/api';

  // Legacy ADEME API (kept for reference)
  static String getBaseUrl() {
    if (kIsWeb) {
      // Use a CORS proxy for web
//      return 'https://cors-anywhere.herokuapp.com/https://data.ademe.fr/data-fair/api/v1/datasets/dpe-v2-logements-existants';
    }
    return 'https://data.ademe.fr/data-fair/api/v1/datasets/dpe-france/';
  }

  // Backend endpoints
  static String get dvfTransactionsEndpoint => '$backendBaseUrl/dvf/transactions';
  static String get dpeRecordsEndpoint => '$backendBaseUrl/dpe/records';
  static String get geocodingEndpoint => '$backendBaseUrl/geocoding/search';
  static String get healthEndpoint => '$backendBaseUrl/health';
}