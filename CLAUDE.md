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
- **Live Activities:** ActivityKit para Dynamic Island

### Android (planificado)
- Jetpack Compose + MVVM + Flow
- Firebase + Google Location Services + Google Maps SDK
- SharedPreferences/Room para persistencia
- **Deberá implementar:** Notificaciones persistentes para ruta activa (equivalente a Live Activities)

## Estructura del Proyecto

```
AudioCityPOC/
├── Models/
│   ├── Route.swift              # Ruta con metadatos y thumbnailUrl
│   ├── Stop.swift               # Parada con script de audio
│   ├── Trip.swift               # Viaje planificado por usuario
│   ├── CachedRoute.swift        # Ruta guardada para offline
│   ├── UserRoute.swift          # Ruta creada por usuario (UGC)
│   ├── RouteHistory.swift       # Historial de rutas completadas
│   ├── Points.swift             # Sistema de puntos y niveles
│   └── RouteActivityAttributes.swift  # Atributos para Live Activity
├── Services/
│   ├── LocationService.swift    # Geolocalización + geofences nativos
│   ├── GeofenceService.swift    # Detección de paradas por proximidad
│   ├── AudioService.swift       # TTS con cola de reproducción
│   ├── AudioPreviewService.swift # Preview de audio en cards
│   ├── FirebaseService.swift    # Conexión a Firestore
│   ├── TripService.swift        # CRUD de viajes del usuario
│   ├── FavoritesService.swift   # Gestión de rutas favoritas
│   ├── OfflineCacheService.swift # Descarga y caché offline
│   ├── NotificationService.swift # Notificaciones locales al llegar a paradas
│   ├── UserRoutesService.swift  # CRUD de rutas creadas por usuario
│   ├── HistoryService.swift     # Historial de rutas completadas
│   ├── PointsService.swift      # Sistema de gamificación
│   ├── ImageCacheService.swift  # Caché de imágenes en memoria y disco
│   ├── RouteCalculationService.swift  # Cálculo de rutas caminando
│   └── RouteOptimizationService.swift # Optimización de orden de paradas
├── LiveActivity/
│   └── LiveActivityService.swift # Gestión de Dynamic Island
├── ViewModels/
│   ├── RouteViewModel.swift     # Orquesta servicios para rutas
│   └── ExploreViewModel.swift   # Mapa de exploración (Singleton)
├── Views/
│   ├── SplashView.swift
│   ├── MainTabView.swift        # 5 tabs con orden: Rutas, Viajes, Explorar, Crear, Perfil
│   ├── RoutesListView.swift     # Catálogo de rutas con filtro por ciudad
│   ├── ViajesView.swift         # Planificación de viajes
│   ├── AllTripsView.swift       # Lista completa de viajes (pasados/futuros)
│   ├── TripOnboardingView.swift # Wizard planificar viaje (4 pasos)
│   ├── TripDetailView.swift     # Detalle de viaje (ver/editar rutas)
│   ├── MapExploreView.swift     # Mapa con todas las paradas + buscador
│   ├── MapView.swift            # Mapa de ruta activa
│   ├── RouteDetailView.swift
│   ├── ActiveRouteView.swift    # Vista de ruta en progreso
│   ├── ActiveRouteMiniPlayer.swift # Mini player flotante
│   ├── MyRoutesView.swift       # Rutas creadas por usuario (UGC)
│   ├── HistoryView.swift        # Historial de rutas completadas (accesible desde Perfil)
│   └── ProfileView.swift        # Perfil con puntos, nivel e historial integrado
├── DesignSystem/
│   ├── Theme.swift              # Colores, tipografía, espaciados
│   └── Components/              # Componentes reutilizables
│       ├── ACButton.swift, ACCard.swift, ACBadge.swift...
│       ├── ACTripCard.swift     # Card de viaje (usado en ViajesView)
│       ├── ACCitySearchField.swift    # Buscador de ciudad con autocompletado
│       ├── ACThemeSection.swift       # Sección de rutas agrupadas por temática
│       └── ACHistoryComponents.swift  # Componentes de historial (stats, record card)
├── RouteActivityWidget/         # Widget Extension para Live Activity
│   ├── RouteActivityWidget.swift
│   └── RouteActivityWidgetBundle.swift
└── Assets.xcassets/
```

## Navegación por Tabs (MainTabView)

```
Tab 0: Rutas        → RoutesListView (catálogo: favoritas, top, populares) - TAB INICIAL
Tab 1: Viajes       → ViajesView (planificación de viajes por destino)
Tab 2: Explorar     → MapExploreView (mapa con paradas + buscador de direcciones)
Tab 3: Crear        → MyRoutesView (rutas creadas por usuario)
Tab 4: Perfil       → ProfileView (puntos, nivel, historial integrado)
```

