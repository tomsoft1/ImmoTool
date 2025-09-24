import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:immo_tools/models/immo_data_dvf.dart';

class ImmoDataService {
  static const String _baseUrl = 'https://www.immo-data.fr/api';

  Future<List<ImmoDataDvf>> getDvfData({
    required double north,
    required double east,
    required double south,
    required double west,
    List<int>? propertyTypes,
    List<int>? roomCounts,
    DateTime? minDate,
    DateTime? maxDate,
    double? minSellPrice,
    double? maxSellPrice,
    double? minSurface,
    double? maxSurface,
    double? minSquareMeterPrice,
    double? maxSquareMeterPrice,
    double? minSurfaceLand,
    double? maxSurfaceLand,
  }) async {
    final queryParams = {
      'bounds': '$west,$north,$east,$north,$east,$south,$west,$south',
      if (propertyTypes != null) 'propertyType': propertyTypes.join(','),
      if (roomCounts != null) 'roomCount': roomCounts.join(','),
      if (minDate != null) 'minDate': minDate.toIso8601String().split('T')[0],
      if (maxDate != null) 'maxDate': maxDate.toIso8601String().split('T')[0],
      if (minSellPrice != null) 'minSellPrice': minSellPrice.toString(),
      if (maxSellPrice != null) 'maxSellPrice': maxSellPrice.toString(),
      if (minSurface != null) 'minSurface': minSurface.toString(),
      if (maxSurface != null) 'maxSurface': maxSurface.toString(),
      if (minSquareMeterPrice != null)
        'minSquareMeterPrice': minSquareMeterPrice.toString(),
      if (maxSquareMeterPrice != null)
        'maxSquareMeterPrice': maxSquareMeterPrice.toString(),
      if (minSurfaceLand != null) 'minSurfaceLand': minSurfaceLand.toString(),
      if (maxSurfaceLand != null) 'maxSurfaceLand': maxSurfaceLand.toString(),
      'sortBy': 'txDate',
      'sortOrder': '-1',
    };

    final uri = Uri.parse('$_baseUrl/transactions/search').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => ImmoDataDvf.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load DVF data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load DVF data: $e');
    }
  }
}
