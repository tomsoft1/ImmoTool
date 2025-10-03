import 'dart:io';

import 'package:immo_tools/providers/settings_provider.dart';
import 'package:immo_tools/services/ademe_api_service.dart';

// ignore_for_file: avoid_print
/// Programme de test simple pour l'API ADEME
/// Version simplifiée pour des tests rapides
void main() async {
  print('🚀 Test simple de l\'API ADEME');
  print('=' * 40);

  final service = AdemeApiService();
  final settings = SettingsProvider();

  // Configuration simple
  settings.toggleDpeGrade('F');
  settings.toggleDpeGrade('G');
  settings.setDateRange(DateRange.last3Months);
  settings.updateSettings(minSurface: 50, maxSurface: 200);

  // Coordonnées de Paris
  const double lat = 48.8566;
  const double lng = 2.3522;
  const String bbox = '2.3522,48.8566,2.3522,48.8566';

  try {
    print('🔍 Recherche de données DPE à Paris...');
    print('Paramètres:');
    print('  - Grades: ${settings.selectedDpeGrades}');
    print('  - Surface: ${settings.minSurface}-${settings.maxSurface} m²');
    print('  - Requête: ${settings.getFullQuery()}');
    print('');

    final startTime = DateTime.now();
    final dpeData = await service.getDpeData(
      lat: lat,
      lng: lng,
      radius: 1000,
      bbox: bbox,
      settings: settings,
    );
    final endTime = DateTime.now();

    print('✅ Résultats:');
    print('  - Nombre d\'entrées: ${dpeData.length}');
    print(
        '  - Temps d\'exécution: ${endTime.difference(startTime).inMilliseconds}ms');

    if (dpeData.isNotEmpty) {
      print('\n📋 Premiers résultats:');
      for (int i = 0; i < dpeData.length && i < 5; i++) {
        final dpe = dpeData[i];
        print('  ${i + 1}. ${dpe.address}');
        print('     Grade: ${dpe.energyGrade}, Surface: ${dpe.surface} m²');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}