**Nota:** Historial está integrado como sección visible en ProfileView con acceso a HistoryView completo.

## Dynamic Island / Live Activity

### Funcionalidad
- Muestra la distancia al próximo punto de la ruta activa
- Se actualiza en tiempo real mientras el usuario camina
- Colores según proximidad: coral (>200m), naranja (50-200m), verde (<50m)
- **Se cierra automáticamente cuando la app pasa a background**

### Implementación iOS
```swift
// Iniciar Live Activity
LiveActivityServiceWrapper.shared.startActivity(
    routeName: route.name,
    routeCity: route.city,
    routeId: route.id,
    distanceToNextStop: distance,
    nextStopName: stop.name,
    nextStopOrder: stop.order,
    visitedStops: visited,
    totalStops: total,
    isPlaying: false
)

// Actualizar
LiveActivityServiceWrapper.shared.updateActivity(...)

// Finalizar
LiveActivityServiceWrapper.shared.endActivity()
```

### Implementación Android (equivalente)
Usar **Notificación persistente** con:
- Estilo: `NotificationCompat.Builder` con prioridad alta
- Mostrar: distancia, nombre próxima parada, progreso
- Actualizar en tiempo real con `NotificationManager.notify()`
- Colores según proximidad (igual que iOS)

## Ordenación de Rutas por Proximidad

Las rutas en la pantalla principal se ordenan por cercanía a la ubicación del usuario:

### iOS
```swift
// En RoutesListView
private func sortByProximity(_ routes: [Route]) -> [Route] {
    guard let location = userLocation else { return routes }
    return routes.sorted { route1, route2 in
        let distance1 = location.distance(from: CLLocation(
            latitude: route1.startLocation.latitude,
            longitude: route1.startLocation.longitude
        ))
        let distance2 = location.distance(from: CLLocation(
            latitude: route2.startLocation.latitude,
            longitude: route2.startLocation.longitude
        ))
        return distance1 < distance2
    }
}
```

### Android (equivalente)
```kotlin
fun sortByProximity(routes: List<Route>, userLocation: Location): List<Route> {
    return routes.sortedBy { route ->
        val routeLocation = Location("").apply {
            latitude = route.startLocation.latitude
            longitude = route.startLocation.longitude
        }
        userLocation.distanceTo(routeLocation)
    }
}
```

## Caché de Imágenes

### Funcionalidad
- Caché en memoria (NSCache/LruCache) para acceso rápido
- Caché en disco para persistencia entre sesiones
- Las imágenes de rutas (`thumbnailUrl`) se cachean automáticamente

### iOS (ImageCacheService)
```swift
// Singleton
ImageCacheService.shared.loadImage(from: url)  // Descarga con caché
ImageCacheService.shared.getImage(for: url)    // Solo caché
ImageCacheService.shared.clearCache()          // Limpiar

// Componente SwiftUI
CachedAsyncImage(url: url) {
    // Placeholder mientras carga
}
```

### Android (equivalente)
Usar **Coil** o **Glide** con caché configurado:
```kotlin
// Con Coil
AsyncImage(
    model = ImageRequest.Builder(context)
        .data(thumbnailUrl)
        .crossfade(true)
        .diskCachePolicy(CachePolicy.ENABLED)
        .memoryCachePolicy(CachePolicy.ENABLED)
        .build(),
    placeholder = painterResource(R.drawable.placeholder),
    contentDescription = null
)
```

## Imágenes de Rutas (thumbnailUrl)

### Modelo Route
```swift
struct Route {
    // ... otros campos
    let thumbnailUrl: String  // URL de imagen de la ruta (puede estar vacío)
    let startLocation: Location  // Para ordenar por proximidad
}
```

### Visualización
- Si `thumbnailUrl` tiene una URL válida: mostrar imagen con gradiente oscuro
- Si está vacío: mostrar placeholder con gradiente coral e icono de auriculares centrado

### Firebase
Campo `thumbnail_url` en la colección `routes`:
```json
{
  "id": "letras-poc-001",
  "name": "Barrio de las Letras",
  "thumbnail_url": "https://storage.googleapis.com/...",
  "start_location": {
    "latitude": 40.4140,
    "longitude": -3.6980,
    "name": "Plaza de Santa Ana"
  }
}
```

## Buscador de Direcciones (MapExploreView)

### Funcionalidad
- Campo de búsqueda en la parte superior del mapa
- Autocompletado con MKLocalSearchCompleter (iOS) / Places API (Android)
- Al seleccionar resultado, centra el mapa en esa ubicación

