# AudioCity - Contexto para Claude Code

## Resumen del Proyecto

Plataforma de turismo con audioguías geolocalizadas estilo **Wikiloc**. El usuario planifica viajes, selecciona rutas de un destino, las descarga para uso offline, y cuando camina por la ciudad, automáticamente se reproduce la narración al llegar a puntos de interés.

## Stack Tecnológico

### iOS (POC actual)
- **UI:** SwiftUI
- **Arquitectura:** MVVM + Combine
- **Backend:** Firebase Firestore
- **Geolocalización:** CoreLocation (híbrido: geofences nativos 100m + location updates 5m)
- **Audio:** AVFoundation (Text-to-Speech con cola de reproducción)
- **Mapas:** MapKit
- **Persistencia local:** UserDefaults (viajes, favoritos, caché)

### Android (planificado)
- Jetpack Compose + MVVM + Flow
- Firebase + Google Location Services + Google Maps SDK
- SharedPreferences/Room para persistencia

## Estructura del Proyecto

```
AudioCityPOC/
├── Models/
│   ├── Route.swift          # Ruta con metadatos
│   ├── Stop.swift           # Parada con script de audio
│   ├── Trip.swift           # Viaje planificado por usuario
│   └── CachedRoute.swift    # Ruta guardada para offline
├── Services/
│   ├── LocationService.swift    # Geolocalización + geofences nativos
│   ├── GeofenceService.swift    # Detección de paradas por proximidad
│   ├── AudioService.swift       # TTS con cola de reproducción
│   ├── FirebaseService.swift    # Conexión a Firestore
│   ├── TripService.swift        # CRUD de viajes del usuario
│   ├── FavoritesService.swift   # Gestión de rutas favoritas
│   └── OfflineCacheService.swift # Descarga y caché offline
├── ViewModels/
│   ├── RouteViewModel.swift     # Orquesta servicios para rutas
│   └── ExploreViewModel.swift   # Mapa de exploración
├── Views/
│   ├── SplashView.swift
│   ├── MainTabView.swift
│   ├── RoutesListView.swift     # Pantalla principal de rutas (secciones)
│   ├── AllRoutesView.swift      # Buscador con filtros
│   ├── TripOnboardingView.swift # Wizard planificar viaje (4 pasos)
│   ├── MapExploreView.swift     # Mapa con todas las paradas
│   ├── MapView.swift            # Mapa de ruta activa
│   ├── RouteDetailView.swift
│   └── ProfileView.swift
└── Assets.xcassets/
```

## Arquitectura de Pantalla de Rutas (RoutesListView)

```
RoutesListView
├── Header ("Descubre tu ciudad")
├── 🧳 Mis Viajes
│   ├── [Viajes existentes] → TripCard
│   └── [+ Planificar] → TripOnboardingView
├── ❤️ Rutas Favoritas (scroll horizontal, si hay)
├── ⭐ Top Rutas (scroll horizontal) - ordenadas por nº paradas
├── 🔥 Rutas de Moda (scroll horizontal) - actualmente mockeadas
└── 🗺️ [Todas las Rutas] → AllRoutesView (buscador + filtros)
```

### Rutas de Moda (Mock)
Rutas temporales hardcodeadas para visualizar la UI:
- **Ruta de la Tapa por Lavapiés** - gastronomía, 90min, 8 paradas
- **Ruta de Navidad** - luces y mercadillos, 120min, 10 paradas
- **Ruta Black Friday** - compras, 150min, 12 paradas

> TODO: Reemplazar por lógica real de trending (popularidad, recientes, etc.)

## Flujo de Planificación de Viaje (TripOnboardingView)

```
Paso 1: Destino     → Seleccionar ciudad (Madrid, Valladolid, Zamora...)
Paso 2: Rutas       → Seleccionar múltiples rutas del destino
Paso 3: Opciones    → Fechas (opcional) + descarga offline
Paso 4: Resumen     → Confirmar y crear viaje
```

## Modelos de Datos Principales

### Trip (viaje del usuario)
```swift
struct Trip {
    let id: String
    let destinationCity: String
    let destinationCountry: String
    var selectedRouteIds: [String]
    let createdAt: Date
    var startDate: Date?      // opcional
    var endDate: Date?        // opcional
    var isOfflineAvailable: Bool
    var lastSyncDate: Date?
}
```

### CachedRoute (caché offline)
```swift
struct CachedRoute {
    let id: String
    let tripId: String
    let route: Route
    let stops: [Stop]
    let cachedAt: Date
    var mapTilesPath: String?
    var totalSizeBytes: Int64
}
```

## Servicios Clave

### TripService
- `createTrip()` - Crear viaje
- `addRoute(routeId, tripId)` - Añadir ruta a viaje
- `deleteTrip()` - Eliminar viaje
- `loadAvailableDestinations()` - Cargar ciudades desde Firebase
- Persistencia en UserDefaults

### FavoritesService
- `toggleFavorite(routeId)` - Toggle favorito
- `isFavorite(routeId)` - Verificar si es favorito
- `filterFavorites(routes)` - Filtrar rutas favoritas
- Persistencia en UserDefaults

### OfflineCacheService
- `downloadTrip(trip, routes, stops)` - Descargar viaje completo
- `isRouteCached(routeId)` - Verificar caché
- `deleteCache(trip)` - Eliminar caché de viaje
- `formattedCacheSize()` - Tamaño de caché formateado

## AllRoutesView - Buscador

- **Búsqueda:** nombre, descripción, ciudad, barrio
- **Filtros:** dificultad (Fácil/Media/Difícil), ciudad
- **Ordenación:** nombre, duración, distancia, nº paradas
- **Favoritos:** botón de corazón en cada card

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
- Colección `stops`: Paradas con `route_id`, `order`, coordenadas, `script_es`, `fun_fact`, `category`

## Configuración de UI

- **Orientación:** Solo Portrait (iPhone y iPad)
- **Mapa:** Se centra en ubicación del usuario al abrir

## Colores de Marca

- Brand Blue: `#3361FA` (RGB: 51, 97, 250)
- SwiftUI: `Color(red: 0.2, green: 0.38, blue: 0.98)`
- Favoritos: Rojo (heart.fill)
- Trips: Púrpura
- Top: Amarillo (star)
- Trending: Naranja (flame)

## Notas para Desarrollo

- Los campos en Firebase usan snake_case (`route_id`, `trigger_radius_meters`)
- Los modelos Swift usan `CodingKeys` para mapear a camelCase
- El campo `id` debe existir explícitamente en cada documento de Firebase
- El `distanceFilter` del LocationService está configurado a 5 metros
- Background modes habilitados: `audio`, `location`
- Las secciones Top/Trending excluyen rutas ya mostradas en Favoritos

## Próximos Pasos Sugeridos

1. **Detalle de viaje** - Vista para ver/editar rutas de un viaje existente
2. **Creación de rutas por usuario** - Permitir que usuarios creen sus propias rutas (UGC)
3. **Descarga real de tiles de mapa** - Implementar MKTileOverlay para mapas offline
4. **Audio pregrabado** - Opción de audio profesional vs TTS
5. **Gamificación** - Badges por ciudades/rutas completadas
6. **Integración calendario** - Sugerir rutas según duración del viaje
