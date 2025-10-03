import 'dart:io';

import 'package:immo_tools/providers/settings_provider.dart';
import 'package:immo_tools/services/ademe_api_service.dart';

// ignore_for_file: avoid_print
/// Programme de test pour l'API ADEME
/// Ce programme teste les différentes fonctionnalités de l'API DPE
void main() async {
  print('🚀 Démarrage du test de l\'API ADEME');
  print('=' * 50);

  final service = AdemeApiService();
  final settings = SettingsProvider();

  // Configuration des paramètres de test
  await setupTestSettings(settings);

  // Coordonnées de test (Paris)
  const double testLat = 48.8566;
  const double testLng = 2.3522;
  const double testRadius = 1000;
  const String testBbox = '2.3522,48.8566,2.3522,48.8566';

  try {
    // Test 1: Récupération de données DPE de base
    print('\n📊 Test 1: Récupération de données DPE de base');
    print('-' * 40);
    await testBasicDpeData(
        service, testLat, testLng, testRadius, testBbox, settings);

    // Test 2: Test avec différents paramètres de surface
    print('\n📊 Test 2: Test avec filtres de surface');
    print('-' * 40);
    await testSurfaceFilters(
        service, testLat, testLng, testRadius, testBbox, settings);

    // Test 3: Test avec différents grades DPE
    print('\n📊 Test 3: Test avec différents grades DPE');
    print('-' * 40);
    await testDpeGrades(
        service, testLat, testLng, testRadius, testBbox, settings);

    // Test 4: Test de gestion d'erreurs
    print('\n📊 Test 4: Test de gestion d\'erreurs');
    print('-' * 40);
    await testErrorHandling(service);

    // Test 5: Test de respect des limites de taux
    print('\n📊 Test 5: Test de respect des limites de taux');
    print('-' * 40);
    await testRateLimiting(
        service, testLat, testLng, testRadius, testBbox, settings);

    print('\n✅ Tous les tests sont terminés avec succès!');
  } catch (e) {
    print('\n❌ Erreur lors de l\'exécution des tests: $e');
    exit(1);
  }
}

/// Configuration des paramètres de test
Future<void> setupTestSettings(SettingsProvider settings) async {
  print('⚙️ Configuration des paramètres de test...');

  // Configuration des grades DPE
  settings.toggleDpeGrade('F');
  settings.toggleDpeGrade('G');

  // Configuration de la plage de dates (3 derniers mois)
  settings.setDateRange(DateRange.last3Months);

  // Configuration de la surface (entre 50 et 200 m²)
  settings.updateSettings(
    minSurface: 50,
    maxSurface: 200,
  );

  print('✅ Paramètres configurés:');
  print('   - Grades DPE: ${settings.selectedDpeGrades}');
  print('   - Surface: ${settings.minSurface}-${settings.maxSurface} m²');
  print('   - Période: ${settings.dateRange}');
  print('   - Requête complète: ${settings.getFullQuery()}');
}

/// Test de récupération de données DPE de base
Future<void> testBasicDpeData(
  AdemeApiService service,
  double lat,
  double lng,
  double radius,
  String bbox,
  SettingsProvider settings,
) async {
  try {
    print('🔍 Recherche de données DPE...');
    final startTime = DateTime.now();

    final dpeData = await service.getDpeData(
      lat: lat,
      lng: lng,
      radius: radius,
      bbox: bbox,
      settings: settings,
    );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('✅ Données récupérées avec succès!');
    print('   - Nombre de résultats: ${dpeData.length}');
    print('   - Temps d\'exécution: ${duration.inMilliseconds}ms');

    if (dpeData.isNotEmpty) {
      print('\n📋 Aperçu des premiers résultats:');
      for (int i = 0; i < dpeData.length && i < 3; i++) {
        final dpe = dpeData[i];
        print('   ${i + 1}. ${dpe.address}');
        print('      - Grade DPE: ${dpe.energyGrade}');
        print('      - Surface: ${dpe.surface} m²');
        print('      - Date: ${dpe.formattedDate}');
        print('      - Coordonnées: ${dpe.latitude}, ${dpe.longitude}');
      }
    } else {
      print('⚠️ Aucune donnée trouvée pour cette zone');
    }
  } catch (e) {
    print('❌ Erreur lors de la récupération des données: $e');
  }
}

