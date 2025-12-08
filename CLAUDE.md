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
- **Persistencia local:** UserDefaults (viajes, favoritos, caché, puntos, historial)

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
│   ├── CachedRoute.swift    # Ruta guardada para offline
│   ├── UserRoute.swift      # Ruta creada por usuario (UGC)
│   ├── RouteHistory.swift   # Historial de rutas completadas
│   └── Points.swift         # Sistema de puntos y niveles
├── Services/
│   ├── LocationService.swift    # Geolocalización + geofences nativos
│   ├── GeofenceService.swift    # Detección de paradas por proximidad
│   ├── AudioService.swift       # TTS con cola de reproducción
│   ├── FirebaseService.swift    # Conexión a Firestore
│   ├── TripService.swift        # CRUD de viajes del usuario
│   ├── FavoritesService.swift   # Gestión de rutas favoritas
│   ├── OfflineCacheService.swift # Descarga y caché offline
│   ├── NotificationService.swift # Notificaciones locales al llegar a paradas
│   ├── UserRoutesService.swift  # CRUD de rutas creadas por usuario
│   ├── HistoryService.swift     # Historial de rutas completadas
│   └── PointsService.swift      # Sistema de gamificación
├── ViewModels/
│   ├── RouteViewModel.swift     # Orquesta servicios para rutas
│   └── ExploreViewModel.swift   # Mapa de exploración
├── Views/
│   ├── SplashView.swift
│   ├── MainTabView.swift        # 5 tabs: Explorar, Rutas, Mis Rutas, Historial, Perfil
│   ├── RoutesListView.swift     # Pantalla principal de rutas (secciones)
│   ├── AllRoutesView.swift      # Buscador con filtros
│   ├── AllTripsView.swift       # Lista completa de viajes (pasados/futuros)
│   ├── TripOnboardingView.swift # Wizard planificar viaje (4 pasos)
│   ├── TripDetailView.swift     # Detalle de viaje (ver/editar rutas)
│   ├── MapExploreView.swift     # Mapa con todas las paradas
│   ├── MapView.swift            # Mapa de ruta activa
│   ├── RouteDetailView.swift
│   ├── MyRoutesView.swift       # Rutas creadas por usuario (UGC)
│   ├── HistoryView.swift        # Historial de rutas completadas
│   └── ProfileView.swift        # Perfil con puntos y nivel
└── Assets.xcassets/
```

## Navegación por Tabs (MainTabView)

```
Tab 1: Explorar     → MapExploreView (mapa con paradas)
Tab 2: Rutas        → RoutesListView (catálogo de rutas)
Tab 3: Mis Rutas    → MyRoutesView (rutas creadas por usuario)
Tab 4: Historial    → HistoryView (rutas completadas)
Tab 5: Perfil       → ProfileView (puntos, nivel, configuración)
```

## Sistema de Gamificación (Puntos y Niveles)

### Acciones que otorgan puntos

| Acción | Puntos | Descripción |
|--------|--------|-------------|
| Crear ruta (3-4 paradas) | 50 | Ruta pequeña |
| Crear ruta (5-9 paradas) | 100 | Ruta mediana |
| Crear ruta (10+ paradas) | 200 | Ruta extensa |
| Completar ruta 100% | 30 | Visitar todas las paradas |
| Primera ruta del día | 10 | Bonus diario |
| Racha de 3 días | 50 | Completar rutas 3 días seguidos |
| Racha de 7 días | 100 | Completar rutas 7 días seguidos |
| Publicar ruta | 20 | Compartir con la comunidad |
| Tu ruta usada por otros | 5 | Cada vez que alguien completa tu ruta |

### Niveles de Usuario

| Nivel | Puntos | Nombre | Icono |
|-------|--------|--------|-------|
| 1 | 0-99 | Explorador | figure.walk |
| 2 | 100-299 | Viajero | airplane |
| 3 | 300-599 | Guía Local | map |
| 4 | 600-999 | Experto | star.fill |
| 5 | 1000+ | Maestro AudioCity | crown.fill |

### PointsService (Singleton)
```swift
PointsService.shared.awardPointsForCreatingRoute(routeId:routeName:stopsCount:)
PointsService.shared.awardPointsForCompletingRoute(routeId:routeName:)
PointsService.shared.awardPointsForPublishingRoute(routeId:routeName:)
PointsService.shared.stats  // UserPointsStats con nivel y progreso
```

## Creación de Rutas por Usuario (UGC)

### MyRoutesView
- Lista de rutas creadas por el usuario
- Estado vacío con botón para crear primera ruta
- Indicador de estado: "Publicada" (verde) / "Borrador" (naranja)
- Swipe para eliminar

### CreateRouteView
- Formulario: nombre, ciudad, barrio (opcional), descripción
- Al crear, la ruta empieza sin paradas

### EditRouteView
- Editar información básica
- Gestionar paradas (añadir, eliminar, reordenar)
- Toggle para publicar/despublicar
- Eliminar ruta

### AddStopView
- Nombre, descripción, coordenadas (lat/lon)
- Narración (script que se reproducirá)

### UserRoutesService (Singleton)
```swift
UserRoutesService.shared.createRoute(name:city:description:neighborhood:)
UserRoutesService.shared.addStop(to:stop:)  // Otorga puntos al alcanzar 3/5/10 paradas
UserRoutesService.shared.togglePublish(_:)  // Otorga puntos al publicar
```

## Historial de Rutas (HistoryView)

- Rutas completadas agrupadas por fecha
- Estadísticas: rutas totales, distancia recorrida, tiempo total, % completado
- Cada registro muestra: progreso circular, nombre, ciudad, hora, duración
- Opción para borrar historial

### HistoryService (Singleton)
```swift
HistoryService.shared.startRoute(routeId:routeName:routeCity:totalStops:)
HistoryService.shared.updateProgress(historyId:stopsVisited:distanceWalkedKm:)
HistoryService.shared.completeRoute(historyId:)  // Otorga puntos automáticamente
```

## Arquitectura de Pantalla de Rutas (RoutesListView)

```
RoutesListView
├── 🧳 Mis Viajes (máx 2 próximos + "Ver todos")
│   ├── [Viajes existentes] → TripCard → TripDetailView
│   ├── [+ Planificar] → TripOnboardingView
│   └── [Ver todos] → AllTripsView
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

    var isPast: Bool          // Viaje pasado
    var isCurrent: Bool       // Viaje en curso
    var isFuture: Bool        // Viaje futuro
}
```

### UserRoute (ruta creada por usuario)
```swift
struct UserRoute {
    let id: String
    var name: String
    var description: String
    var city: String
    var neighborhood: String
    var stops: [UserStop]
    var isPublished: Bool
    var totalDistanceKm: Double
    var estimatedDurationMinutes: Int
}
```

### RouteHistory (historial)
```swift
struct RouteHistory {
    let routeId: String
    let routeName: String
    let startedAt: Date
    var completedAt: Date?
    var stopsVisited: Int
    var totalStops: Int
    var completionPercentage: Int  // 0-100
}
```

### UserPointsStats (puntos)
```swift
struct UserPointsStats {
    var totalPoints: Int
    var currentLevel: UserLevel
    var routesCreated: Int
    var routesCompleted: Int
    var currentStreak: Int
    var progressToNextLevel: Double  // 0.0-1.0
}
```

## Servicios Clave

### TripService (Singleton)
- `TripService.shared` - Instancia compartida
- `createTrip()` - Crear viaje (valida duplicados)
- `addRoute(routeId, tripId)` - Añadir ruta a viaje
- `removeRoute(routeId, tripId)` - Quitar ruta de viaje
- `deleteTrip()` - Eliminar viaje
- `loadAvailableDestinations()` - Cargar ciudades desde Firebase
- `activeRouteIds` - IDs de rutas en viajes activos (para pins rosas en mapa)
- `tripExists(city, dates)` - Validar duplicados
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
xcodebuild -project AudioCityPOC/AudioCityPOC.xcodeproj -scheme AudioCityPOC -destination 'platform=iOS Simulator,name=iPhone 17' build
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
- **Pins en mapa:** Naranja (normal), Rosa (rutas de viaje activo), Azul (seleccionado)

## Colores de Marca

- Brand Blue: `#3361FA` (RGB: 51, 97, 250)
- SwiftUI: `Color(red: 0.2, green: 0.38, blue: 0.98)`
- Favoritos: Rojo (heart.fill)
- Trips: Púrpura / Rosa
- Top: Amarillo (star)
- Trending: Naranja (flame)
- Puntos: Amarillo (star.fill)
- Niveles: Gris → Azul → Verde → Púrpura → Naranja

## Notas para Desarrollo

- Los campos en Firebase usan snake_case (`route_id`, `trigger_radius_meters`)
- Los modelos Swift usan `CodingKeys` para mapear a camelCase
- El campo `id` debe existir explícitamente en cada documento de Firebase
- El `distanceFilter` del LocationService está configurado a 5 metros
- Background modes habilitados: `audio`, `location`
- Las secciones Top/Trending excluyen rutas ya mostradas en Favoritos
- Los puntos se otorgan automáticamente al completar acciones (no requiere llamada manual)

## Próximos Pasos Sugeridos

1. **Descarga real de tiles de mapa** - Implementar MKTileOverlay para mapas offline
2. **Audio pregrabado** - Opción de audio profesional vs TTS
3. **Badges/logros** - Medallas especiales por ciudades/rutas completadas
4. **Integración calendario** - Sugerir rutas según duración del viaje
5. **Trending real** - Reemplazar rutas mock por lógica de popularidad
6. **Sincronización Firebase** - Subir rutas de usuario y puntos a la nube
7. **Ranking de usuarios** - Leaderboard por puntos/nivel
