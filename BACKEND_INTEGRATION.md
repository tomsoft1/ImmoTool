# Backend API Integration

This document describes the backend API integration changes made to the Flutter client.

## Overview

The Flutter client has been updated to use a centralized backend API instead of making direct calls to public APIs (ADEME, DVF, etc.). This provides:

- **Centralized caching**: Backend handles MongoDB-based caching with 30-day TTL
- **Rate limiting**: Backend manages rate limits for external APIs
- **Simplified client**: Single API interface instead of multiple service classes
- **Better error handling**: Graceful fallback to direct APIs if backend is unavailable
- **Consistent data format**: Backend normalizes responses across different data sources

## Changes Made

### 1. New Backend API Service

**File**: `lib/services/backend_api_service.dart`

A new service class that communicates with the Node.js/Express backend:

```dart
final backendService = BackendApiService();

// Fetch DPE records by map bounds
final dpeRecords = await backendService.getDpeRecords(
  north: 48.9,
  south: 48.8,
  east: 2.4,
  west: 2.3,
);

// Fetch DVF transactions by map bounds
final dvfTransactions = await backendService.getDvfTransactions(
  north: 48.9,
  south: 48.8,
  east: 2.4,
  west: 2.3,
);
```

**Features**:
- Rate limiting: 500ms between requests
- 30-second timeout for backend calls
- Automatic data transformation to existing models (`DpeData`, `ImmoDataDvf`)
- Health check endpoint: `checkHealth()`

### 2. Updated API Configuration

**File**: `lib/config/api_config.dart`

Added backend endpoint configuration:

```dart
class ApiConfig {
  static const String backendBaseUrl = 'http://localhost:3000/api';

  static String get dvfTransactionsEndpoint => '$backendBaseUrl/dvf/transactions';
  static String get dpeRecordsEndpoint => '$backendBaseUrl/dpe/records';
  static String get geocodingEndpoint => '$backendBaseUrl/geocoding/search';
  static String get healthEndpoint => '$backendBaseUrl/health';
}
```

### 3. Updated Property Map Screen

**File**: `lib/screens/property_map_screen.dart`

Modified data loading methods to use the backend API:

**Before**:
```dart
final dpeDataList = await _dpeService.getDpeDataV1(
  lat: _center.latitude,
  lng: _center.longitude,
  bbox: bbox,
  settings: settings,
);
```

**After**:
```dart
final bounds = _mapController.camera.visibleBounds;
final dpeDataList = await _backendService.getDpeRecords(
  north: bounds.north,
  south: bounds.south,
  east: bounds.east,
  west: bounds.west,
);
```

**Fallback Mechanism**: If the backend is unavailable, the app automatically falls back to direct API calls to ensure continued functionality.

## Backend API Endpoints

### DPE Records
```
GET /api/dpe/records?north={N}&south={S}&east={E}&west={W}
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "DPE123456",
      "address": "55 Rue Traversière 75012 Paris",
      "lat": 48.8456,
      "lon": 2.3789,
      "energyClass": "D",
      "ghgClass": "D",
      "energyConsumption": 285,
      "surfaceThermiqueLot": 65.0,
      "dateEtablissementDpe": "2023-06-15T00:00:00Z"
    }
  ],
  "meta": {
    "count": 12,
    "bounds": { "north": 48.9, "south": 48.8, "east": 2.4, "west": 2.3 }
  }
}
```

### DVF Transactions
```
GET /api/dvf/transactions?north={N}&south={S}&east={E}&west={W}
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "transaction_id",
      "date": "2023-01-15T00:00:00Z",
      "price": 250000,
      "propertyType": "Appartement",
      "surface": 65,
      "rooms": 3,
      "address": "15 Rue de la République, 75001 Paris",
      "lat": 48.8566,
      "lon": 2.3522,
      "postalCode": "75001",
      "commune": "Paris",
      "communeCode": "75056"
    }
  ],
  "meta": {
    "count": 45,
    "bounds": { "north": 48.9, "south": 48.8, "east": 2.4, "west": 2.3 }
  }
}
```

## Setup Instructions

### 1. Backend Setup

The backend must be running before starting the Flutter app:

```bash
cd /Users/tomsoft/Documents/OtherProjects/ImmoTool_All/backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env to configure MongoDB and API URLs

# Start backend server
npm start
```

