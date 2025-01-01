import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String getBaseUrl() {
    if (kIsWeb) {
      // Use a CORS proxy for web
//      return 'https://cors-anywhere.herokuapp.com/https://data.ademe.fr/data-fair/api/v1/datasets/dpe-v2-logements-existants';
    }
    return 'https://data.ademe.fr/data-fair/api/v1/datasets/dpe-france/';
  }
} 