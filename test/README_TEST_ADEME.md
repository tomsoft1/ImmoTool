# Test de l'API ADEME

Ce dossier contient des programmes de test pour l'API ADEME utilisée dans l'application ImmoTool.

## Fichiers de test

### 1. `test_ademe_api.dart` - Test complet
Programme de test complet qui teste toutes les fonctionnalités de l'API ADEME :
- Récupération de données DPE de base
- Tests avec différents filtres de surface
- Tests avec différents grades DPE
- Tests de gestion d'erreurs
- Tests de respect des limites de taux

### 2. `test_ademe_simple.dart` - Test simple
Version simplifiée pour des tests rapides avec les paramètres par défaut.

## Comment exécuter les tests

### Prérequis
- Flutter SDK installé
- Dépendances du projet installées (`flutter pub get`)

### Exécution

#### Test simple (recommandé pour commencer)
```bash
dart test_ademe_simple.dart
```

#### Test complet
```bash
dart test_ademe_api.dart
```

### Exécution avec Flutter
```bash
flutter run test_ademe_simple.dart
# ou
flutter run test_ademe_api.dart
```

## Paramètres de test

### Coordonnées par défaut
- **Latitude**: 48.8566 (Paris)
- **Longitude**: 2.3522 (Paris)
- **Rayon**: 1000 mètres
- **Bbox**: Zone autour de Paris

### Filtres par défaut
- **Grades DPE**: F, G (logements énergivores)
- **Surface**: 50-200 m²
- **Période**: 3 derniers mois

## Résultats attendus

### Test simple
- Récupération de données DPE pour Paris
- Affichage du nombre de résultats
- Affichage des premiers résultats avec détails

### Test complet
- Tests de différentes configurations
- Vérification de la gestion d'erreurs
- Test du respect des limites de taux (10 appels/seconde)
- Statistiques détaillées

## Gestion des erreurs

Le programme teste plusieurs scénarios d'erreur :
- Coordonnées invalides
- Paramètres de surface invalides
- Gestion des exceptions réseau

## Limites de l'API

L'API ADEME a les limites suivantes :
- **10 appels par seconde par IP**
- **100 résultats maximum par requête**
- **Rate limiting automatique** implémenté dans le service

## Personnalisation

Vous pouvez modifier les paramètres de test dans les fichiers :
- Coordonnées de test
- Filtres de surface
- Grades DPE
- Périodes de recherche

## Dépannage

### Erreurs communes
1. **Erreur de connexion**: Vérifiez votre connexion internet
2. **Erreur de parsing**: Vérifiez que les modèles sont à jour
3. **Limite de taux**: Attendez avant de relancer les tests

### Logs détaillés
Le programme affiche des logs détaillés pour le débogage :
- URL des requêtes
- Temps d'exécution
- Nombre de résultats
- Détails des erreurs
