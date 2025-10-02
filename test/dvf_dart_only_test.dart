import 'dart:convert';
import 'dart:io';

// ignore_for_file: avoid_print
/// Test simple de l'API DVF utilisant seulement Dart (sans Flutter)
/// Usage: dart test/dvf_dart_only_test.dart
void main() async {
  print('🚀 Test simple de l\'API DVF (Dart seulement)\n');

  // Test de l'API DVF Etalab
  print('=== Test API DVF Etalab ===');
  await testDvfApi();

  print('\n=== Test API Cadastre ===');
  await testCadastreApi();

  print('\n🎉 Tests terminés!');
}

/// Test de l'API DVF
Future<void> testDvfApi() async {
  try {
    final client = HttpClient();

    // Test avec Paris 1er arrondissement
    const communeCode = '75101';
    const parcelCode = '00AB';
    const baseUrl = 'https://app.dvf.etalab.gouv.fr/api';

    final uri = Uri.parse('$baseUrl/mutations3/$communeCode/$parcelCode');
    final request = await client.getUrl(uri);
    request.headers.set('Accept', 'application/json');

    print('📊 Requête: ${uri.toString()}');

    final response = await request.close();

    print('📈 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);

      if (data is Map<String, dynamic> && data['mutations'] != null) {
        final mutations = data['mutations'] as List;
        print('✅ ${mutations.length} transactions DVF trouvées');

        if (mutations.isNotEmpty) {
          final firstMutation = mutations.first;
          print('📊 Première transaction:');
          print('   - Date: ${firstMutation['date_mutation']}');
          print('   - Prix: ${firstMutation['valeur_fonciere']}€');
          print('   - Surface: ${firstMutation['lot1_surface_carrez']}m²');
          print('   - Commune: ${firstMutation['nom_commune']}');

          // Calculer le prix au m² si possible
          final prix = double.tryParse(
                  firstMutation['valeur_fonciere']?.toString() ?? '0') ??
              0;
          final surface = double.tryParse(
                  firstMutation['lot1_surface_carrez']?.toString() ?? '0') ??
              0;
          if (surface > 0) {
            final prixM2 = prix / surface;
            print('   - Prix/m²: ${prixM2.toStringAsFixed(0)}€');
          }
        }
      } else {
        print('⚠️ Aucune donnée DVF trouvée');
      }
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('❌ Erreur lors du test DVF: $e');
  }
}

/// Test de l'API Cadastre
Future<void> testCadastreApi() async {
  try {
    final client = HttpClient();

    const communeCode = '75101';
    const cadastreUrl = 'https://cadastre.data.gouv.fr';
    const url =
        '$cadastreUrl/bundler/cadastre-etalab/communes/$communeCode/geojson/parcelles';

    final uri = Uri.parse(url);
    final request = await client.getUrl(uri);

    print('📊 Requête: ${uri.toString()}');

    final response = await request.close();

    print('📈 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);

      if (data is Map<String, dynamic> && data['features'] != null) {
        final features = data['features'] as List;
        print('✅ ${features.length} parcelles trouvées');

        if (features.isNotEmpty) {
          final firstParcel = features.first;
          final properties = firstParcel['properties'] as Map<String, dynamic>;
          print('📊 Première parcelle:');
          print('   - ID: ${properties['id']}');
          print('   - Section: ${properties['section']}');
          print('   - Numéro: ${properties['numero']}');
          print('   - Contenance: ${properties['contenance']}m²');
          print('   - Commune: ${properties['commune']}');
        }
      } else {
        print('⚠️ Aucune parcelle trouvée');
      }
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('❌ Erreur lors du test Cadastre: $e');
  }
}

/// Test de validation JSON
void testJsonValidation() {
  print('\n=== Test de validation JSON ===');

  // Test de sérialisation d'un objet DVF
  final testMutation = {
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
    // Validation des champs obligatoires
    final requiredFields = [
      'date_mutation',
      'valeur_fonciere',
      'nom_commune',
      'longitude',
      'latitude'
    ];

    bool isValid = true;
    for (final field in requiredFields) {
      if (!testMutation.containsKey(field) || testMutation[field] == null) {
        print('❌ Champ manquant: $field');
        isValid = false;
      }
    }

    if (isValid) {
      print('✅ Validation réussie pour la mutation de test');

      // Calcul du prix au m²
      final prix =
          double.tryParse(testMutation['valeur_fonciere']?.toString() ?? '0') ??
              0;
      final surface = double.tryParse(
              testMutation['lot1_surface_carrez']?.toString() ?? '0') ??
          0;

      if (surface > 0) {
        final prixM2 = prix / surface;
        print('📊 Prix calculé: ${prix.toStringAsFixed(0)}€');
        print('📏 Surface: ${surface.toStringAsFixed(1)}m²');
        print('💰 Prix/m²: ${prixM2.toStringAsFixed(0)}€');
      }
    }
  } catch (e) {
    print('❌ Erreur lors de la validation: $e');
  }
}