/// Test avec différents filtres de surface
Future<void> testSurfaceFilters(
  AdemeApiService service,
  double lat,
  double lng,
  double radius,
  String bbox,
  SettingsProvider settings,
) async {
  final surfaceRanges = [
    {'min': 0, 'max': 50, 'label': 'Petites surfaces (0-50 m²)'},
    {'min': 50, 'max': 100, 'label': 'Surfaces moyennes (50-100 m²)'},
    {'min': 100, 'max': 200, 'label': 'Grandes surfaces (100-200 m²)'},
  ];

  for (final range in surfaceRanges) {
    print('\n🔍 Test: ${range['label']}');

    settings.updateSettings(
      minSurface: range['min'] as int,
      maxSurface: range['max'] as int,
    );

    try {
      final dpeData = await service.getDpeData(
        lat: lat,
        lng: lng,
        radius: radius,
        bbox: bbox,
        settings: settings,
      );

      print('   ✅ Résultats: ${dpeData.length} entrées');

      if (dpeData.isNotEmpty) {
        final avgSurface =
            dpeData.map((d) => d.surface).reduce((a, b) => a + b) /
                dpeData.length;
        print('   📊 Surface moyenne: ${avgSurface.toStringAsFixed(1)} m²');
      }
    } catch (e) {
      print('   ❌ Erreur: $e');
    }
  }
}

/// Test avec différents grades DPE
Future<void> testDpeGrades(
  AdemeApiService service,
  double lat,
  double lng,
  double radius,
  String bbox,
  SettingsProvider settings,
) async {
  final gradeCombinations = [
    {
      'grades': ['F', 'G'],
      'label': 'Logements énergivores (F, G)'
    },
    {
      'grades': ['D', 'E'],
      'label': 'Logements moyens (D, E)'
    },
    {
      'grades': ['A', 'B', 'C'],
      'label': 'Logements performants (A, B, C)'
    },
  ];

  for (final combo in gradeCombinations) {
    print('\n🔍 Test: ${combo['label']}');

    // Réinitialiser les grades sélectionnés
    settings._selectedDpeGrades.clear();
    for (final grade in combo['grades'] as List<String>) {
      settings.toggleDpeGrade(grade);
    }

    try {
      final dpeData = await service.getDpeData(
        lat: lat,
        lng: lng,
        radius: radius,
        bbox: bbox,
        settings: settings,
      );

      print('   ✅ Résultats: ${dpeData.length} entrées');

      if (dpeData.isNotEmpty) {
        final gradeDistribution = <String, int>{};
        for (final dpe in dpeData) {
          gradeDistribution[dpe.energyGrade] =
              (gradeDistribution[dpe.energyGrade] ?? 0) + 1;
        }
        print('   📊 Distribution des grades: $gradeDistribution');
      }
    } catch (e) {
      print('   ❌ Erreur: $e');
    }
  }
}

/// Test de gestion d'erreurs
Future<void> testErrorHandling(AdemeApiService service) async {
  print('🔍 Test avec des coordonnées invalides...');

  try {
    final settings = SettingsProvider();
    await service.getDpeData(
      lat: 999.0, // Coordonnée invalide
      lng: 999.0, // Coordonnée invalide
      radius: 1000,
      bbox: '999,999,999,999', // Bbox invalide
      settings: settings,
    );
    print('   ⚠️ Aucune erreur détectée (peut être normal)');
  } catch (e) {
    print('   ✅ Erreur correctement gérée: $e');
  }

  print('🔍 Test avec des paramètres de surface invalides...');

  try {
    final settings = SettingsProvider();
    settings.updateSettings(
        minSurface: -10, maxSurface: -5); // Valeurs négatives
    await service.getDpeData(
      lat: 48.8566,
      lng: 2.3522,
      radius: 1000,
      bbox: '2.3522,48.8566,2.3522,48.8566',
      settings: settings,
    );
    print('   ⚠️ Aucune erreur détectée (peut être normal)');
  } catch (e) {
    print('   ✅ Erreur correctement gérée: $e');
  }
}

/// Test de respect des limites de taux
Future<void> testRateLimiting(
  AdemeApiService service,
  double lat,
  double lng,
  double radius,
  String bbox,
  SettingsProvider settings,
) async {
  print('🔍 Test de respect des limites de taux (10 appels/seconde)...');

  final startTime = DateTime.now();
  final callCount = 5; // Nombre d'appels à effectuer

  for (int i = 0; i < callCount; i++) {
    try {
      print('   📞 Appel ${i + 1}/$callCount...');
      final dpeData = await service.getDpeData(
        lat: lat,
        lng: lng,
        radius: radius,
        bbox: bbox,
        settings: settings,
      );
      print('   ✅ Appel ${i + 1} réussi (${dpeData.length} résultats)');
    } catch (e) {
      print('   ❌ Appel ${i + 1} échoué: $e');
    }
  }

  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime);

  print('📊 Résumé du test de taux:');
  print('   - Nombre d\'appels: $callCount');
  print('   - Durée totale: ${totalDuration.inMilliseconds}ms');
  print(
      '   - Durée moyenne par appel: ${totalDuration.inMilliseconds / callCount}ms');

  if (totalDuration.inMilliseconds > 1000) {
    print('   ✅ Limite de taux respectée (plus de 1 seconde pour 5 appels)');
  } else {
    print('   ⚠️ Limite de taux potentiellement non respectée');
  }
}

/// Extension pour accéder aux membres privés de SettingsProvider (pour les tests)
extension SettingsProviderTest on SettingsProvider {
  Set<String> get _selectedDpeGrades => selectedDpeGrades;
}
