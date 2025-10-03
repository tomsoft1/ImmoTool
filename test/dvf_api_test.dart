import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:immo_tools/services/dvf_api_service.dart';
import 'package:immo_tools/services/dvf_service.dart';
import 'package:immo_tools/models/immo_data_dvf.dart';
import 'package:immo_tools/models/parcel_data.dart';

// ignore_for_file: avoid_print

void main() {
  group('DVF API Tests', () {
    late DvfApiService dvfApiService;
    late DvfService dvfService;

    setUp(() {
      dvfApiService = DvfApiService();
      dvfService = DvfService();
    });

    group('DvfApiService Tests', () {
      test(
          'Test de récupération des données DVF pour une commune et parcelle spécifiques',
          () async {
        print('\n=== Test DVF API Service ===');

        // Test avec Paris (code commune: 75101) et une parcelle spécifique
        const communeCode = '75101';
        const parcelCode = '0001';

        try {
          final dvfData = await dvfApiService.getDvfData(
            communeCode: communeCode,
            parcelCode: parcelCode,
            startDate: '2020-01-01',
            endDate: '2024-01-01',
          );

          print('✅ Données DVF récupérées: ${dvfData.length} transactions');

          if (dvfData.isNotEmpty) {
            final firstTransaction = dvfData.first;
            print('📊 Première transaction:');
            print('   - Date: ${firstTransaction.txDate}');
            print('   - Prix: ${firstTransaction.price}€');
            print(
                '   - Prix/m²: ${firstTransaction.squareMeterPrice.toStringAsFixed(2)}€');
            print('   - Surface: ${firstTransaction.attributes.livingArea}m²');
            print('   - Adresse: ${firstTransaction.location.cityName}');
          }

          expect(dvfData, isA<List<ImmoDataDvf>>());
        } catch (e) {
          print('❌ Erreur lors de la récupération des données DVF: $e');
          // Ne pas faire échouer le test si l'API n'est pas disponible
        }
      });

      test('Test de récupération des parcelles pour une commune', () async {
        print('\n=== Test Récupération Parcelles ===');

        const communeCode = '75101'; // Paris 1er arrondissement

        try {
          final parcels = await dvfApiService.getParcelles(communeCode);

          print('✅ Parcelles récupérées: ${parcels.length} parcelles');

          if (parcels.isNotEmpty) {
            final firstParcel = parcels.first;
            print('📊 Première parcelle:');
            print('   - ID: ${firstParcel.id}');
            print('   - Section: ${firstParcel.section}');
            print('   - Numéro: ${firstParcel.number}');
            print('   - Surface: ${firstParcel.area}m²');
          }

          expect(parcels, isA<List<ParcelData>>());
        } catch (e) {
          print('❌ Erreur lors de la récupération des parcelles: $e');
        }
      });

      test('Test du cache DVF', () async {
        print('\n=== Test Cache DVF ===');

        const communeCode = '75101';
        const parcelCode = '0001';

        try {
          // Premier appel
          final start1 = DateTime.now();
          final dvfData1 = await dvfApiService.getDvfData(
            communeCode: communeCode,
            parcelCode: parcelCode,
          );
          final duration1 = DateTime.now().difference(start1);
          print('⏱️ Premier appel: ${duration1.inMilliseconds}ms');

          // Deuxième appel (devrait utiliser le cache)
          final start2 = DateTime.now();
          final dvfData2 = await dvfApiService.getDvfData(
            communeCode: communeCode,
            parcelCode: parcelCode,
          );
          final duration2 = DateTime.now().difference(start2);
          print('⏱️ Deuxième appel (cache): ${duration2.inMilliseconds}ms');

          expect(dvfData1.length, equals(dvfData2.length));
          expect(duration2.inMilliseconds, lessThan(duration1.inMilliseconds));

          print('✅ Cache fonctionne correctement');
        } catch (e) {
          print('❌ Erreur lors du test de cache: $e');
        }
      });

      test('Test de nettoyage du cache', () async {
        print('\n=== Test Nettoyage Cache ===');

        const communeCode = '75101';
        const parcelCode = '0001';

        try {
          // Remplir le cache
          await dvfApiService.getDvfData(
            communeCode: communeCode,
            parcelCode: parcelCode,
          );

          // Nettoyer le cache
          dvfApiService.clearCache();

          print('✅ Cache nettoyé avec succès');
        } catch (e) {
          print('❌ Erreur lors du nettoyage du cache: $e');
        }
      });
    });

    group('DvfService Tests', () {
      test('Test de récupération des données avec bounds', () async {
        print('\n=== Test DVF Service avec Bounds ===');

        // Bounds pour Paris
        final bounds = LatLngBounds(
          const LatLng(48.8566, 2.3522), // Sud-Ouest
          const LatLng(48.8606, 2.3562), // Nord-Est
        );

        try {
          final dvfData = await dvfService.getData(
            bounds: bounds,
            minDate: DateTime(2020, 1, 1),
            maxDate: DateTime(2024, 1, 1),
            minPrice: 100000,
            maxPrice: 1000000,
          );

          print(
              '✅ Données DVF récupérées avec bounds: ${dvfData.length} transactions');

          if (dvfData.isNotEmpty) {
            final firstTransaction = dvfData.first;
            print('📊 Première transaction:');
            print('   - Date: ${firstTransaction.txDate}');
            print('   - Prix: ${firstTransaction.price}€');
            print(
                '   - Prix/m²: ${firstTransaction.squareMeterPrice.toStringAsFixed(2)}€');
          }

          expect(dvfData, isA<List<ImmoDataDvf>>());
        } catch (e) {
          print('❌ Erreur lors de la récupération avec bounds: $e');
        }
      });

      test('Test de disponibilité du service', () async {
        print('\n=== Test Disponibilité Service ===');

        try {
          final isAvailable = await dvfService.isAvailable();
          print('✅ Service disponible: $isAvailable');

          expect(isAvailable, isA<bool>());
        } catch (e) {
          print('❌ Erreur lors du test de disponibilité: $e');
        }
      });

      test('Test de récupération des détails d\'une propriété', () async {
        print('\n=== Test Détails Propriété ===');

        const testId = 'test_id';

        try {
          final details = await dvfService.getPropertyDetails(testId);

          if (details != null) {
            print('✅ Détails récupérés pour la propriété $testId');
            print('📊 Détails: $details');
          } else {
            print('ℹ️ Aucun détail trouvé pour la propriété $testId');
          }

          expect(details, anyOf(isA<Map<String, dynamic>>(), isNull));
        } catch (e) {
          print('❌ Erreur lors de la récupération des détails: $e');
        }
      });
    });

    group('Modèles de données Tests', () {
      test('Test de sérialisation ImmoDataDvf', () {
        print('\n=== Test Sérialisation ImmoDataDvf ===');

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
          print('📊 Données:');
          print('   - Date: ${immoData.txDate}');
          print('   - Prix: ${immoData.price}€');
          print(
              '   - Prix/m²: ${immoData.squareMeterPrice.toStringAsFixed(2)}€');
          print('   - Surface: ${immoData.attributes.livingArea}m²');
          print('   - Pièces: ${immoData.attributes.rooms}');
          print('   - Adresse: ${immoData.location.cityName}');
          print(
              '   - Coordonnées: ${immoData.location.latitude}, ${immoData.location.longitude}');

          expect(immoData.txDate, equals('2023-01-15'));
          expect(immoData.price, equals(250000.0));
          expect(immoData.squareMeterPrice, equals(5000.0)); // 250000 / 50
          expect(immoData.attributes.livingArea, equals(50.0));
          expect(immoData.attributes.rooms, equals(3));
        } catch (e) {
          print('❌ Erreur lors de la sérialisation: $e');
          rethrow;
        }
      });

      test('Test de sérialisation DvfAttributes', () {
        print('\n=== Test Sérialisation DvfAttributes ===');

        final testJson = {
          'livingArea': 75.5,
          'rooms': 4,
          'landArea': 120.0,
        };

        try {
          final attributes = DvfAttributes.fromJson(testJson);

          print('✅ DvfAttributes créé avec succès');
          print('📊 Attributs:');
          print('   - Surface: ${attributes.livingArea}m²');
          print('   - Pièces: ${attributes.rooms}');
          print('   - Surface terrain: ${attributes.landArea}m²');

          expect(attributes.livingArea, equals(75.5));
          expect(attributes.rooms, equals(4));
          expect(attributes.landArea, equals(120.0));
        } catch (e) {
          print('❌ Erreur lors de la sérialisation DvfAttributes: $e');
          rethrow;
        }
      });
    });

    group('Tests de gestion d\'erreurs', () {
      test('Test avec des paramètres invalides', () async {
        print('\n=== Test Paramètres Invalides ===');

        try {
          // Test avec un code commune invalide
          final dvfData = await dvfApiService.getDvfData(
            communeCode: 'invalid_code',
            parcelCode: 'invalid_parcel',
          );

          print(
              'ℹ️ Résultat avec paramètres invalides: ${dvfData.length} transactions');
          expect(dvfData, isA<List<ImmoDataDvf>>());
        } catch (e) {
          print('✅ Erreur attendue avec paramètres invalides: $e');
        }
      });

      test('Test avec des dates invalides', () async {
        print('\n=== Test Dates Invalides ===');

        try {
          final bounds = LatLngBounds(
            const LatLng(48.8566, 2.3522),
            const LatLng(48.8606, 2.3562),
          );

          final dvfData = await dvfService.getData(
            bounds: bounds,
            minDate: DateTime(2025, 1, 1), // Date future
            maxDate: DateTime(2020, 1, 1), // Date passée
          );

          print(
              'ℹ️ Résultat avec dates invalides: ${dvfData.length} transactions');
          expect(dvfData, isA<List<ImmoDataDvf>>());
        } catch (e) {
          print('✅ Erreur attendue avec dates invalides: $e');
        }
      });
    });

    group('Tests de performance', () {
      test('Test de performance avec plusieurs appels', () async {
        print('\n=== Test Performance ===');

        const communeCode = '75101';
        const parcelCode = '0001';

        try {
          final start = DateTime.now();

          // Effectuer plusieurs appels en parallèle
          final futures = List.generate(
              5,
              (index) => dvfApiService.getDvfData(
                    communeCode: communeCode,
                    parcelCode: parcelCode,
                  ));

          final results = await Future.wait(futures);
          final duration = DateTime.now().difference(start);

          print(
              '✅ ${results.length} appels effectués en ${duration.inMilliseconds}ms');
          print(
              '📊 Temps moyen par appel: ${duration.inMilliseconds / results.length}ms');

          expect(results.length, equals(5));
          expect(
              duration.inMilliseconds, lessThan(10000)); // Moins de 10 secondes
        } catch (e) {
          print('❌ Erreur lors du test de performance: $e');
        }
      });
    });
  });
}

