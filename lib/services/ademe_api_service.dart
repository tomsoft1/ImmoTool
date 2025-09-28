import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/dpe_data.dart';
import '../providers/settings_provider.dart';

class AdemeApiService {
  // API DPE Logements neufs (depuis juillet 2021) - Documentation officielle
  static const String dpeNewUrl =
      'https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines';

  // URL de base pour les données DPE via data.gouv.fr
  static const String dataGouvBaseUrl =
      'https://www.data.gouv.fr/api/1/datasets';

  // Limite de l'API : 10 appels par seconde par IP
  static const int maxCallsPerSecond = 10;
  static final List<DateTime> _callHistory = [];

  /// Respecte la limite de 10 appels par seconde de l'API ADEME
  static Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    _callHistory.removeWhere(
        (callTime) => now.difference(callTime).inMilliseconds > 1000);

    if (_callHistory.length >= maxCallsPerSecond) {
      final oldestCall = _callHistory.first;
      final waitTime = 1000 - now.difference(oldestCall).inMilliseconds;
      if (waitTime > 0) {
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }

    _callHistory.add(DateTime.now());
  }

  /// Récupère les données DPE pour les logements existants
  /// Basé sur la documentation officielle de l'API DPE logements
  Future<List<DpeData>> getDpeData({
    required double lat,
    required double lng,
    double radius = 1000,
    required String bbox,
    required SettingsProvider settings,
  }) async {
    final queryParams = {
      'size': '100', // Limite recommandée par l'API
      'select':
          'adresse_ban,date_etablissement_dpe,_geopoint,_id,surface_habitable_logement,etiquette_dpe,etiquette_ges',
      'qs': settings.getFullQuery(),
      'bbox': bbox,
    };

    final uri = Uri.parse(dpeNewUrl).replace(queryParameters: queryParams);

    try {
      // Respecter la limite de 10 appels par seconde
      await _respectRateLimit();

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ImmoTool/1.0',
        },
      );

      print('Fetching DPE data from: ${uri.toString()}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Found ${data['results']?.length ?? 0} DPE entries');

        if (data['results'] == null) {
          return [];
        }

        return (data['results'] as List)
            .where((json) =>
                json != null &&
                json['_geopoint'] != null &&
                json['_geopoint'].toString().isNotEmpty)
            .map((json) => DpeData.fromJson(json))
            .toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load DPE data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Exception: $e');
      throw Exception('Error fetching DPE data: $e');
    }
  }

  /// Méthode de compatibilité pour l'ancienne version de l'API
  /// @deprecated Utilisez getDpeData() à la place
  Future<List<DpeData>> getDpeDataV1({
    required double lat,
    required double lng,
    double radius = 1000,
    required String bbox,
    required SettingsProvider settings,
  }) async {
    // Redirige vers la nouvelle méthode
    return getDpeData(
      lat: lat,
      lng: lng,
      radius: radius,
      bbox: bbox,
      settings: settings,
    );
  }
}
