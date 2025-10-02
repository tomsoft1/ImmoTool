import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test d'intégration complet pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_integration_test.dart
void main() async {
  print('🚀 Test d\'intégration complet de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test d'intégration complet
  print('=== Test d\'intégration complet ===');
  await testFullIntegration(dvfApiService, dvfService);

  print('\n=== Test de workflow complet ===');
  await testCompleteWorkflow(dvfApiService, dvfService);

  print('\n=== Test de données réelles ===');
  await testRealData(dvfApiService, dvfService);

  print('\n=== Test de validation des données ===');
  await testDataValidation(dvfApiService, dvfService);

  print('\n=== Test de gestion d\'erreurs ===');
  await testErrorHandling(dvfApiService, dvfService);

  print('\n🎉 Tests d\'intégration terminés!');
}

/// Test d'intégration complet
Future<void> testFullIntegration(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test 1: Récupération des parcelles');
    final parcels = await dvfApiService.getParcelles('75101');
    print('✅ ${parcels.length} parcelles récupérées');

    if (parcels.isNotEmpty) {
      final parcel = parcels.first;
      print(
          '📊 Première parcelle: ${parcel.id} (${parcel.section}${parcel.number})');

      print('\n🔍 Test 2: Récupération des données DVF pour cette parcelle');
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

        print('\n🔍 Test 3: Test du service DVF avec bounds');
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

        print('\n🔍 Test 4: Test de disponibilité du service');
        final isAvailable = await dvfService.isAvailable();
        print('✅ Service disponible: $isAvailable');

        print('\n🔍 Test 5: Test de détails de propriété');
        final details = await dvfService.getPropertyDetails(transaction.txId);
        if (details != null) {
          print('✅ Détails récupérés pour la propriété ${transaction.txId}');
        } else {
          print('ℹ️ Aucun détail disponible pour cette propriété');
        }
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test d\'intégration: $e');
  }
}

