#!/bin/bash

# Script pour exécuter tous les tests DVF
# Usage: chmod +x test/run_tests.sh && ./test/run_tests.sh

echo "🚀 Exécution de tous les tests DVF..."
echo "=================================="

# Vérifier que Flutter/Dart est installé
if ! command -v dart &> /dev/null; then
    echo "❌ Dart n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Ce script doit être exécuté depuis la racine du projet Flutter"
    exit 1
fi

# Installer les dépendances si nécessaire
echo "📦 Vérification des dépendances..."
flutter pub get

# Compteurs
total_tests=0
passed_tests=0
failed_tests=0
start_time=$(date +%s)

# Liste des tests à exécuter
tests=(
    "test/dvf_simple_test.dart|Test simple"
    "test/dvf_performance_test.dart|Test de performance"
    "test/dvf_stress_test.dart|Test de stress"
    "test/dvf_integration_test.dart|Test d'intégration"
    "test/dvf_validation_test.dart|Test de validation"
    "test/dvf_load_test.dart|Test de charge"
    "test/dvf_regression_test.dart|Test de régression"
)

echo ""
echo "📋 Tests à exécuter: ${#tests[@]}"
echo ""

# Exécuter chaque test
for test_info in "${tests[@]}"; do
    IFS='|' read -r test_file test_name <<< "$test_info"
    total_tests=$((total_tests + 1))
    
    echo "📊 [$total_tests/${#tests[@]}] $test_name"
    echo "   Fichier: $test_file"
    
    test_start=$(date +%s)
    
    if dart "$test_file" > /tmp/test_output.log 2>&1; then
        test_end=$(date +%s)
        test_duration=$((test_end - test_start))
        echo "   ✅ Réussi en ${test_duration}s"
        passed_tests=$((passed_tests + 1))
    else
        test_end=$(date +%s)
        test_duration=$((test_end - test_start))
        echo "   ❌ Échoué en ${test_duration}s"
        echo "   Erreur: $(tail -n 3 /tmp/test_output.log)"
        failed_tests=$((failed_tests + 1))
    fi
    
    echo ""
done

# Calculer le temps total
end_time=$(date +%s)
total_duration=$((end_time - start_time))

# Afficher le résumé
echo "📊 RÉSUMÉ DES TESTS DVF"
echo "======================"
echo "✅ Tests réussis: $passed_tests"
echo "❌ Tests échoués: $failed_tests"
echo "📊 Total: $total_tests"
echo "⏱️ Temps total: ${total_duration}s"

if [ $failed_tests -eq 0 ]; then
    echo ""
    echo "🎉 Tous les tests DVF ont réussi!"
    
    # Exécuter aussi les tests Flutter si disponible
    if [ -f "test/dvf_api_test.dart" ]; then
        echo ""
        echo "🧪 Exécution des tests Flutter..."
        if flutter test test/dvf_api_test.dart; then
            echo "✅ Tests Flutter réussis"
        else
            echo "❌ Tests Flutter échoués"
            exit 1
        fi
    fi
    
    exit 0
else
    echo ""
    echo "⚠️ $failed_tests test(s) ont échoué."
    echo "💡 Vérifiez:"
    echo "   - La connectivité réseau"
    echo "   - La disponibilité des APIs"
    echo "   - Les logs d'erreur ci-dessus"
    exit 1
fi

