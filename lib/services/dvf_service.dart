import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'real_estate_data_service.dart';
import '../models/immo_data_dvf.dart';

// ignore_for_file: avoid_print
class DvfService implements RealEstateDataService<ImmoDataDvf> {
  static const String _baseUrl = 'https://www.immo-data.fr/api';

  @override
  Future<List<ImmoDataDvf>> getData({
    required LatLngBounds bounds,
    DateTime? minDate,
    DateTime? maxDate,
    double? minSurface,
    double? maxSurface,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = {
      'bounds': '${bounds.southWest.longitude},${bounds.northEast.latitude},'
          '${bounds.northEast.longitude},${bounds.northEast.latitude},'
          '${bounds.northEast.longitude},${bounds.southWest.latitude},'
          '${bounds.southWest.longitude},${bounds.southWest.latitude}',
      if (minDate != null) 'minDate': minDate.toIso8601String().split('T')[0],
      if (maxDate != null) 'maxDate': maxDate.toIso8601String().split('T')[0],
      if (minPrice != null) 'minSellPrice': minPrice.toString(),
      if (maxPrice != null) 'maxSellPrice': maxPrice.toString(),
      if (minSurface != null) 'minSurface': minSurface.toString(),
      if (maxSurface != null) 'maxSurface': maxSurface.toString(),
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

  @override
  List<Marker> convertToMarkers(BuildContext context, List<ImmoDataDvf> data) {
    return data.map((dvf) {
      final coordinates = LatLng(dvf.location.latitude, dvf.location.longitude);
      return Marker(
        point: coordinates,
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            // Afficher les détails de la transaction
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Transaction DVF'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${dvf.txDate}'),
                    Text('Prix: ${dvf.price}€'),
                    if (dvf.attributes.livingArea != null)
                      Text('Surface: ${dvf.attributes.livingArea}m²'),
                    if (dvf.attributes.rooms != null)
                      Text('Pièces: ${dvf.attributes.rooms}'),
                    Text('Prix/m²: ${dvf.squareMeterPrice}€'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${dvf.price ~/ 1000}k€',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/transactions/search'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPropertyDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/$id'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting property details: $e');
      return null;
    }
  }
}
