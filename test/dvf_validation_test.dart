import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_print
/// Script de test de validation des données pour l'API DVF
/// Peut être exécuté avec: dart test/dvf_validation_test.dart
void main() async {
  print('🚀 Test de validation des données de l\'API DVF\n');

  final dvfApiService = DvfApiService();
  final dvfService = DvfService();

  // Test de validation complet
  print('=== Test de validation des données ===');
  await testDataValidation(dvfApiService, dvfService);

  print('\n=== Test de validation des modèles ===');
  await testModelValidation(dvfApiService, dvfService);

  print('\n=== Test de validation des contraintes ===');
  await testConstraintValidation(dvfApiService, dvfService);

  print('\n=== Test de validation des formats ===');
  await testFormatValidation(dvfApiService, dvfService);

  print('\n=== Test de validation des limites ===');
  await testLimitValidation(dvfApiService, dvfService);

  print('\n🎉 Tests de validation terminés!');
}

/// Test de validation des données
Future<void> testDataValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des données DVF');

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
      final issues = <String>[];

      for (final transaction in dvfData) {
        bool isValid = true;
        final transactionIssues = <String>[];

        // Validation des champs obligatoires
        if (transaction.txDate.isEmpty) {
          isValid = false;
          transactionIssues.add('Date manquante');
        }

        if (transaction.price <= 0) {
          isValid = false;
          transactionIssues.add('Prix invalide');
        }

        if (transaction.location.latitude == 0 &&
            transaction.location.longitude == 0) {
          isValid = false;
          transactionIssues.add('Coordonnées invalides');
        }

        if (transaction.location.latitude == 0 &&
            transaction.location.longitude == 0) {
          isValid = false;
          transactionIssues.add('Coordonnées nulles');
        }

        if (transaction.attributes.livingArea != null &&
            transaction.attributes.livingArea! <= 0) {
          isValid = false;
          transactionIssues.add('Surface invalide');
        }

        if (transaction.squareMeterPrice < 0) {
          isValid = false;
          transactionIssues.add('Prix au m² invalide');
        }

        if (isValid) {
          validTransactions++;
        } else {
          invalidTransactions++;
          issues.addAll(transactionIssues);

          if (invalidTransactions <= 5) {
            print('❌ Transaction invalide: ${transactionIssues.join(', ')}');
          }
        }
      }

      print('📊 Résultats de validation:');
      print('   - Transactions valides: $validTransactions');
      print('   - Transactions invalides: $invalidTransactions');
      print(
          '   - Taux de validité: ${(validTransactions / dvfData.length * 100).toStringAsFixed(1)}%');

      if (invalidTransactions > 0) {
        print('⚠️ $invalidTransactions transactions invalides détectées');

        // Analyse des problèmes les plus fréquents
        final issueCounts = <String, int>{};
        for (final issue in issues) {
          issueCounts[issue] = (issueCounts[issue] ?? 0) + 1;
        }

        print('\n📊 Problèmes les plus fréquents:');
        final sortedIssues = issueCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (final entry in sortedIssues.take(5)) {
          print('   - ${entry.key}: ${entry.value} occurrences');
        }
      } else {
        print('✅ Toutes les transactions sont valides');
      }
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des données: $e');
  }
}

/// Test de validation des modèles
Future<void> testModelValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des modèles');

    // Test de sérialisation/désérialisation
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

    try {
      final immoData = ImmoDataDvf.fromJson(testJson);
      print('✅ ImmoDataDvf créé avec succès');

      // Validation des champs
      bool isValid = true;
      final issues = <String>[];

      if (immoData.txDate != '2023-01-15') {
        isValid = false;
        issues.add('Date incorrecte');
      }

      if (immoData.price != 250000.0) {
        isValid = false;
        issues.add('Prix incorrect');
      }

      if (immoData.squareMeterPrice != 5000.0) {
        isValid = false;
        issues.add('Prix au m² incorrect');
      }

      if (immoData.attributes.livingArea != 50.0) {
        isValid = false;
        issues.add('Surface incorrecte');
      }

      if (immoData.attributes.rooms != 3) {
        isValid = false;
        issues.add('Nombre de pièces incorrect');
      }

      if (immoData.location.cityName != 'Paris') {
        isValid = false;
        issues.add('Nom de ville incorrect');
      }

      if (immoData.location.latitude != 48.8566) {
        isValid = false;
        issues.add('Latitude incorrecte');
      }

      if (immoData.location.longitude != 2.3522) {
        isValid = false;
        issues.add('Longitude incorrecte');
      }

      if (isValid) {
        print('✅ Modèle validé avec succès');
      } else {
        print('❌ Modèle invalide: ${issues.join(', ')}');
      }
    } catch (e) {
      print('❌ Erreur lors de la création du modèle: $e');
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des modèles: $e');
  }
}