### iOS
```swift
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    func search(query: String) {
        completer.queryFragment = query
    }
}
```

### Android (equivalente)
```kotlin
// Usar Places SDK
val request = FindAutocompletePredictionsRequest.builder()
    .setQuery(searchText)
    .build()
placesClient.findAutocompletePredictions(request)
```

## Botón "Ver Ruta" en Paradas del Mapa

Cuando el usuario pulsa una parada en el mapa de exploración:
1. Se muestra `StopDetailCard` con información de la parada
2. Botón "Ver ruta" navega al tab Rutas con esa ruta seleccionada
3. Se detiene cualquier audio en reproducción

```swift
// En MapExploreView
onViewRoute: {
    viewModel.stopAudio()
    viewModel.selectedStop = nil
    onNavigateToRoute?(selectedStop.routeId)
}

// En MainTabView
onNavigateToRoute: { routeId in
    activeRouteViewModel.selectRouteById(routeId)
    selectedTab = 0  // Tab Rutas
}
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

## Arquitectura de Pantallas Principales

### RoutesListView (Tab Rutas)
```
RoutesListView
├── 🔍 ACCitySearchField (buscador de ciudad con autocompletado)
│   └── Detecta ciudad más cercana automáticamente
├── 📍 Header "Rutas en [Ciudad]" (muestra ciudad actual)
├── ❤️ Tus Favoritas (rutas favoritas de la ciudad, ordenadas por rating)
├── ⭐ Top Rutas (las 5 más usadas, ordenadas por usageCount)
└── 🏷️ Secciones por Temática (ACThemeSection)
    ├── 🏛️ Históricas
    ├── 🍽️ Gastronómicas
    ├── 🎨 Arte y Cultura
    └── ... (dinámico según rutas disponibles)
```

### ViajesView (Tab Viajes)
```
ViajesView
├── 🟢 Viaje Activo (destacado con borde verde)
├── 📅 Próximos Viajes
│   └── [Viaje] → ACTripCard → TripDetailView
├── 🕐 Viajes Pasados
│   └── [Viaje] → ACTripCard → TripDetailView
└── [+ Planificar] → TripOnboardingView
```

### ProfileView (Tab Perfil)
```
ProfileView
├── 👤 Header (nivel, puntos, progreso)
├── 📊 Estadísticas (rutas, km, tiempo, completadas)
├── 📜 Historial
│   ├── ACHistoryStatsRow (4 stats)
│   ├── ACHistoryRecordCard (máx 3 recientes)
│   └── [Ver todo] → HistoryView
└── ℹ️ Info y ajustes
```

## Optimización de Ruta

Cuando el usuario inicia una ruta, se le ofrece optimizar el orden:
1. Se calcula la parada más cercana a su ubicación actual
2. Si no es la primera parada, se muestra sheet de optimización
3. Opciones: "Optimizar ruta" (reordena) o "Seguir orden original"

```swift
// RouteOptimizationService
func shouldSuggestOptimization(stops: [Stop], userLocation: CLLocation) -> Bool
func getNearestStopInfo(stops: [Stop], userLocation: CLLocation) -> (name, distance, order)?
func optimizeRoute(stops: [Stop], userLocation: CLLocation) -> [Stop]
```

## Modelos de Datos Principales

### RouteTheme (Temática de Rutas)
```swift
enum RouteTheme: String, Codable, CaseIterable {
    case historicas = "Historicas"
    case gastronomicas = "Gastronomicas"
    case arte = "Arte"
    case naturaleza = "Naturaleza"
    case arquitectura = "Arquitectura"
    case nocturnas = "Nocturnas"
    case familiar = "Familiar"
    case general = "General"

    var displayName: String   // "Históricas", "Gastronómicas", etc.
    var icon: String          // SF Symbol: "building.columns.fill", etc.
    var color: Color          // Color asociado a la temática
}
```

### Route
```swift
struct Route {
    let id: String
    let name: String
    let description: String
    let city: String
    let neighborhood: String
    let durationMinutes: Int
    let distanceKm: Double
    let difficulty: String
    let numStops: Int
    let thumbnailUrl: String      // URL de imagen (puede estar vacío)
    let startLocation: Location   // Para ordenar por proximidad
    let endLocation: Location

