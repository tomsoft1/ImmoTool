import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dvf_data.dart';

class DvfApiService {
  static const String baseUrl = 'https://app.dvf.etalab.gouv.fr/api';

  Future<List<DvfData>> getDvfData({
    required double lat,
    required double lng,
    double radius = 1000,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'radius': radius.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse('$baseUrl/mutations3/75104/000AF').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      print('Fetching DVF data from: ${uri.toString()}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Found ${data['mutations']?.length ?? 0} DVF entries');
        
        if (data['mutations'] == null) {
          return [];
        }

        return (data['mutations'] as List)
            .where((json) => 
                json != null && 
                json['latitude'] != null && 
                json['longitude'] != null)
            .map((json) => DvfData.fromJson(json))
            .toList();
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load DVF data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Exception: $e');
      throw Exception('Error fetching DVF data: $e');
    }
  }
} 