/// Test de validation des contraintes
Future<void> testConstraintValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des contraintes');

    // Test avec des contraintes de prix
    print('\n📊 Test avec contraintes de prix');
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522),
      const LatLng(48.8606, 2.3562),
    );

    try {
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minPrice: 100000,
        maxPrice: 500000,
      );

      print(
          '✅ ${dvfData.length} transactions récupérées avec contraintes de prix');

      if (dvfData.isNotEmpty) {
        bool allPricesValid = true;
        for (final transaction in dvfData) {
          if (transaction.price < 100000 || transaction.price > 500000) {
            allPricesValid = false;
            print('❌ Prix invalide: ${transaction.price}€ (hors contraintes)');
            break;
          }
        }

        if (allPricesValid) {
          print('✅ Toutes les transactions respectent les contraintes de prix');
        } else {
          print(
              '❌ Certaines transactions ne respectent pas les contraintes de prix');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du test avec contraintes de prix: $e');
    }

    // Test avec des contraintes de surface
    print('\n📊 Test avec contraintes de surface');
    try {
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minSurface: 50,
        maxSurface: 100,
      );

      print(
          '✅ ${dvfData.length} transactions récupérées avec contraintes de surface');

      if (dvfData.isNotEmpty) {
        bool allSurfacesValid = true;
        for (final transaction in dvfData) {
          if (transaction.attributes.livingArea != null) {
            if (transaction.attributes.livingArea! < 50 ||
                transaction.attributes.livingArea! > 100) {
              allSurfacesValid = false;
              print(
                  '❌ Surface invalide: ${transaction.attributes.livingArea}m² (hors contraintes)');
              break;
            }
          }
        }

        if (allSurfacesValid) {
          print(
              '✅ Toutes les transactions respectent les contraintes de surface');
        } else {
          print(
              '❌ Certaines transactions ne respectent pas les contraintes de surface');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du test avec contraintes de surface: $e');
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des contraintes: $e');
  }
}

/// Test de validation des formats
Future<void> testFormatValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des formats');

    final dvfData = await dvfApiService.getDvfData(
      communeCode: '75101',
      parcelCode: '0001',
      startDate: '2020-01-01',
      endDate: '2024-01-01',
    );

    print(
        '✅ ${dvfData.length} transactions récupérées pour validation des formats');

    if (dvfData.isNotEmpty) {
      int validFormats = 0;
      int invalidFormats = 0;
      final formatIssues = <String>[];

      for (final transaction in dvfData) {
        bool isValidFormat = true;
        final transactionFormatIssues = <String>[];

        // Validation du format de date
        if (transaction.txDate.isNotEmpty) {
          try {
            DateTime.parse(transaction.txDate);
          } catch (e) {
            isValidFormat = false;
            transactionFormatIssues
                .add('Format de date invalide: ${transaction.txDate}');
          }
        }

        // Validation du format des coordonnées
        if (transaction.location.latitude == 0 &&
            transaction.location.longitude == 0) {
          isValidFormat = false;
          transactionFormatIssues.add('Format de coordonnées invalide');
        } else {
          final lat = transaction.location.latitude;
          final lng = transaction.location.longitude;

          if (lat < -90 || lat > 90) {
            isValidFormat = false;
            transactionFormatIssues.add('Latitude invalide: $lat');
          }

          if (lng < -180 || lng > 180) {
            isValidFormat = false;
            transactionFormatIssues.add('Longitude invalide: $lng');
          }
        }

        // Validation du format du prix
        if (transaction.price < 0) {
          isValidFormat = false;
          transactionFormatIssues.add('Prix négatif: ${transaction.price}');
        }

        // Validation du format de la surface
        if (transaction.attributes.livingArea != null &&
            transaction.attributes.livingArea! < 0) {
          isValidFormat = false;
          transactionFormatIssues
              .add('Surface négative: ${transaction.attributes.livingArea}');
        }

        // Validation du format du prix au m²
        if (transaction.squareMeterPrice < 0) {
          isValidFormat = false;
          transactionFormatIssues
              .add('Prix au m² négatif: ${transaction.squareMeterPrice}');
        }

        if (isValidFormat) {
          validFormats++;
        } else {
          invalidFormats++;
          formatIssues.addAll(transactionFormatIssues);

          if (invalidFormats <= 5) {
            print('❌ Format invalide: ${transactionFormatIssues.join(', ')}');
          }
        }
      }

      print('📊 Résultats de validation des formats:');
      print('   - Formats valides: $validFormats');
      print('   - Formats invalides: $invalidFormats');
      print(
          '   - Taux de validité: ${(validFormats / dvfData.length * 100).toStringAsFixed(1)}%');

      if (invalidFormats > 0) {
        print('⚠️ $invalidFormats formats invalides détectés');

        // Analyse des problèmes de format les plus fréquents
        final formatIssueCounts = <String, int>{};
        for (final issue in formatIssues) {
          formatIssueCounts[issue] = (formatIssueCounts[issue] ?? 0) + 1;
        }

        print('\n📊 Problèmes de format les plus fréquents:');
        final sortedFormatIssues = formatIssueCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (final entry in sortedFormatIssues.take(5)) {
          print('   - ${entry.key}: ${entry.value} occurrences');
        }
      } else {
        print('✅ Tous les formats sont valides');
      }
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des formats: $e');
  }
}