/// Test de workflow complet
Future<void> testCompleteWorkflow(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Étape 1: Récupération des parcelles pour plusieurs communes');
    final communes = ['75101', '75102', '75103'];
    final allParcels = <ParcelData>[];

    for (final commune in communes) {
      final parcels = await dvfApiService.getParcelles(commune);
      allParcels.addAll(parcels);
      print('📊 Commune $commune: ${parcels.length} parcelles');
    }

    print('✅ Total: ${allParcels.length} parcelles récupérées');

    if (allParcels.isNotEmpty) {
      print(
          '\n🔍 Étape 2: Récupération des données DVF pour les premières parcelles');
      final allDvfData = <ImmoDataDvf>[];

      for (int i = 0; i < 5 && i < allParcels.length; i++) {
        final parcel = allParcels[i];
        final dvfData = await dvfApiService.getDvfData(
          communeCode: parcel.communeCode,
          parcelCode: parcel.number,
          startDate: '2020-01-01',
          endDate: '2024-01-01',
        );
        allDvfData.addAll(dvfData);
        print('📊 Parcelle ${parcel.id}: ${dvfData.length} transactions');
      }

      print('✅ Total: ${allDvfData.length} transactions DVF récupérées');

      if (allDvfData.isNotEmpty) {
        print('\n🔍 Étape 3: Analyse des données récupérées');
        final prices = allDvfData.map((d) => d.price).toList();
        final surfaces = allDvfData
            .map((d) => d.attributes.livingArea)
            .where((s) => s != null)
            .toList();
        final squareMeterPrices = allDvfData
            .map((d) => d.squareMeterPrice)
            .where((p) => p > 0)
            .toList();

        if (prices.isNotEmpty) {
          final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          final minPrice = prices.reduce((a, b) => a < b ? a : b);
          final maxPrice = prices.reduce((a, b) => a > b ? a : b);

          print('📊 Statistiques des prix:');
          print('   - Prix moyen: ${avgPrice.toStringAsFixed(0)}€');
          print('   - Prix min: ${minPrice.toStringAsFixed(0)}€');
          print('   - Prix max: ${maxPrice.toStringAsFixed(0)}€');
        }

        if (surfaces.isNotEmpty) {
          final avgSurface =
              surfaces.reduce((a, b) => a! + b!)! / surfaces.length;
          final minSurface = surfaces.reduce((a, b) => a! < b! ? a : b);
          final maxSurface = surfaces.reduce((a, b) => a! > b! ? a : b);

          print('📊 Statistiques des surfaces:');
          print('   - Surface moyenne: ${avgSurface.toStringAsFixed(1)}m²');
          print('   - Surface min: ${minSurface!.toStringAsFixed(1)}m²');
          print('   - Surface max: ${maxSurface!.toStringAsFixed(1)}m²');
        }

        if (squareMeterPrices.isNotEmpty) {
          final avgSquareMeterPrice =
              squareMeterPrices.reduce((a, b) => a + b) /
                  squareMeterPrices.length;
          final minSquareMeterPrice =
              squareMeterPrices.reduce((a, b) => a < b ? a : b);
          final maxSquareMeterPrice =
              squareMeterPrices.reduce((a, b) => a > b ? a : b);

          print('📊 Statistiques des prix au m²:');
          print(
              '   - Prix/m² moyen: ${avgSquareMeterPrice.toStringAsFixed(0)}€');
          print('   - Prix/m² min: ${minSquareMeterPrice.toStringAsFixed(0)}€');
          print('   - Prix/m² max: ${maxSquareMeterPrice.toStringAsFixed(0)}€');
        }

        print('\n🔍 Étape 4: Test du service DVF avec bounds calculés');
        if (allDvfData.isNotEmpty) {
          final coordinates =
              allDvfData.map((d) => d.location.latitude).toList();
          final latitudes = coordinates.map((c) => c!).toList();
          final longitudes = coordinates.map((c) => c).toList();

          final bounds = LatLngBounds(
            LatLng(latitudes.reduce((a, b) => a < b ? a : b) - 0.001,
                longitudes.reduce((a, b) => a < b ? a : b) - 0.001),
            LatLng(latitudes.reduce((a, b) => a > b ? a : b) + 0.001,
                longitudes.reduce((a, b) => a > b ? a : b) + 0.001),
          );

          final boundsData = await dvfService.getData(
            bounds: bounds,
            minDate: DateTime(2020, 1, 1),
            maxDate: DateTime(2024, 1, 1),
          );

          print(
              '✅ ${boundsData.length} transactions récupérées avec bounds calculés');
        }
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test de workflow: $e');
  }
}

/// Test avec des données réelles
Future<void> testRealData(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test avec des données réelles de Paris');

    // Test avec des communes parisiennes réelles
    final parisCommunes = [
      {'code': '75101', 'name': 'Paris 1er'},
      {'code': '75102', 'name': 'Paris 2e'},
      {'code': '75103', 'name': 'Paris 3e'},
      {'code': '75104', 'name': 'Paris 4e'},
      {'code': '75105', 'name': 'Paris 5e'},
    ];

    for (final commune in parisCommunes) {
      print('\n📊 Test avec ${commune['name']} (${commune['code']})');

      try {
        final parcels = await dvfApiService.getParcelles(commune['code']!);
        print('   - Parcelles: ${parcels.length}');

        if (parcels.isNotEmpty) {
          final parcel = parcels.first;
          final dvfData = await dvfApiService.getDvfData(
            communeCode: commune['code']!,
            parcelCode: parcel.number,
            startDate: '2023-01-01',
            endDate: '2024-01-01',
          );
          print('   - Transactions DVF: ${dvfData.length}');

          if (dvfData.isNotEmpty) {
            final transaction = dvfData.first;
            print(
                '   - Dernière transaction: ${transaction.txDate} - ${transaction.price}€');
          }
        }
      } catch (e) {
        print('   ❌ Erreur pour ${commune['name']}: $e');
      }
    }
  } catch (e) {
    print('❌ Erreur lors du test avec données réelles: $e');
  }
}

