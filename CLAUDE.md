# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ImmoTool is a Flutter multi-platform application that visualizes French real estate data on an interactive map. It displays:
- **DPE** (Diagnostic de Performance Énergétique) - Energy performance certificates
- **DVF** (Demandes de Valeurs Foncières) - Property transaction prices

The app uses French government open data APIs and implements zoom-based data loading with aggressive caching.

## Development Commands

### Running the App
```bash
flutter run                    # Debug mode
flutter run --release         # Release mode
flutter run -d macos          # Run on specific platform (macos/web/windows/linux)
```

### Code Generation
After modifying any model files in `lib/models/`, regenerate serialization code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing
```bash
flutter test                           # Run all tests
flutter test test/dvf_api_test.dart   # Run specific test file
dart test/dvf_simple_test.dart        # Run Dart-only tests
```

### Dependencies
```bash
flutter pub get               # Install dependencies
flutter pub upgrade           # Upgrade dependencies
```

### Building
```bash
flutter build apk             # Android APK
flutter build ios             # iOS build
flutter build web             # Web build
flutter build macos           # macOS app
```

## Architecture Overview

### Technology Stack
- **Framework**: Flutter (Dart 3.5.4+)
- **State Management**: Provider pattern
- **Map**: flutter_map ^6.1.0
- **HTTP**: http ^1.5.0 with custom service layer
- **Serialization**: json_serializable with code generation

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── config/api_config.dart         # API endpoints and configuration
├── models/                        # JSON-serializable data models
│   ├── dpe_data.dart             # Energy performance certificates
│   ├── immo_data_dvf.dart        # Property transaction data
│   └── parcel_data.dart          # Land parcel geometries
├── providers/
│   └── settings_provider.dart     # Global app state (filters, settings)
├── screens/
│   ├── property_map_screen.dart   # Main map UI (1073 lines - core logic)
│   └── settings_screen.dart       # Settings UI
├── services/                      # API service layer with caching
│   ├── ademe_api_service.dart    # DPE data from ADEME
│   ├── dvf_api_service.dart      # DVF transaction data
│   ├── geo_api_service.dart      # Geographic boundaries
│   └── dvf_service.dart          # Alternative DVF implementation
└── widgets/
    └── location_search_bar.dart   # Location autocomplete search