/// Test de validation des limites
Future<void> testLimitValidation(
    DvfApiService dvfApiService, DvfService dvfService) async {
  try {
    print('🔍 Test de validation des limites');

    // Test avec des limites de prix extrêmes
    print('\n📊 Test avec limites de prix extrêmes');
    final bounds = LatLngBounds(
      const LatLng(48.8566, 2.3522),
      const LatLng(48.8606, 2.3562),
    );

    try {
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minPrice: 1,
        maxPrice: 10000000,
      );

      print(
          '✅ ${dvfData.length} transactions récupérées avec limites de prix extrêmes');

      if (dvfData.isNotEmpty) {
        final prices = dvfData.map((d) => d.price).toList();
        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);
        final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

        print('📊 Statistiques des prix:');
        print('   - Prix min: ${minPrice.toStringAsFixed(0)}€');
        print('   - Prix max: ${maxPrice.toStringAsFixed(0)}€');
        print('   - Prix moyen: ${avgPrice.toStringAsFixed(0)}€');

        // Validation des limites
        bool pricesWithinLimits = true;
        for (final price in prices) {
          if (price < 1 || price > 10000000) {
            pricesWithinLimits = false;
            print('❌ Prix hors limites: $price€');
            break;
          }
        }

        if (pricesWithinLimits) {
          print('✅ Tous les prix sont dans les limites');
        } else {
          print('❌ Certains prix sont hors limites');
        }
      }
    } catch (e) {
      print('❌ Erreur lors du test avec limites de prix: $e');
    }

    // Test avec des limites de surface extrêmes
    print('\n📊 Test avec limites de surface extrêmes');
    try {
      final dvfData = await dvfService.getData(
        bounds: bounds,
        minDate: DateTime(2020, 1, 1),
        maxDate: DateTime(2024, 1, 1),
        minSurface: 1,
        maxSurface: 10000,
      );

      print(
          '✅ ${dvfData.length} transactions récupérées avec limites de surface extrêmes');

      if (dvfData.isNotEmpty) {
        final surfaces = dvfData
            .map((d) => d.attributes.livingArea)
            .where((s) => s != null)
            .map((s) => s!)
            .toList();

        if (surfaces.isNotEmpty) {
          final minSurface = surfaces.reduce((a, b) => a < b ? a : b);
          final maxSurface = surfaces.reduce((a, b) => a > b ? a : b);
          final avgSurface = surfaces.reduce((a, b) => a + b) / surfaces.length;

          print('📊 Statistiques des surfaces:');
          print('   - Surface min: ${minSurface.toStringAsFixed(1)}m²');
          print('   - Surface max: ${maxSurface.toStringAsFixed(1)}m²');
          print('   - Surface moyenne: ${avgSurface.toStringAsFixed(1)}m²');

          // Validation des limites
          bool surfacesWithinLimits = true;
          for (final surface in surfaces) {
            if (surface < 1 || surface > 10000) {
              surfacesWithinLimits = false;
              print('❌ Surface hors limites: ${surface}m²');
              break;
            }
          }

          if (surfacesWithinLimits) {
            print('✅ Toutes les surfaces sont dans les limites');
          } else {
            print('❌ Certaines surfaces sont hors limites');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors du test avec limites de surface: $e');
    }
  } catch (e) {
    print('❌ Erreur lors de la validation des limites: $e');
  }
}