/// Test de validation des données
Future<void> testDataValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des données');

    final dvfData = await dvfApiService.getDvfData(
      communeCode: '75101',
      parcelCode: '0001',
      startDate: '2020-01-01',
      endDate: '2024-01-01',
    );

    print('✅ ${dvfData.length} transactions récupérées pour validation');

    if (dvfData.isNotEmpty) {
      int validTransactions = 0;
      int invalidTransactions = 0;

      for (final transaction in dvfData) {
        bool isValid = true;
        final issues = <String>[];

        // Validation des champs obligatoires
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

        if (transaction.attributes.livingArea != null &&
            transaction.attributes.livingArea! <= 0) {
          isValid = false;
          issues.add('Surface invalide');
        }

        if (transaction.squareMeterPrice < 0) {
          isValid = false;
          issues.add('Prix au m² invalide');
        }

        if (isValid) {
          validTransactions++;
        } else {
          invalidTransactions++;
          if (invalidTransactions <= 5) {
            print('❌ Transaction invalide: ${issues.join(', ')}');
          }
        }
      }

      print('📊 Résultats de validation:');
      print('   - Transactions valides: $validTransactions');
      print('   - Transactions invalides: $invalidTransactions');
      print(
          '   - Taux de validité: ${(validTransactions / dvfData.length * 100).toStringAsFixed(1)}%');

      if (invalidTransactions > 0) {
        print('⚠️ ${invalidTransactions} transactions invalides détectées');
      } else {
        print('✅ Toutes les transactions sont valides');
      }
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des données: $e');
  }
}

/// Test de gestion d'erreurs
Future<void> testErrorHandling(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de gestion d\'erreurs');

    // Test avec des paramètres invalides
    print('\n📊 Test avec code commune invalide');
    try {
      await dvfApiService.getDvfData(
        communeCode: 'invalid_code',
        parcelCode: '0001',
      );
      print('⚠️ Aucune erreur avec code invalide');
    } catch (e) {
      print('✅ Erreur attendue avec code invalide: $e');
    }

    print('\n📊 Test avec parcelle invalide');
    try {
      await dvfApiService.getDvfData(
        communeCode: '75101',
        parcelCode: 'invalid_parcel',
      );
      print('⚠️ Aucune erreur avec parcelle invalide');
    } catch (e) {
      print('✅ Erreur attendue avec parcelle invalide: $e');
    }

    print('\n📊 Test avec dates invalides');
    try {
      final bounds = LatLngBounds(
        const LatLng(48.8566, 2.3522),
        const LatLng(48.8606, 2.3562),
      );

      await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2025, 1, 1), // Date future
        maxDate: DateTime(2020, 1, 1), // Date passée
      );
      print('⚠️ Aucune erreur avec dates invalides');
    } catch (e) {
      print('✅ Erreur attendue avec dates invalides: $e');
    }

    print('\n📊 Test avec bounds invalides');
    try {
      final invalidBounds = LatLngBounds(
        const LatLng(48.8606, 2.3562), // Nord-Est
        const LatLng(48.8566, 2.3522), // Sud-Ouest (inversé)
      );

      await dvfService.getData(bounds: invalidBounds);
      print('⚠️ Aucune erreur avec bounds invalides');
    } catch (e) {
      print('✅ Erreur attendue avec bounds invalides: $e');
    }

    print('\n📊 Test avec filtres invalides');
    try {
      final bounds = LatLngBounds(
        const LatLng(48.8566, 2.3522),
        const LatLng(48.8606, 2.3562),
      );

      await dvfService.getData(
        bounds: bounds,
        minPrice: 1000000,
        maxPrice: 100000, // Prix min > prix max
      );
      print('⚠️ Aucune erreur avec filtres invalides');
    } catch (e) {
      print('✅ Erreur attendue avec filtres invalides: $e');
    }
  } catch (e) {
    print('❌ Erreur lors du test de gestion d\'erreurs: $e');
  }
}
