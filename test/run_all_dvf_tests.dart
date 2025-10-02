import 'dart:io';

// ignore_for_file: avoid_print
/// Script pour exécuter tous les tests DVF
/// Usage: dart test/run_all_dvf_tests.dart
void main() async {
  print('🚀 Exécution de tous les tests DVF\n');

  final tests = [
    {
      'name': 'Test simple',
      'file': 'test/dvf_simple_test.dart',
      'description': 'Tests de base de l\'API DVF'
    },
    {
      'name': 'Test de performance',
      'file': 'test/dvf_performance_test.dart',
      'description': 'Tests de performance et temps de réponse'
    },
    {
      'name': 'Test de stress',
      'file': 'test/dvf_stress_test.dart',
      'description': 'Tests de stress et charge intensive'
    },
    {
      'name': 'Test d\'intégration',
      'file': 'test/dvf_integration_test.dart',
      'description': 'Tests d\'intégration complets'
    },
    {
      'name': 'Test de validation',
      'file': 'test/dvf_validation_test.dart',
      'description': 'Tests de validation des données'
    },
    {
      'name': 'Test de charge',
      'file': 'test/dvf_load_test.dart',
      'description': 'Tests de charge et appels parallèles'
    },
    {
      'name': 'Test de régression',
      'file': 'test/dvf_regression_test.dart',
      'description': 'Tests de régression et stabilité'
    },
  ];

  final results = <Map<String, dynamic>>[];

  for (int i = 0; i < tests.length; i++) {
    final test = tests[i];
    print('📊 ${i + 1}/${tests.length} - ${test['name']}');
    print('   ${test['description']}');

    final start = DateTime.now();

    try {
      final result = await Process.run(
        'dart',
        [test['file']!],
        workingDirectory: '.',
      );

      final duration = DateTime.now().difference(start);

      if (result.exitCode == 0) {
        print('   ✅ Réussi en ${duration.inMilliseconds}ms\n');
        results.add({
          'name': test['name'],
          'status': 'success',
          'duration': duration.inMilliseconds,
          'output': result.stdout,
        });
      } else {
        print('   ❌ Échoué en ${duration.inMilliseconds}ms');
        print('   Erreur: ${result.stderr}\n');
        results.add({
          'name': test['name'],
          'status': 'failed',
          'duration': duration.inMilliseconds,
          'error': result.stderr,
        });
      }
    } catch (e) {
      final duration = DateTime.now().difference(start);
      print('   ❌ Exception en ${duration.inMilliseconds}ms: $e\n');
      results.add({
        'name': test['name'],
        'status': 'error',
        'duration': duration.inMilliseconds,
        'error': e.toString(),
      });
    }
  }

  // Résumé final
  print('📊 RÉSUMÉ DES TESTS DVF');
  print('=' * 50);

  final successful = results.where((r) => r['status'] == 'success').length;
  final failed = results.where((r) => r['status'] == 'failed').length;
  final errors = results.where((r) => r['status'] == 'error').length;

  print('✅ Tests réussis: $successful');
  print('❌ Tests échoués: $failed');
  print('🚨 Erreurs: $errors');
  print('📊 Total: ${results.length}');

  final totalDuration =
      results.fold(0, (sum, r) => sum + (r['duration'] as int));
  print(
      '⏱️ Temps total: ${totalDuration}ms (${(totalDuration / 1000).toStringAsFixed(1)}s)');

  if (successful > 0) {
    final avgDuration = results
            .where((r) => r['status'] == 'success')
            .fold(0, (sum, r) => sum + (r['duration'] as int)) /
        successful;
    print(
        '📈 Temps moyen par test réussi: ${avgDuration.toStringAsFixed(0)}ms');
  }

  print('\n📋 DÉTAILS PAR TEST:');
  for (final result in results) {
    final icon = result['status'] == 'success' ? '✅' : '❌';
    print('$icon ${result['name']}: ${result['duration']}ms');
    if (result['status'] != 'success' && result['error'] != null) {
      print('   Erreur: ${result['error']}');
    }
  }

  if (failed == 0 && errors == 0) {
    print('\n🎉 Tous les tests DVF ont réussi!');
    exit(0);
  } else {
    print('\n⚠️ Certains tests ont échoué. Vérifiez les détails ci-dessus.');
    exit(1);
  }
}
