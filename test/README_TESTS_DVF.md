# Tests de l'API DVF

Ce répertoire contient une suite complète de tests pour l'API DVF (Demandes de Valeurs Foncières) de l'application ImmoTool.

## Structure des Tests

### 📁 Fichiers de Tests

1. **`dvf_api_test.dart`** - Suite de tests principale utilisant le framework Flutter Test
   - Tests unitaires complets
   - Tests d'intégration
   - Tests de cache
   - Tests de gestion d'erreurs

2. **`dvf_simple_test.dart`** - Script de test simple et autonome
   - Tests de base de l'API DVF
   - Facile à exécuter et comprendre
   - Idéal pour déboguer rapidement

3. **`dvf_performance_test.dart`** - Tests de performance
   - Mesure des temps de réponse
   - Tests avec cache
   - Tests avec bounds et filtres
   - Analyse de performance

4. **`dvf_stress_test.dart`** - Tests de stress
   - Tests avec appels intensifs
   - Tests de charge
   - Tests de limite de capacité

5. **`dvf_integration_test.dart`** - Tests d'intégration complets
   - Workflow complet de l'application
   - Tests avec données réelles
   - Validation des données
   - Tests de gestion d'erreurs

6. **`dvf_validation_test.dart`** - Tests de validation des données
   - Validation des modèles
   - Validation des contraintes
   - Validation des formats
   - Tests de limites

7. **`dvf_load_test.dart`** - Tests de charge
   - Tests avec appels parallèles
   - Tests de performance avec cache
   - Tests de charge avec bounds et filtres

8. **`dvf_regression_test.dart`** - Tests de régression
   - Vérification de la compatibilité
   - Tests de stabilité
   - Tests de cohérence des résultats

## 🚀 Comment Exécuter les Tests

### Prérequis

Assurez-vous d'avoir installé :
- Flutter SDK
- Dart SDK
- Les dépendances du projet (`flutter pub get`)

### Exécution des Tests

#### 1. Tests unitaires (Flutter Test)
```bash
# Exécuter tous les tests
flutter test

# Exécuter uniquement les tests DVF
flutter test test/dvf_api_test.dart

# Exécuter avec mode verbose
flutter test test/dvf_api_test.dart --verbose
```

#### 2. Tests simples (Scripts Dart)
```bash
# Test simple
dart test/dvf_simple_test.dart

# Test de performance
dart test/dvf_performance_test.dart

# Test de stress
dart test/dvf_stress_test.dart

# Test d'intégration
dart test/dvf_integration_test.dart

# Test de validation
dart test/dvf_validation_test.dart

# Test de charge
dart test/dvf_load_test.dart

# Test de régression
dart test/dvf_regression_test.dart
```

#### 3. Exécuter tous les tests en séquence
```bash
#!/bin/bash
echo "Exécution de tous les tests DVF..."

echo "1. Test simple..."
dart test/dvf_simple_test.dart

echo "2. Test de performance..."
dart test/dvf_performance_test.dart

echo "3. Test de stress..."
dart test/dvf_stress_test.dart

echo "4. Test d'intégration..."
dart test/dvf_integration_test.dart

echo "5. Test de validation..."
dart test/dvf_validation_test.dart

echo "6. Test de charge..."
dart test/dvf_load_test.dart

echo "7. Test de régression..."
dart test/dvf_regression_test.dart

echo "Tests terminés!"
```

## 📊 Types de Tests

### Tests Fonctionnels
- ✅ Récupération des données DVF
- ✅ Récupération des parcelles
- ✅ Fonctionnement du cache
- ✅ Service DVF avec bounds
- ✅ Disponibilité du service
- ✅ Détails des propriétés

### Tests de Performance
- ⏱️ Temps de réponse des API
- 📈 Performance avec cache
- 🔄 Tests avec appels parallèles
- 📊 Analyse des statistiques

### Tests de Validation
- 🔍 Validation des modèles de données
- ✅ Validation des contraintes
- 📝 Validation des formats
- 🚨 Tests de limites

### Tests de Robustesse
- 💪 Tests de stress
- 🏋️ Tests de charge
- 🔧 Tests de gestion d'erreurs
- 🛡️ Tests de stabilité

## 🎯 Cas de Test Couverts

### API DVF Service
- [x] Récupération des données DVF avec paramètres
- [x] Gestion du cache (lecture/écriture/nettoyage)
- [x] Récupération des parcelles
- [x] Gestion des erreurs HTTP
- [x] Tests avec différents codes commune
- [x] Tests avec dates de début/fin

### DVF Service
- [x] Récupération avec bounds géographiques
- [x] Filtres par prix (min/max)
- [x] Filtres par surface (min/max)
- [x] Filtres par date (min/max)
- [x] Disponibilité du service
- [x] Détails des propriétés

### Modèles de Données
- [x] Sérialisation ImmoDataDvf
- [x] Sérialisation DvfAttributes
- [x] Sérialisation DvfLocation
- [x] Sérialisation DvfGeometry
- [x] Validation des champs obligatoires
- [x] Gestion des valeurs nulles

## 🐛 Gestion des Erreurs Testées

- ❌ Codes commune invalides
- ❌ Codes parcelle invalides
- ❌ Dates invalides
- ❌ Bounds invalides
- ❌ Filtres invalides
- ❌ Erreurs réseau
- ❌ Erreurs de sérialisation

## 📈 Métriques de Performance

Les tests mesurent :
- Temps de réponse moyen
- Temps de réponse minimum/maximum
- Transactions par seconde
- Efficacité du cache
- Charge mémoire
- Stabilité des performances

## 🔧 Configuration

### Variables d'Environnement
Aucune variable d'environnement n'est requise. Les tests utilisent les APIs publiques.

### Paramètres de Test
- **Codes commune** : 75101-75105 (Paris)
- **Codes parcelle** : 0001-0003
- **Période de test** : 2020-2024
- **Zone géographique** : Paris centre

## 📝 Rapports de Test

Les tests génèrent des rapports détaillés incluant :
- ✅ Nombre de tests réussis/échoués
- ⏱️ Temps d'exécution
- 📊 Statistiques de performance
- 🐛 Détails des erreurs
- 📈 Métriques de validation

## 🚀 Utilisation en CI/CD

Ces tests peuvent être intégrés dans un pipeline CI/CD :

```yaml
test:
  script:
    - flutter pub get
    - flutter test test/dvf_api_test.dart
    - dart test/dvf_simple_test.dart
    - dart test/dvf_performance_test.dart
```

## 🤝 Contribution

Pour ajouter de nouveaux tests :
1. Créer un nouveau fichier dans le répertoire `test/`
2. Suivre la structure existante
3. Documenter les nouveaux cas de test
4. Mettre à jour ce README

## 📞 Support

En cas de problème avec les tests :
1. Vérifier la connectivité réseau
2. Vérifier que les APIs sont disponibles
3. Consulter les logs d'erreur
4. Vérifier les dépendances Flutter/Dart

---

*Tests créés pour assurer la qualité et la robustesse de l'API DVF dans ImmoTool.*

