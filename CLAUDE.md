# AudioCity - Contexto para Claude Code

## Resumen del Proyecto

Plataforma de turismo con audioguías geolocalizadas. El usuario compra una ruta, se pone los auriculares y camina. Cuando llega a puntos de interés, automáticamente se reproduce la narración del guía turístico.

## Stack Tecnológico

### iOS (POC actual)
- **UI:** SwiftUI
- **Arquitectura:** MVVM + Combine
- **Backend:** Firebase Firestore
- **Geolocalización:** CoreLocation (híbrido: geofences nativos 100m + location updates 5m)
- **Audio:** AVFoundation (Text-to-Speech con cola de reproducción)
- **Mapas:** MapKit

### Android (planificado)
- Jetpack Compose + MVVM + Flow
- Firebase + Google Location Services + Google Maps SDK

## Estructura del Proyecto

```
AudioCityPOC/
├── Models/          # Route.swift, Stop.swift
├── Services/        # LocationService, GeofenceService, AudioService, FirebaseService
├── ViewModels/      # RouteViewModel, ExploreViewModel
├── Views/           # SplashView, MainTabView, RoutesListView, MapView, etc.
└── Assets.xcassets/ # AppLogo_transp, LaunchBackground
```

## Rutas en Firebase

| ID | Nombre | Ciudad | Paradas |
|----|--------|--------|---------|
| arganzuela-poc-001 | Descubre Arganzuela | Madrid | 6 |
| letras-poc-001 | Barrio de las Letras | Madrid | 5 |
| canal-poc-001 | Canal y Chamberí | Madrid | 5 |
| valladolid-centro-001 | Valladolid Histórico | Valladolid | 15 |
| zamora-romanico-001 | Zamora Románica | Zamora | 15 |

## Credenciales y Archivos Externos

- **Firebase credentials:** `/Users/juanrafernandez/Documents/AudioCity POC/firebase-credentials.json`
- **GoogleService-Info.plist:** `/Users/juanrafernandez/Documents/AudioCity POC/GoogleService-Info.plist`
- **Scripts de importación:** `/Users/juanrafernandez/Documents/AudioCity POC/import_to_firebase.py`

## Comandos Útiles

```bash
# Subir datos a Firebase
cd "/Users/juanrafernandez/Documents/AudioCity POC"
export GOOGLE_APPLICATION_CREDENTIALS="firebase-credentials.json"
python3 import_to_firebase.py

# Build iOS
xcodebuild -project AudioCityPOC/AudioCityPOC.xcodeproj -scheme AudioCityPOC -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Conceptos Clave

### Sistema Híbrido de Geofencing
- **Geofences nativos (100m):** Despiertan la app cuando está suspendida (máx 20 en iOS)
- **Location updates (5m):** Precisión para detectar paradas mientras la app está en background

### Cola de Audio
- Las paradas detectadas se encolan ordenadas por `order`
- Reproducción secuencial automática
- Evita duplicados con `processedStopIds`

### Modelo de Datos Firebase
- Colección `routes`: Rutas con metadatos (ciudad, duración, dificultad, etc.)
- Colección `stops`: Paradas con `route_id`, `order`, coordenadas, `narration_text`

## Colores de Marca

- Brand Blue: `#3361FA` (RGB: 51, 97, 250)
- SwiftUI: `Color(red: 0.2, green: 0.38, blue: 0.98)`

## Notas para Desarrollo

- Los campos en Firebase usan snake_case (`route_id`, `trigger_radius_meters`)
- Los modelos Swift usan `CodingKeys` para mapear a camelCase
- El campo `id` debe existir explícitamente en cada documento de Firebase
- El `distanceFilter` del LocationService está configurado a 5 metros
- Background modes habilitados: `audio`, `location`