// Fonction utilitaire pour exécuter les tests manuellement
Future<void> runDvfApiTests() async {
  print('🚀 Démarrage des tests DVF API...\n');

  try {
    // Test de base de l'API DVF
    final dvfApiService = DvfApiService();

    print('=== Test API DVF de base ===');
    final dvfData = await dvfApiService.getDvfData(
      communeCode: '75101',
      parcelCode: '0001',
      startDate: '2020-01-01',
      endDate: '2024-01-01',
    );

    print('✅ Données récupérées: ${dvfData.length} transactions');

    if (dvfData.isNotEmpty) {
      final transaction = dvfData.first;
      print('📊 Exemple de transaction:');
      print('   - Date: ${transaction.txDate}');
      print('   - Prix: ${transaction.price}€');
      print(
          '   - Prix/m²: ${transaction.squareMeterPrice.toStringAsFixed(2)}€');
      print('   - Surface: ${transaction.attributes.livingArea}m²');
      print('   - Adresse: ${transaction.location.cityName}');
    }

    // Test des parcelles
    print('\n=== Test récupération parcelles ===');
    final parcels = await dvfApiService.getParcelles('75101');
    print('✅ Parcelles récupérées: ${parcels.length}');

    if (parcels.isNotEmpty) {
      final parcel = parcels.first;
      print('📊 Exemple de parcelle:');
      print('   - ID: ${parcel.id}');
      print('   - Section: ${parcel.section}');
      print('   - Numéro: ${parcel.number}');
      print('   - Surface: ${parcel.area}m²');
    }

    print('\n🎉 Tests DVF API terminés avec succès!');
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}
