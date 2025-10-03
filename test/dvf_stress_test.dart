import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test de stress pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_stress_test.dart
void main() async {
  print('🚀 Test de stress de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test de stress avec appels intensifs
  print('=== Test de stress avec appels intensifs ===');
  await testIntensiveCalls(dvfApiService);

  print('\n=== Test de stress avec cache ===');
  await testCacheStress(dvfApiService);

  print('\n=== Test de stress avec bounds ===');
  await testBoundsStress(dvfService);

  print('\n=== Test de stress avec filtres complexes ===');
  await testComplexFilters(dvfService);

  print('\n=== Test de stress avec appels simultanés ===');
  await testConcurrentCalls(dvfApiService);

  print('\n=== Test de stress avec nettoyage de cache ===');
  await testCacheCleanup(dvfApiService);

  print('\n🎉 Tests de stress terminés!');
}

/// Test avec appels intensifs
Future<void> testIntensiveCalls(DvfApiService dvfApiService) async {
  try {
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
    print('❌ Erreur lors du test intensif: $e');
  }
}

/// Test de stress du cache
Future<void> testCacheStress(DvfApiService dvfApiService) async {
  try {
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
    print('❌ Erreur lors du test de stress du cache: $e');
  }
}

/// Test de stress avec bounds
Future<void> testBoundsStress(DvfService dvfService) async {
  try {
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
    print('❌ Erreur lors du test de stress avec bounds: $e');
  }
}

/// Test de stress avec filtres complexes
Future<void> testComplexFilters(DvfService dvfService) async {
  try {
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522),
      const LatLng(48.8606, 2.3562),
    );

    final stopwatch = Stopwatch()..start();
    final results = <List<ImmoDataDvf>>[];

    // Test avec différents filtres complexes
    final filters = [
      {
        'minPrice': 100000,
        'maxPrice': 500000,
        'minSurface': 50,
        'maxSurface': 100
      },
      {
        'minPrice': 500000,
        'maxPrice': 1000000,
        'minSurface': 100,
        'maxSurface': 200
      },
      {
        'minPrice': 1000000,
        'maxPrice': 2000000,
        'minSurface': 200,
        'maxSurface': 500
      },
      {
        'minPrice': 2000000,
        'maxPrice': 5000000,
        'minSurface': 500,
        'maxSurface': 1000
      },
      {
        'minPrice': 5000000,
        'maxPrice': 10000000,
        'minSurface': 1000,
        'maxSurface': 2000
      },
    ];

    for (int i = 0; i < 20; i++) {
      final filter = filters[i % filters.length];

      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minPrice: filter['minPrice'] as double,
        maxPrice: filter['maxPrice'] as double,
        minSurface: filter['minSurface'] as double,
        maxSurface: filter['maxSurface'] as double,
      );

      results.add(dvfData);

      if (i % 5 == 0) {
        print('📊 Appel ${i + 1}/20: ${dvfData.length} transactions');
      }
    }

    stopwatch.stop();
    final totalTransactions = results.fold(0, (sum, list) => sum + list.length);

    print(
        '✅ ${results.length} appels avec filtres complexes effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / results.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test de stress avec filtres: $e');
  }
}

/// Test avec appels simultanés
Future<void> testConcurrentCalls(DvfApiService dvfApiService) async {
  try {
    final stopwatch = Stopwatch()..start();

    // Test avec 100 appels simultanés
    final futures = List.generate(100, (index) {
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
        '✅ ${futures.length} appels simultanés effectués en ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $totalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${stopwatch.elapsedMilliseconds / futures.length}ms');
    print(
        '📈 Transactions par seconde: ${(totalTransactions / stopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');

    // Test avec 500 appels simultanés
    print('\n=== Test avec 500 appels simultanés ===');
    final loadStopwatch = Stopwatch()..start();

    final loadFutures = List.generate(500, (index) {
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
        '✅ ${loadFutures.length} appels simultanés effectués en ${loadStopwatch.elapsedMilliseconds}ms');
    print('📊 Total: $loadTotalTransactions transactions');
    print(
        '⏱️ Temps moyen par appel: ${loadStopwatch.elapsedMilliseconds / loadFutures.length}ms');
    print(
        '📈 Transactions par seconde: ${(loadTotalTransactions / loadStopwatch.elapsedMilliseconds * 1000).toStringAsFixed(2)}');
  } catch (e) {
    print('❌ Erreur lors du test d\'appels simultanés: $e');
  }
}

/// Test de stress avec nettoyage de cache
Future<void> testCacheCleanup(DvfApiService dvfApiService) async {
  try {
    // Remplir le cache
    for (int i = 0; i < 10; i++) {
      final communeCode = '7510${(i % 5) + 1}';
      final parcelCode = '000${(i % 3) + 1}';

      await dvfApiService.getDvfData(
        communeCode: communeCode,
        parcelCode: parcelCode,
      );
    }

    print('✅ Cache rempli avec 10 entrées');

    // Test de nettoyage de cache
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < 100; i++) {
      dvfApiService.clearCache();

      if (i % 20 == 0) {
        print('📊 Nettoyage ${i + 1}/100');
      }
    }

    stopwatch.stop();

    print('✅ ${stopwatch.elapsedMilliseconds}ms pour 100 nettoyages de cache');
    print(
        '⏱️ Temps moyen par nettoyage: ${stopwatch.elapsedMilliseconds / 100}ms');
  } catch (e) {
    print('❌ Erreur lors du test de nettoyage de cache: $e');
  }
}
