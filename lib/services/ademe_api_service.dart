import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dpe_data.dart';

class AdemeApiService {
  static const String baseUrl = 'https://data.ademe.fr/data-fair/api/v1/datasets/dpe-france/lines';
  
  Future<List<DpeData>> getDpeData({
    required double lat,
    required double lng,
    double radius = 1000,
    required String xyz,
  }) async {
    final queryParams = {
      'size': '1000',
      'select': '*',
//      'where': 'distance(POINT(longitude,latitude),POINT($lng,$lat)) < $radius',
      'xyz': xyz,
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
} 