The backend will start on `http://localhost:3000`.

### 2. Flutter Configuration

Update the backend URL in `lib/config/api_config.dart` if needed:

```dart
static const String backendBaseUrl = 'http://localhost:3000/api';
```

For production, you'll want to use an environment variable:

```dart
static const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000/api',
);
```

Then run with:
```bash
flutter run --dart-define=BACKEND_URL=https://your-backend.com/api
```

### 3. Running the App

```bash
# Ensure backend is running first
cd /Users/tomsoft/Documents/OtherProjects/ImmoTool_All/backend
npm start

# In a new terminal, run the Flutter app
cd /Users/tomsoft/Documents/OtherProjects/ImmoTool_All/Flutter_Client
flutter run
```

## Testing

### Backend Health Check

The app can check if the backend is available:

```dart
final isHealthy = await BackendApiService().checkHealth();
if (!isHealthy) {
  print('Backend is not available, using fallback APIs');
}
```

### Fallback Behavior

If the backend is unavailable:
1. App logs error to console
2. Automatically falls back to direct API calls
3. User experience is maintained
4. Console shows: `"Attempting fallback to direct ADEME API..."`

## Benefits

1. **Reduced API calls**: Backend caches data in MongoDB for 30 days
2. **Better rate limiting**: Centralized rate limit management
3. **Simpler client code**: Single service interface
4. **Improved reliability**: Fallback mechanism ensures app works even if backend is down
5. **Future-proof**: Easy to add new data sources without client changes

## Migration Notes

### Old Service Classes (Still Available)

The old service classes are still in the codebase for fallback:
- `lib/services/ademe_api_service.dart` - Direct ADEME API calls
- `lib/services/dvf_api_service.dart` - Direct DVF API calls
- `lib/services/geo_api_service.dart` - Geographic boundaries

These are used as fallback when the backend is unavailable.

### Removing Fallback (Optional)

To force backend-only mode (no fallback), remove the `catch` fallback blocks in `property_map_screen.dart`:

```dart
// Remove these fallback sections:
catch (fallbackError) {
  debugPrint('Fallback also failed: $fallbackError');
}
```

## Troubleshooting

### Backend Connection Failed

**Error**: `Error fetching DPE records from backend: Connection refused`

**Solution**: Ensure the backend is running on `http://localhost:3000`

### CORS Issues (Web Platform)

**Error**: `CORS policy: No 'Access-Control-Allow-Origin' header`

**Solution**: Backend CORS is configured for `http://localhost:5173` (Vite default). Update in backend `src/config/index.ts`:

```typescript
corsOrigins: process.env.CORS_ORIGINS?.split(',') || [
  'http://localhost:5173',
  'http://localhost:8080', // Add Flutter web port if different
]
```

### Empty Results

**Error**: Backend returns `success: true` but empty `data` array

**Possible causes**:
1. No data in MongoDB cache for the requested bounds
2. Backend can't reach external APIs (ADEME, DVF)
3. Coordinates out of France (no DVF/DPE data available)

**Solution**: Check backend logs for external API errors

## Architecture Comparison

### Before (Direct API Calls)
```
Flutter App
├── ADEME API Service → data.ademe.fr
├── DVF API Service → dvf-api.data.gouv.fr
└── Geo API Service → geo.api.gouv.fr
```

### After (Backend Integration)
```
Flutter App
└── Backend API Service → localhost:3000
    ├── DPE Controller → MongoDB Cache → ADEME API
    ├── DVF Controller → MongoDB Cache → DVF API
    └── Geo Controller → Geocoding Service
```

## Next Steps

1. **Environment Configuration**: Use environment variables for backend URL
2. **Error Handling UI**: Show user-friendly messages when backend is down
3. **Offline Mode**: Implement local SQLite cache for offline functionality
4. **Authentication**: Add API key or JWT authentication if deploying publicly
5. **Remove Fallback**: Once backend is stable, remove direct API fallback code

## Related Files

- `lib/services/backend_api_service.dart` - New backend service
- `lib/config/api_config.dart` - Updated configuration
- `lib/screens/property_map_screen.dart` - Updated to use backend
- `lib/models/dpe_data.dart` - DPE data model
- `lib/models/immo_data_dvf.dart` - DVF transaction model
