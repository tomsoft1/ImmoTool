import 'dart:io';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test de performance pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_performance_test.dart
void main() async {
  print('🚀 Test de performance de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test de performance avec plusieurs appels
  print('=== Test de performance avec appels multiples ===');
  await testMultipleCalls(dvfApiService);

  print('\n=== Test de performance avec cache ===');
  await testCachePerformance(dvfApiService);

  print('\n=== Test de performance avec bounds ===');
  await testBoundsPerformance(dvfService);

  print('\n=== Test de performance avec filtres ===');
  await testFiltersPerformance(dvfService);

  print('\n=== Test de charge avec appels parallèles ===');
  await testParallelCalls(dvfApiService);

  print('\n🎉 Tests de performance terminés!');
}

/// Test avec plusieurs appels séquentiels
Future<void> testMultipleCalls(DvfApiService dvfApiService) async {
  final stopwatch = Stopwatch()..start();

  try {
    final results = <List<ImmoDataDvf>>[];

    // Test avec différents codes de commune
    final communeCodes = ['75101', '75102', '75103', '75104', '75105'];

    for (final communeCode in communeCodes) {
      final start = DateTime.now();
      final dvfData = await dvfApiService.getDvfData(
        communeCode: communeCode,
        parcelCode: '0001',
        startDate: '2020-01-01',
        endDate: '2024-01-01',
      );
      final duration = DateTime.now().difference(start);

      results.add(dvfData);
      print(
          '📊 Commune $communeCode: ${dvfData.length} transactions en ${duration.inMilliseconds}ms');
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${communeCodes.length} appels effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / communeCodes.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test multiple: $e');
  }
}

/// Test de performance du cache
Future<void> testCachePerformance(DvfApiService dvfApiService) async {
  try {
    const communeCode = '75101';
    const parcelCode = '0001';

    // Premier appel (sans cache)
    final start1 = DateTime.now();
    await dvfApiService.getDvfData(
      communeCode: communeCode,
      parcelCode: parcelCode,
    );
    final duration1 = DateTime.now().difference(start1);
    print('⏱️ Premier appel (sans cache): ${duration1.inMilliseconds}ms');

    // Deuxième appel (avec cache)
    final start2 = DateTime.now();
    await dvfApiService.getDvfData(
      communeCode: communeCode,
      parcelCode: parcelCode,
    );
    final duration2 = DateTime.now().difference(start2);
    print('⏱️ Deuxième appel (avec cache): ${duration2.inMilliseconds}ms');

    final improvement = ((duration1.inMilliseconds - duration2.inMilliseconds) /
        duration1.inMilliseconds *
        100);
    print('📈 Amélioration avec cache: ${improvement.toStringAsFixed(1)}%');

    if (duration2.inMilliseconds < duration1.inMilliseconds) {
      print('✅ Cache fonctionne correctement');
    } else {
      print('⚠️ Cache ne semble pas fonctionner');
    }
  } catch (e) {
    print('❌ Erreur lors du test de cache: $e');
  }
}

/// Test de performance avec bounds
Future<void> testBoundsPerformance(DvfService dvfService) async {
  try {
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522), // Sud-Ouest de Paris
      const LatLng(48.8606, 2.3562), // Nord-Est de Paris
    );

    final start = DateTime.now();
    final dvfData = await dvfService.getData(
      bounds: bounds,
      minDate: DateTime(2020, 1, 1),
      maxDate: DateTime(2024, 1, 1),
    );
    final duration = DateTime.now().difference(start);

    print(
        '✅ Données récupérées avec bounds: ${dvfData.length} transactions en ${duration.inMilliseconds}ms');
    print(
        '📊 Temps par transaction: ${duration.inMilliseconds / dvfData.length}ms');
  } catch (e) {
    print('❌ Erreur lors du test avec bounds: $e');
  }
}

/// Test de performance avec filtres
Future<void> testFiltersPerformance(DvfService dvfService) async {
  try {
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522),
      const LatLng(48.8606, 2.3562),
    );

    // Test avec différents filtres
    final filters = [
      {'minPrice': 100000, 'maxPrice': 500000, 'name': 'Prix bas'},
      {'minPrice': 500000, 'maxPrice': 1000000, 'name': 'Prix moyen'},
      {'minPrice': 1000000, 'maxPrice': 2000000, 'name': 'Prix élevé'},
      {'minSurface': 50, 'maxSurface': 100, 'name': 'Surface petite'},
      {'minSurface': 100, 'maxSurface': 200, 'name': 'Surface grande'},
    ];

    for (final filter in filters) {
      final start = DateTime.now();
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minPrice: filter['minPrice'] as double?,
        maxPrice: filter['maxPrice'] as double?,
        minSurface: filter['minSurface'] as double?,
        maxSurface: filter['maxSurface'] as double?,
      );
      final duration = DateTime.now().difference(start);

      print(
          '📊 ${filter['name']}: ${dvfData.length} transactions en ${duration.inMilliseconds}ms');
    }
  } catch (e) {
    print('❌ Erreur lors du test avec filtres: $e');
  }
}

/// Test avec appels parallèles
Future<void> testParallelCalls(DvfApiService dvfApiService) async {
  try {
    final stopwatch = Stopwatch()..start();

    // Créer plusieurs appels en parallèle
    final futures = List.generate(10, (index) {
      final communeCode = '7510${(index % 5) + 1}'; // 75101 à 75105
      final parcelCode = '000${(index % 3) + 1}'; // 0001 à 0003

      return dvfApiService.getDvfData(
        communeCode: communeCode,
        parcelCode: parcelCode,
        startDate: '2020-01-01',
        endDate: '2024-01-01',
      );
    });

    final results = await Future.wait(futures);
    stopwatch.stop();

    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${futures.length} appels parallèles effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / futures.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');

    // Test de charge avec plus d'appels
    print('\n=== Test de charge avec 50 appels ===');
    final loadStopwatch = Stopwatch()..start();

    final loadFutures = List.generate(50, (index) {
      final communeCode = '7510${(index % 5) + 1}';
      final parcelCode = '000${(index % 3) + 1}';

      return dvfApiService.getDvfData(
        communeCode: communeCode,
        parcelCode: parcelCode,
      );
    });

    final loadResults = await Future.wait(loadFutures);
    loadStopwatch.stop();

    final loadTotalTransactions =
        loadResults.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${loadFutures.length} appels de charge effectués en ${loadStopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $loadTotalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${loadStopwatch.elapsedMilliseconds / loadFutures.length}ms');
    print(
        '📈 Transactions par seconde: ${(loadTotalTransactions / loadStopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de charge: $e');
  }
}
