# Immo Tools - Flutter Client

Application Flutter pour visualiser les informations immobilières en utilisant des données open source françaises.

## 📋 Description

Immo Tools est une application mobile développée en Flutter qui permet de visualiser sur une carte interactive les informations immobilières publiques françaises, notamment :
- **DPE** (Diagnostic de Performance Énergétique) - données ADEME
- **DVF** (Demandes de Valeurs Foncières) - données Etalab
- **Données géographiques** : départements, communes, parcelles cadastrales

L'application utilise principalement l'IA pour le développement et l'amélioration continue.

## ✨ Fonctionnalités

### 🗺️ Carte Interactive
- Visualisation sur carte OpenStreetMap
- Géolocalisation automatique
- Navigation fluide avec zoom adaptatif
- Affichage des frontières administratives (départements, communes)
- Visualisation des parcelles cadastrales

### 📊 Données DPE (Diagnostic de Performance Énergétique)
- Affichage des diagnostics énergétiques sur la carte
- Filtrage par classe énergétique (A à G)
- Informations détaillées : consommation énergétique, surface, adresse, date
- Couleurs codées selon la performance énergétique

### 💰 Données DVF (Demandes de Valeurs Foncières)
- Historique des transactions immobilières
- Prix de vente, type de bien, surface, nombre de pièces
- Visualisation par parcelle avec marqueurs
- Filtres par date, prix, surface

### 🔍 Recherche
- Recherche de communes par nom
- Navigation rapide vers une localisation
- Détection automatique de la commune selon la position

### ⚙️ Paramètres
- Configuration des filtres DPE
- Sélection des couches de données à afficher (DPE, DVF, ou les deux)
- Activation/désactivation de l'affichage des parcelles

## 🚀 Installation

### Prérequis
- Flutter SDK (version 3.5.4 ou supérieure)
- Dart SDK
- Android Studio / Xcode (pour le développement mobile)
- Git

### Étapes d'installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd Flutter_Client
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Générer les fichiers de sérialisation JSON** (si nécessaire)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Lancer l'application**
   ```bash
   flutter run
   ```

## 📱 Utilisation

### Démarrage
1. L'application démarre avec votre position actuelle (si autorisée)
2. Par défaut, les données DPE et DVF sont affichées simultanément

### Navigation
- **Zoom** : Utilisez les boutons +/- ou pincez pour zoomer
- **Déplacement** : Glissez sur la carte pour explorer
- **Géolocalisation** : Appuyez sur le bouton de localisation pour revenir à votre position

### Affichage des données
- **Marqueurs DPE** : Cercles colorés avec la lettre de la classe énergétique
- **Marqueurs DVF** : Cercles bleus avec l'icône €
- **Parcelles** : Polygones bleus avec bordures

### Interaction
- **Cliquer sur un marqueur DPE** : Affiche les détails du diagnostic
- **Cliquer sur un marqueur DVF** : Affiche les détails de la transaction
- **Cliquer sur une parcelle** : Affiche l'historique des transactions pour cette parcelle

### Recherche
1. Cliquez sur l'icône de recherche dans la barre d'outils
2. Tapez le nom d'une commune
3. Sélectionnez la commune dans les résultats
4. La carte se centre automatiquement sur la commune sélectionnée

### Paramètres
1. Cliquez sur l'icône de paramètres
2. Configurez les filtres DPE selon vos besoins
3. Les modifications sont appliquées automatiquement

## 🔌 Sources de données

### API DPE (ADEME)
- **URL** : `https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines`
- **Documentation** : [data.ademe.fr](https://data.ademe.fr)
- **Limite** : 10 appels par seconde par IP
- **Données** : Diagnostics de performance énergétique des logements existants

### API DVF (Etalab)
- **URL** : `https://app.dvf.etalab.gouv.fr/api`
- **Documentation** : [etalab.gouv.fr](https://www.etalab.gouv.fr)
- **Données** : Demandes de valeurs foncières (transactions immobilières)

### API Géographique
- **Geo API Gouv** : `https://geo.api.gouv.fr`
- **Cadastre** : `https://cadastre.data.gouv.fr`
- **Données** : Départements, communes, parcelles cadastrales

## 🏗️ Architecture

### État actuel
L'application Flutter communique directement avec les APIs tierces (ADEME, Etalab, Geo API Gouv) depuis le client.

### Évolutions prévues
Un backend est prévu pour faire office de proxy entre l'application Flutter et les APIs tierces. Cette architecture permettra de :
- **Optimiser les performances** : Mise en cache centralisée côté serveur
- **Réduire la charge** : Agrégation et pré-traitement des données
- **Améliorer la sécurité** : Gestion centralisée des clés API et des limites de taux
- **Simplifier le client** : Logique métier déplacée côté serveur
- **Meilleure scalabilité** : Gestion des appels API optimisée pour plusieurs clients

## 📁 Structure du projet

```
lib/
├── config/           # Configuration de l'application
│   └── api_config.dart
├── models/           # Modèles de données
│   ├── dpe_data.dart
│   ├── immo_data_dvf.dart
│   └── parcel_data.dart
├── providers/        # Gestion d'état (Provider)
│   └── settings_provider.dart
├── screens/          # Écrans de l'application
│   ├── property_map_screen.dart
│   └── settings_screen.dart
├── services/         # Services API
│   ├── ademe_api_service.dart
│   ├── dvf_api_service.dart
│   ├── geo_api_service.dart
│   └── real_estate_data_service.dart
├── widgets/          # Widgets réutilisables
│   └── location_search_bar.dart
└── main.dart         # Point d'entrée de l'application

test/                 # Tests
├── dvf_api_test.dart
├── dvf_simple_test.dart
└── ...
```

## 📦 Dépendances principales

- `flutter_map` : Carte interactive
- `latlong2` : Gestion des coordonnées géographiques
- `geolocator` : Géolocalisation
- `geocoding` : Géocodage
- `provider` : Gestion d'état
- `http` : Requêtes HTTP
- `json_annotation` / `json_serializable` : Sérialisation JSON

Voir `pubspec.yaml` pour la liste complète des dépendances.

## 🧪 Tests

Le projet inclut une suite complète de tests pour l'API DVF :

```bash
# Exécuter tous les tests
flutter test

# Tests spécifiques
flutter test test/dvf_api_test.dart
dart test/dvf_simple_test.dart
```

Voir `test/README_TESTS_DVF.md` pour plus de détails sur les tests.

## 🛠️ Développement

### Génération de code
Pour régénérer les fichiers de sérialisation JSON :
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Mode debug
```bash
flutter run --debug
```

### Build de production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📝 Notes

- L'application respecte les limites de taux des APIs publiques
- Les données sont mises en cache pour améliorer les performances
- La géolocalisation nécessite les permissions appropriées
- Les données sont mises à jour selon la disponibilité des APIs publiques

## 🔗 Liens utiles

- [Etalab](https://www.etalab.gouv.fr) - Données publiques françaises
- [ADEME](https://data.ademe.fr) - Données environnementales
- [Geo API Gouv](https://geo.api.gouv.fr) - API géographique française
- [Flutter Documentation](https://flutter.dev/docs)

## 📄 Licence

Voir le fichier `LICENSE` pour plus d'informations.

---

*Application développée avec Flutter et des données open source françaises.*
