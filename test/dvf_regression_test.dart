import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test de régression pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_regression_test.dart
void main() async {
  print('🚀 Test de régression de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test de régression complet
  print('=== Test de régression complet ===');
  await testRegression(dvfApiService, dvfService);

  print('\n=== Test de compatibilité des données ===');
  await testDataCompatibility(dvfApiService, dvfService);

  print('\n=== Test de stabilité de l\'API ===');
  await testApiStability(dvfApiService, dvfService);

  print('\n=== Test de cohérence des résultats ===');
  await testResultConsistency(dvfApiService, dvfService);

  print('\n=== Test de performance de régression ===');
  await testPerformanceRegression(dvfApiService, dvfService);

  print('\n🎉 Tests de régression terminés!');
}

/// Test de régression principal
Future<void> testRegression(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de régression des fonctionnalités de base');

    // Test 1: Récupération des parcelles
    print('\n📊 Test 1: Récupération des parcelles');
    final parcels = await dvfApiService.getParcelles('75101');
    print('✅ ${parcels.length} parcelles récupérées');

    if (parcels.isNotEmpty) {
      final parcel = parcels.first;
      print(
          '📊 Première parcelle: ${parcel.id} (${parcel.section}${parcel.number})');

      // Test 2: Récupération des données DVF
      print('\n📊 Test 2: Récupération des données DVF');
      final dvfData = await dvfApiService.getDvfData(
        communeCode: '75101',
        parcelCode: parcel.number,
        startDate: '2020-01-01',
        endDate: '2024-01-01',
      );
      print('✅ ${dvfData.length} transactions DVF récupérées');

      if (dvfData.isNotEmpty) {
        final transaction = dvfData.first;
        print('📊 Première transaction:');
        print('   - Date: ${transaction.txDate}');
        print('   - Prix: ${transaction.price}€');
        print(
            '   - Prix/m²: ${transaction.squareMeterPrice.toStringAsFixed(2)}€');
        print('   - Surface: ${transaction.attributes.livingArea}m²');
        print('   - Adresse: ${transaction.location.cityName}');

        // Test 3: Test du service DVF
        print('\n📊 Test 3: Test du service DVF');
        final bounds = LatLngBounds(
          LatLng(transaction.location.latitude - 0.001,
              transaction.location.longitude - 0.001),
          LatLng(transaction.location.latitude + 0.001,
              transaction.location.longitude + 0.001),
        );

        final boundsData = await dvfService.getData(
          bounds: bounds,
          minDate: DateTime(2020, 1, 1),
          maxDate: DateTime(2024, 1, 1),
        );
        print('✅ ${boundsData.length} transactions récupérées avec bounds');

        // Test 4: Test de disponibilité
        print('\n📊 Test 4: Test de disponibilité');
        final isAvailable = await dvfService.isAvailable();
        print('✅ Service disponible: $isAvailable');

        // Test 5: Test de détails
        print('\n📊 Test 5: Test de détails');
        final details = await dvfService.getPropertyDetails(transaction.txId);
        if (details != null) {
          print('✅ Détails récupérés pour la propriété ${transaction.txId}');
        } else {
          print('ℹ️ Aucun détail disponible pour cette propriété');
        }
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de régression: $e');
  }
}

/// Test de compatibilité des données
Future<void> testDataCompatibility(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de compatibilité des données');

    // Test avec différents formats de données
    final testCases = [
      {'commune': '75101', 'parcel': '0001', 'name': 'Paris 1er'},
      {'commune': '75102', 'parcel': '0002', 'name': 'Paris 2e'},
      {'commune': '75103', 'parcel': '0003', 'name': 'Paris 3e'},
    ];

    for (final testCase in testCases) {
      print('\n📊 Test avec ${testCase['name']}');

      try {
        // Test des parcelles
        final parcels = await dvfApiService.getParcelles(testCase['commune']!);
        print('   - Parcelles: ${parcels.length}');

        if (parcels.isNotEmpty) {
          // Test des données DVF
          final dvfData = await dvfApiService.getDvfData(
            communeCode: testCase['commune']!,
            parcelCode: testCase['parcel']!,
            startDate: '2020-01-01',
            endDate: '2024-01-01',
          );
          print('   - Transactions DVF: ${dvfData.length}');

          if (dvfData.isNotEmpty) {
            final transaction = dvfData.first;

            // Validation de la structure des données
            bool isValid = true;
            final issues = <String>[];

            if (transaction.txDate.isEmpty) {
              isValid = false;
              issues.add('Date manquante');
            }

            if (transaction.price <= 0) {
              isValid = false;
              issues.add('Prix invalide');
            }

            if (transaction.location.latitude == 0 &&
                transaction.location.longitude == 0) {
              isValid = false;
              issues.add('Coordonnées invalides');
            }

            if (transaction.location.latitude == 0 &&
                transaction.location.longitude == 0) {
              isValid = false;
              issues.add('Coordonnées nulles');
            }

            if (isValid) {
              print('   ✅ Données valides');
            } else {
              print('   ❌ Données invalides: ${issues.join(', ')}');
            }
          }
        }
      } catch (e) {
        print('   ❌ Erreur: $e');
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de compatibilité: $e');
  }
}

/// Test de stabilité de l'API
Future<void> testApiStability(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de stabilité de l\'API');

    // Test avec plusieurs appels répétés
    const testCount = 10;
    final results = <List<ImmoDataDvf>>[];
    final errors = <String>[];

    for (int i = 0; i < testCount; i++) {
      try {
        final dvfData = await dvfApiService.getDvfData(
          communeCode: '75101',
          parcelCode: '0001',
          startDate: '2020-01-01',
          endDate: '2024-01-01',
        );
        results.add(dvfData);

        if (i % 2 == 0) {
          print('📊 Appel ${i + 1}/$testCount: ${dvfData.length} transactions');
        }
      } catch (e) {
        errors.add('Appel ${i + 1}: $e');
      }
    }

    print('✅ ${results.length} appels réussis sur $testCount');
    print('❌ ${errors.length} erreurs');

    if (results.isNotEmpty) {
      // Vérification de la cohérence des résultats
      final firstResult = results.first;
      bool isConsistent = true;

      for (int i = 1; i < results.length; i++) {
        if (results[i].length != firstResult.length) {
          isConsistent = false;
          break;
        }
      }

      if (isConsistent) {
        print('✅ Résultats cohérents entre les appels');
      } else {
        print('⚠️ Résultats incohérents entre les appels');
      }

      // Test de stabilité avec bounds
      print('\n📊 Test de stabilité avec bounds');
      final bounds = LatLngBounds(
        const LatLng(48.8566, 2.3522),
        const LatLng(48.8606, 2.3562),
      );

      final boundsResults = <List<ImmoDataDvf>>[];
      final boundsErrors = <String>[];

      for (int i = 0; i < 5; i++) {
        try {
          final boundsData = await dvfService.getData(
            bounds: bounds,
            minDate: DateTime(2020, 1, 1),
            maxDate: DateTime(2024, 1, 1),
          );
          boundsResults.add(boundsData);
        } catch (e) {
          boundsErrors.add('Appel ${i + 1}: $e');
        }
      }

      print('✅ ${boundsResults.length} appels avec bounds réussis sur 5');
      print('❌ ${boundsErrors.length} erreurs avec bounds');
    }
  } catch (e) {
    print('❌ Erreur lors du test de stabilité: $e');
  }
}

/// Test de cohérence des résultats
Future<void> testResultConsistency(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de cohérence des résultats');

    // Test avec les mêmes paramètres plusieurs fois
    final testParams = {
      'communeCode': '75101',
      'parcelCode': '0001',
      'startDate': '2020-01-01',
      'endDate': '2024-01-01',
    };

    final results = <List<ImmoDataDvf>>[];

    for (int i = 0; i < 5; i++) {
      final dvfData = await dvfApiService.getDvfData(
        communeCode: testParams['communeCode']!,
        parcelCode: testParams['parcelCode']!,
        startDate: testParams['startDate'],
        endDate: testParams['endDate'],
      );
      results.add(dvfData);
    }

    print('✅ ${results.length} appels effectués');

    if (results.isNotEmpty) {
      // Vérification de la cohérence
      final firstResult = results.first;
      bool isConsistent = true;

      for (int i = 1; i < results.length; i++) {
        if (results[i].length != firstResult.length) {
          isConsistent = false;
          print(
              '⚠️ Incohérence détectée: ${results[i].length} vs ${firstResult.length} transactions');
          break;
        }
      }

      if (isConsistent) {
        print('✅ Résultats cohérents entre les appels');
      } else {
        print('❌ Résultats incohérents entre les appels');
      }

      // Test de cohérence avec bounds
      print('\n📊 Test de cohérence avec bounds');
      final bounds = LatLngBounds(
        const LatLng(48.8566, 2.3522),
        const LatLng(48.8606, 2.3562),
      );

      final boundsResults = <List<ImmoDataDvf>>[];

      for (int i = 0; i < 3; i++) {
        final boundsData = await dvfService.getData(
          bounds: bounds,
          minDate: DateTime(2020, 1, 1),
          maxDate: DateTime(2024, 1, 1),
        );
        boundsResults.add(boundsData);
      }

      if (boundsResults.isNotEmpty) {
        final firstBoundsResult = boundsResults.first;
        bool boundsConsistent = true;

        for (int i = 1; i < boundsResults.length; i++) {
          if (boundsResults[i].length != firstBoundsResult.length) {
            boundsConsistent = false;
            print(
                '⚠️ Incohérence avec bounds: ${boundsResults[i].length} vs ${firstBoundsResult.length} transactions');
            break;
          }
        }

        if (boundsConsistent) {
          print('✅ Résultats avec bounds cohérents');
        } else {
          print('❌ Résultats avec bounds incohérents');
        }
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de cohérence: $e');
  }
}

/// Test de performance de régression
Future<void> testPerformanceRegression(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de performance de régression');

    // Test de performance avec appels répétés
    const testCount = 10;
    final durations = <int>[];

    for (int i = 0; i < testCount; i++) {
      final start = DateTime.now();

      await dvfApiService.getDvfData(
        communeCode: '75101',
        parcelCode: '0001',
        startDate: '2020-01-01',
        endDate: '2024-01-01',
      );

      final duration = DateTime.now().difference(start);
      durations.add(duration.inMilliseconds);

      if (i % 2 == 0) {
        print('📊 Appel ${i + 1}/$testCount: ${duration.inMilliseconds}ms');
      }
    }

    if (durations.isNotEmpty) {
      final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
      final minDuration = durations.reduce((a, b) => a < b ? a : b);
      final maxDuration = durations.reduce((a, b) => a > b ? a : b);

      print('📊 Statistiques de performance:');
      print('   - Temps moyen: ${avgDuration.toStringAsFixed(0)}ms');
      print('   - Temps min: ${minDuration}ms');
      print('   - Temps max: ${maxDuration}ms');

      // Test de performance avec bounds
      print('\n📊 Test de performance avec bounds');
      final boundsDurations = <int>[];

      for (int i = 0; i < 5; i++) {
        final start = DateTime.now();

        final bounds = LatLngBounds(
          const LatLng(48.8566, 2.3522),
          const LatLng(48.8606, 2.3562),
        );

        await dvfService.getData(
          bounds: bounds,
          minDate: DateTime(2020, 1, 1),
          maxDate: DateTime(2024, 1, 1),
        );

        final duration = DateTime.now().difference(start);
        boundsDurations.add(duration.inMilliseconds);
      }

      if (boundsDurations.isNotEmpty) {
        final avgBoundsDuration =
            boundsDurations.reduce((a, b) => a + b) / boundsDurations.length;
        final minBoundsDuration =
            boundsDurations.reduce((a, b) => a < b ? a : b);
        final maxBoundsDuration =
            boundsDurations.reduce((a, b) => a > b ? a : b);

        print('📊 Statistiques de performance avec bounds:');
        print('   - Temps moyen: ${avgBoundsDuration.toStringAsFixed(0)}ms');
        print('   - Temps min: ${minBoundsDuration}ms');
        print('   - Temps max: ${maxBoundsDuration}ms');
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de performance: $e');
  }
}
