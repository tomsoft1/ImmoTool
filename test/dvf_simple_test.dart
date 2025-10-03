import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test simple pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_simple_test.dart
void main() async {
  print('🚀 Test simple de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();
/* 
  // Test 1: Récupération des données DVF
  print('=== Test 1: Récupération données DVF ===');
  try {
    final dvfData = await dvfApiService.getDvfData(
      communeCode: '75101', // Paris 1er arrondissement
      parcelCode: '0001',
      startDate: '2020-01-01',
      endDate: '2024-01-01',
    );

    print('✅ Données DVF récupérées: ${dvfData.length} transactions');

    if (dvfData.isNotEmpty) {
      final transaction = dvfData.first;
      print('📊 Première transaction:');
      print('   - Date: ${transaction.txDate}');
      print('   - Prix: ${transaction.price}€');
      print(
          '   - Prix/m²: ${transaction.squareMeterPrice.toStringAsFixed(2)}€');
      print('   - Surface: ${transaction.attributes.livingArea}m²');
      print('   - Pièces: ${transaction.attributes.rooms}');
      print('   - Adresse: ${transaction.location.cityName}');
      print(
          '   - Coordonnées: ${transaction.location.latitude}, ${transaction.location.longitude}');
    }
  } catch (e) {
    print('❌ Erreur lors de la récupération des données DVF: $e');
  }

  print('\n=== Test 2: Récupération des parcelles ===');
  try {
    final parcels = await dvfApiService.getParcelles('75101');
    print('✅ Parcelles récupérées: ${parcels.length}');

    if (parcels.isNotEmpty) {
      final parcel = parcels.first;
      print('📊 Première parcelle:');
      print('   - ID: ${parcel.id}');
      print('   - Section: ${parcel.section}');
      print('   - Numéro: ${parcel.number}');
      print('   - Surface: ${parcel.area}m²');
    }
  } catch (e) {
    print('❌ Erreur lors de la récupération des parcelles: $e');
  }
 */
  print('\n=== Test 3: Test du service DVF avec bounds ===');
  try {
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522), // Sud-Ouest de Paris
      const LatLng(48.8606, 2.3562), // Nord-Est de Paris
    );

    final dvfData = await dvfService.getData(
      bounds: bounds,
      minDate: DateTime(2020, 1, 1),
      maxDate: DateTime(2024, 1, 1),
      minPrice: 100000,
      maxPrice: 1000000,
    );

    print('✅ Données récupérées avec bounds: ${dvfData.length} transactions');

    if (dvfData.isNotEmpty) {
      final transaction = dvfData.first;
      print('📊 Première transaction:');
      print('   - Date: ${transaction.txDate}');
      print('   - Prix: ${transaction.price}€');
      print('   - Adresse: ${transaction.fullAddress}');
      print(
          '   - Prix/m²: ${transaction.squareMeterPrice.toStringAsFixed(2)}€');
    }
  } catch (e) {
    print('❌ Erreur lors du test avec bounds: $e');
  }

  print('\n=== Test 4: Test de disponibilité du service ===');
  try {
    final isAvailable = await dvfService.isAvailable();
    print('✅ Service disponible: $isAvailable');
  } catch (e) {
    print('❌ Erreur lors du test de disponibilité: $e');
  }

  print('\n=== Test 5: Test du cache ===');
  try {
    // Premier appel
    final start1 = DateTime.now();
    await dvfApiService.getDvfData(
      communeCode: '75101',
      parcelCode: '0001',
    );
    final duration1 = DateTime.now().difference(start1);
    print('⏱️ Premier appel: ${duration1.inMilliseconds}ms');

    // Deuxième appel (devrait utiliser le cache)
    final start2 = DateTime.now();
    await dvfApiService.getDvfData(
      communeCode: '75101',
      parcelCode: '0001',
    );
    final duration2 = DateTime.now().difference(start2);
    print('⏱️ Deuxième appel (cache): ${duration2.inMilliseconds}ms');

    if (duration2.inMilliseconds < duration1.inMilliseconds) {
      print('✅ Cache fonctionne correctement');
    } else {
      print('⚠️ Cache ne semble pas fonctionner');
    }
  } catch (e) {
    print('❌ Erreur lors du test de cache: $e');
  }

  print('\n=== Test 6: Test de sérialisation des modèles ===');
  try {
    final testJson = {
      'date_mutation': '2023-01-15',
      'valeur_fonciere': '250000',
      'lot1_surface_carrez': '50.0',
      'nombre_pieces_principales': '3',
      'surface_terrain': '100.0',
      'id_mutation': '12345',
      'code_type_local': '1',
      'id_parcelle': '751010001',
      'adresse_numero': '10',
      'adresse_suffixe': 'bis',
      'adresse_nom_voie': 'Rue de Rivoli',
      'adresse_code_voie': '12345',
      'code_postal': '75001',
      'nom_commune': 'Paris',
      'code_departement': '75',
      'code_commune': '75101',
      'longitude': '2.3522',
      'latitude': '48.8566',
    };

    final immoData = ImmoDataDvf.fromJson(testJson);
    print('✅ ImmoDataDvf créé avec succès');
    print('📊 Données:');
    print('   - Date: ${immoData.txDate}');
    print('   - Prix: ${immoData.price}€');
    print('   - Prix/m²: ${immoData.squareMeterPrice.toStringAsFixed(2)}€');
    print('   - Surface: ${immoData.attributes.livingArea}m²');
    print('   - Pièces: ${immoData.attributes.rooms}');
    print('   - Adresse: ${immoData.fullAddress}');
    print(
        '   - Coordonnées: ${immoData.location.latitude}, ${immoData.location.longitude}');
  } catch (e) {
    print('❌ Erreur lors de la sérialisation: $e');
  }

  print('\n🎉 Tests terminés!');
}