```

### Core Architectural Patterns

#### Zoom-Based Data Loading
The app implements progressive data loading based on map zoom level in `property_map_screen.dart`:
- **Zoom < 8**: Department boundaries only
- **Zoom 8-12**: Departments + commune detection (automatic based on map center)
- **Zoom > 12**: Departments + communes + parcel boundaries with transaction data

This prevents API overload and improves performance.

#### Service Layer Pattern
All API services follow a consistent pattern:
- Rate limiting (ADEME API: 10 calls/second)
- Built-in caching with 24-hour TTL
- Error handling and logging with `debugPrint`
- Asynchronous operations with proper error propagation

#### State Management
- `SettingsProvider` (ChangeNotifier): Manages DPE filters, surface area ranges, date ranges
- Provider pattern for global state access
- Local state in `PropertyMapScreen` for map-specific data

#### Data Models
All models use `json_serializable` for type-safe JSON parsing:
- Annotate with `@JsonSerializable()`
- Run `build_runner` after changes
- Generated `.g.dart` files handle serialization/deserialization

### Map Interaction Flow

1. **User moves map** → 500ms debounce + 500m distance threshold
2. **Check zoom level** → Determine what data to load
3. **Detect commune** (zoom > 8) → Use geo_api to find commune at map center
4. **Load department geometries** → Cached in memory
5. **Load parcel data** (zoom > 12) → 24-hour cache
6. **User taps parcel** → Show transaction history in bottom sheet
7. **Load DPE/DVF markers** → Based on bounding box and active filters

### API Integration

#### ADEME API (DPE Data)
- Endpoint: `data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines`
- **Rate limit**: 10 calls/second (enforced in service)
- Query parameters: bounding box, DPE grades, surface area, date range
- Returns: Energy certificates with lat/lng coordinates

#### DVF API (Transaction Data)
- Base: `app.dvf.etalab.gouv.fr/api` and `cadastre.data.gouv.fr`
- Key endpoints:
  - `/mutations3/{commune}/{parcel}` - Get transaction history
  - Cadastre API for parcel geometries
- Cache: 24-hour TTL for both parcels and transactions

#### Geo API (Geographic Boundaries)
- Base: `geo.api.gouv.fr`
- Provides: Department/commune boundaries, postal code search
- Format: GeoJSON with polygon geometries
- Cache: Department data cached in memory

### Coordinate System Gotcha
- **GeoJSON format**: `[longitude, latitude]` (x, y)
- **LatLng objects**: `LatLng(latitude, longitude)` (y, x)
- Always convert between formats when handling API responses

### Caching Strategy
The app implements aggressive caching to minimize API calls:
- Department geometries: In-memory, permanent for session
- Parcel data: 24-hour TTL
- DVF transactions: 24-hour TTL
- Commune searches: Session cache

Cache keys use combinations like `"${commune}_${parcel}"` for uniqueness.

### Testing Philosophy
The `test/` directory contains comprehensive test coverage:
- Unit tests for all services
- Integration tests for full API workflows
- Performance and stress tests
- Validation tests for data integrity
- See `test/README.md` for detailed testing documentation

Run specific test suites when modifying related code.

## Common Development Patterns

### Adding a New Data Model
1. Create model in `lib/models/` with `@JsonSerializable()` annotation
2. Add `part 'filename.g.dart';` directive
3. Implement `fromJson` and `toJson` factory constructors
4. Run: `flutter pub run build_runner build --delete-conflicting-outputs`

### Adding a New API Service
Follow the pattern in existing services:
1. Create service class in `lib/services/`
2. Implement caching with `Map<String, CachedData>` pattern
3. Add rate limiting if needed (see `ademe_api_service.dart`)
4. Use `debugPrint` for logging API responses
5. Handle errors gracefully with try-catch

### Adding a New Filter
1. Add property to `SettingsProvider`
2. Update `buildQueryParameters()` method for API queries
3. Add UI control in `settings_screen.dart`
4. Call `notifyListeners()` when filter changes
5. Map screen will auto-reload data on provider changes

### Modifying Map Behavior
The core map logic is in `property_map_screen.dart`:
- `_loadData()` - Main data loading orchestrator
- `_handleMapEvent()` - Handles map move/zoom with debouncing
- `_loadDepartments()`, `_loadCommunes()`, `_loadParcels()` - Layer-specific loading
- `_onTap()` - Handles tap detection (point-in-polygon for parcels)

## Important Technical Details

### Map Movement Debouncing
- 500ms debounce timer prevents excessive API calls
- 500m distance threshold - only reload if moved significantly
- Zoom level changes trigger immediate reload

### Point-in-Polygon Algorithm
Custom implementation for parcel tap detection (GeoJSON polygons/multi-polygons):
- Handles both simple polygons and multi-polygon features
- Ray casting algorithm for point containment
- See `_isPointInPolygon()` in `property_map_screen.dart`

### Rate Limiting Implementation
ADEME API enforces 10 calls/second:
- Implemented in `ademe_api_service.dart`
- Uses `_lastCallTime` tracking
- Adds delays between rapid calls

### Multi-Platform Considerations
- iOS: Location permissions configured in Info.plist
- Android: Min SDK 21, location permissions in manifest
- Web: Uses OpenStreetMap tiles, CORS handled
- Desktop: Full support for Windows, Linux, macOS

## Git Workflow
- **Main branch**: `main`
- Use feature branches for new work (e.g., `feat/other_dvf_api`)
- Commit messages should be descriptive

## Project Context
This project was created as an experiment in AI-assisted development, primarily using AI tools to generate code. The codebase demonstrates clean architecture, comprehensive testing, and production-ready patterns.
