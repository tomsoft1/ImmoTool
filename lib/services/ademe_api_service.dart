import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dpe_data.dart';

class AdemeApiService {
  static const String baseUrl =
      'https://data.ademe.fr/data-fair/api/v1/datasets/dpe-france/lines';
  static const String v1BaseUrl =
      'https://data.ademe.fr/data-fair/api/v1/datasets/dpe-v2-logements-existants/lines';

  Future<List<DpeData>> getDpeData({
    required double lat,
    required double lng,
    double radius = 1000,
    required String bbox,
  }) async {
    final queryParams = {
      'size': '100',
      'select': '*',
      'qs': 'date_etablissement_dpe:[2024-01-01 TO 2024-11-17]',
//          'date_etablissement_dpe:[2024-01-01 TO 2024-11-17] AND classe_consommation_energie:("G" OR "F")',
//      'where': 'distance(POINT(longitude,latitude),POINT($lng,$lat)) < $radius',
      'bbox': bbox,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
                json['latitude'] != null &&
                json['longitude'] != null)
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

  Future<List<DpeData>> getDpeDataV1({
    required double lat,
    required double lng,
    double radius = 1000,
    required String bbox,
  }) async {
    final queryParams = {
      'size': '100',
//      'select': '*',
      'select':
          'Adresse_brute,Etiquette_DPE,Date_établissement_DPE,_geopoint,_id,Surface_habitable_logement',
      'qs':
          'Etiquette_DPE:("F" OR "G") AND  Date_établissement_DPE:[2024\\-01\\-01 TO 2025\\-01\\-01]',
      //     'qs': 'date_etablissement_dpe:[2024-01-01 TO 2024-11-17]',
//          'date_etablissement_dpe:[2024-01-01 TO 2024-11-17] AND classe_consommation_energie:("G" OR "F")',
//      'where': 'distance(POINT(longitude,latitude),POINT($lng,$lat)) < $radius',
      'bbox': bbox,
    };

    final uri = Uri.parse(v1BaseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
            .where((json) => json != null)
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
}
