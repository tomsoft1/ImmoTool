import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test de charge pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_load_test.dart
void main() async {
  print('🚀 Test de charge de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test de charge complet
  print('=== Test de charge complet ===');
  await testLoad(dvfApiService, dvfService);

  print('\n=== Test de charge avec appels parallèles ===');
  await testParallelLoad(dvfApiService, dvfService);

  print('\n=== Test de charge avec cache ===');
  await testCacheLoad(dvfApiService, dvfService);

  print('\n=== Test de charge avec bounds ===');
  await testBoundsLoad(dvfApiService, dvfService);

  print('\n=== Test de charge avec filtres ===');
  await testFiltersLoad(dvfApiService, dvfService);

  print('\n🎉 Tests de charge terminés!');
}

/// Test de charge principal
Future<void> testLoad(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de charge avec appels séquentiels');

    final stopwatch = Stopwatch()..start();
    final results = <List<ImmoDataDvf>>[];
    final errors = <String>[];

    // Test avec 100 appels
    for (int i = 0; i < 100; i++) {
      try {
        final communeCode = '7510${(i % 5) + 1}'; // 75101 à 75105
        final parcelCode = '000${(i % 3) + 1}'; // 0001 à 0003

        final dvfData = await dvfApiService.getDvfData(
          communeCode: communeCode,
          parcelCode: parcelCode,
          startDate: '2020-01-01',
          endDate: '2024-01-01',
        );

        results.add(dvfData);

        if (i % 10 == 0) {
          print('📊 Appel ${i + 1}/100: ${dvfData.length} transactions');
        }
      } catch (e) {
        errors.add('Appel ${i + 1}: $e');
      }
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print('✅ ${results.length} appels réussis sur 100');
    print('❌ ${errors.length} erreurs');
    print(
        '📊 Total: $totalTransactions transactions en ${stopwatch.elapsedMilliseconds}ms');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / results.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');

    if (errors.isNotEmpty) {
      print('\n❌ Erreurs rencontrées:');
      for (final error in errors.take(5)) {
        print('   - $error');
      }
      if (errors.length > 5) {
        print('   - ... et ${errors.length - 5} autres erreurs');
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de charge: $e');
  }
}

/// Test de charge avec appels parallèles
Future<void> testParallelLoad(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de charge avec appels parallèles');

    // Test avec 50 appels parallèles
    final stopwatch = Stopwatch()..start();

    final futures = List.generate(50, (index) {
      final communeCode = '7510${(index % 5) + 1}';
      final parcelCode = '000${(index % 3) + 1}';

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

    // Test avec 200 appels parallèles
    print('\n📊 Test avec 200 appels parallèles');
    final loadStopwatch = Stopwatch()..start();

    final loadFutures = List.generate(200, (index) {
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
        '✅ ${loadFutures.length} appels parallèles effectués en ${loadStopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $loadTotalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${loadStopwatch.elapsedMilliseconds / loadFutures.length}ms');
    print(
        '📈 Transactions par seconde: ${(loadTotalTransactions / loadStopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de charge parallèle: $e');
  }
}

/// Test de charge avec cache
Future<void> testCacheLoad(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de charge avec cache');

    const communeCode = '75101';
    const parcelCode = '0001';

    // Remplir le cache
    await dvfApiService.getDvfData(
      communeCode: communeCode,
      parcelCode: parcelCode,
    );

    final stopwatch = Stopwatch()..start();
    final results = <List<ImmoDataDvf>>[];

    // Test avec 1000 appels en cache
    for (int i = 0; i < 1000; i++) {
      final dvfData = await dvfApiService.getDvfData(
        communeCode: communeCode,
        parcelCode: parcelCode,
      );
      results.add(dvfData);

      if (i % 100 == 0) {
        print('📊 Appel ${i + 1}/1000: ${dvfData.length} transactions');
      }
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${results.length} appels en cache effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / results.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de charge avec cache: $e');
  }
}

/// Test de charge avec bounds
Future<void> testBoundsLoad(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de charge avec bounds');

    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522), // Sud-Ouest de Paris
      const LatLng(48.8606, 2.3562), // Nord-Est de Paris
    );

    final stopwatch = Stopwatch()..start();
    final results = <List<ImmoDataDvf>>[];

    // Test avec 50 appels avec bounds
    for (int i = 0; i < 50; i++) {
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
      );

      results.add(dvfData);

      if (i % 10 == 0) {
        print('📊 Appel ${i + 1}/50: ${dvfData.length} transactions');
      }
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${results.length} appels avec bounds effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / results.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de charge avec bounds: $e');
  }
}

/// Test de charge avec filtres
Future<void> testFiltersLoad(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de charge avec filtres');

    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522),
      const LatLng(48.8606, 2.3562),
    );

    final stopwatch = Stopwatch()..start();
    final results = <List<ImmoDataDvf>>[];

    // Test avec différents filtres
    final filters = [
      {'minPrice': 100000, 'maxPrice': 500000, 'name': 'Prix bas'},
      {'minPrice': 500000, 'maxPrice': 1000000, 'name': 'Prix moyen'},
      {'minPrice': 1000000, 'maxPrice': 2000000, 'name': 'Prix élevé'},
      {'minSurface': 50, 'maxSurface': 100, 'name': 'Surface petite'},
      {'minSurface': 100, 'maxSurface': 200, 'name': 'Surface grande'},
    ];

    for (int i = 0; i < 100; i++) {
      final filter = filters[i % filters.length];

      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minPrice: filter['minPrice'] as double?,
        maxPrice: filter['maxPrice'] as double?,
        minSurface: filter['minSurface'] as double?,
        maxSurface: filter['maxSurface'] as double?,
      );

      results.add(dvfData);

      if (i % 20 == 0) {
        print(
            '📊 Appel ${i + 1}/100: ${dvfData.length} transactions (${filter['name']})');
      }
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${results.length} appels avec filtres effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / results.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de charge avec filtres: $e');
  }
}