    // Campos para ordenación y categorización
    let rating: Double            // 0.0-5.0 estrellas
    let usageCount: Int           // Veces completada por usuarios
    let theme: RouteTheme         // Temática de la ruta
}
```

### Stop
```swift
struct Stop {
    let id: String
    let routeId: String
    let name: String
    let description: String
    let scriptEs: String          // Narración en español
    let order: Int
    let latitude: Double
    let longitude: Double
    let triggerRadiusMeters: Double
    let audioDurationSeconds: Int
    var hasBeenVisited: Bool      // Estado durante ruta activa
}
```

## Servicios Clave

### ExploreViewModel (Singleton)
- `ExploreViewModel.shared` - Estado compartido del mapa
- Persiste posición del mapa entre cambios de tab
- `requestCurrentLocation()` - Solicita ubicación única (no tracking continuo)
- `hasCenteredOnUser` - Evita re-centrar innecesariamente

### ImageCacheService (Singleton)
- `loadImage(from: URL)` - Descarga con caché automática
- `getImage(for: URL)` - Solo consulta caché
- `clearCache()` - Limpia memoria y disco
- `formattedCacheSize()` - Tamaño de caché en disco

### LiveActivityServiceWrapper
- `startActivity(...)` - Inicia Dynamic Island
- `updateActivity(...)` - Actualiza distancia y estado
- `endActivity()` - Finaliza (se llama automáticamente al cerrar app)

## Colores de Marca (Design System)

```swift
// Colores principales
ACColors.primary        // Coral #FF6B5B
ACColors.primaryDark    // Coral oscuro
ACColors.primaryLight   // Coral claro (fondos)
ACColors.secondary      // Rosa/Púrpura (viajes)

// Estados
ACColors.success        // Verde (completado, cerca)
ACColors.warning        // Naranja (en progreso, medio)
ACColors.error          // Rojo (errores)
ACColors.info           // Azul (información, usuario→parada)

// Texto
ACColors.textPrimary    // Negro
ACColors.textSecondary  // Gris
ACColors.textTertiary   // Gris claro
```

## Notas para Desarrollo Android

1. **Live Activity → Notificación persistente**: Crear servicio foreground con notificación actualizable
2. **Caché de imágenes**: Usar Coil o Glide con configuración de caché
3. **Ordenación por proximidad**: Usar `Location.distanceTo()` de Android
4. **Buscador de direcciones**: Places SDK de Google
5. **Singleton ViewModels**: Usar Hilt/Dagger para inyección de dependencias
6. **Persistencia**: Room para datos complejos, DataStore para preferencias

## Rutas en Firebase

| ID | Nombre | Ciudad | Paradas | Theme | Rating | UsageCount |
|----|--------|--------|---------|-------|--------|------------|
| arganzuela-poc-001 | Descubre Arganzuela | Madrid | 6 | Naturaleza | 4.2 | 150 |
| letras-poc-001 | Barrio de las Letras | Madrid | 5 | Historicas | 4.5 | 200 |
| canal-poc-001 | Canal y Chamberí | Madrid | 5 | Arquitectura | 4.0 | 100 |
| valladolid-centro-001 | Valladolid Histórico | Valladolid | 15 | Historicas | 4.3 | 80 |
| zamora-romanico-001 | Zamora Románica | Zamora | 15 | Arte | 4.6 | 60 |

### Campos en Firebase (colección routes)
```json
{
  "id": "letras-poc-001",
  "name": "Barrio de las Letras",
  "city": "Madrid",
  "rating": 4.5,
  "usage_count": 200,
  "theme": "Historicas",
  "thumbnail_url": "https://storage.googleapis.com/..."
}
```

## Comandos Útiles

```bash
# Build iOS
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project AudioCityPOC.xcodeproj \
  -scheme AudioCityPOC \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Subir datos a Firebase
cd "/Users/juanrafernandez/Documents/AudioCity POC"
export GOOGLE_APPLICATION_CREDENTIALS="firebase-credentials.json"
python3 import_to_firebase.py
```

## Configuración de UI

- **Orientación:** Solo Portrait (iPhone y iPad)
- **Tema:** Solo modo claro (el design system está optimizado para light mode)
- **Mapa:** Se centra en ubicación del usuario al abrir (una sola vez)
- **Pins en mapa:** Coral (normal), Rosa (rutas de viaje), Verde (visitado), Azul (siguiente)

## Próximos Pasos Sugeridos

1. **Descarga real de tiles de mapa** - Implementar para mapas offline
2. **Audio pregrabado** - Opción de audio profesional vs TTS
3. **Badges/logros** - Medallas especiales por ciudades/rutas completadas
4. **Sincronización Firebase** - Subir rutas de usuario y puntos a la nube
5. **Ranking de usuarios** - Leaderboard por puntos/nivel
6. **Desarrollo Android** - Implementar paridad de funcionalidades
