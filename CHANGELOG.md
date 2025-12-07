# AudioCity - Changelog

Registro de cambios para sincronización entre iOS y Android.

---

## [Unreleased]

### iOS (POC)

#### 2025-12-07
- **feat:** Sistema de planificación de viajes estilo Wikiloc
  - Nueva sección "Mis Viajes" en pantalla de Rutas
  - Onboarding de 4 pasos: destino → rutas → opciones → resumen
  - Selección de destino con ciudades disponibles
  - Selección múltiple de rutas por destino
  - Opción de fechas del viaje (opcional)
  - Descarga offline de rutas con estimación de tamaño
  - Persistencia de viajes en UserDefaults

- **feat:** Rediseño de pantalla de Rutas con secciones
  - Sección "Rutas Favoritas" (scroll horizontal, con corazón)
  - Sección "Top Rutas" (scroll horizontal)
  - Sección "Rutas de Moda" (scroll horizontal) - con rutas mock temporales
  - Botón "Todas las Rutas" → abre pantalla con buscador
  - Nueva card compacta `RouteCardCompact` para secciones horizontales

- **feat:** Rutas de Moda mockeadas para UI
  - Ruta de la Tapa por Lavapiés (gastronomía, 90min)
  - Ruta de Navidad (luces y mercadillos, 120min)
  - Ruta Black Friday (compras, 150min)

- **fix:** Modelo Stop con campos opcionales
  - `funFact`, `imageUrl` ahora opcionales
  - Valores por defecto para `triggerRadiusMeters`, `audioDurationSeconds`, `category`
  - `hasBeenVisited` ya no se decodifica de Firebase (estado runtime)

- **feat:** Pantalla "Todas las Rutas" (`AllRoutesView`)
  - Buscador por nombre, descripción, ciudad, barrio
  - Filtro por dificultad (Fácil/Media/Difícil)
  - Filtro por ciudad
  - Ordenación (nombre, duración, distancia, nº paradas)
  - Botón de favorito en cada card

- **feat:** Sistema de favoritos (`FavoritesService`)
  - Toggle favorito en rutas
  - Persistencia en UserDefaults
  - Sección dedicada en pantalla principal

- **feat:** Servicio de caché offline (`OfflineCacheService`)
  - Descarga de rutas y paradas para uso sin conexión
  - Cálculo de región del mapa para cada ruta
  - Gestión de espacio en disco
  - Progreso de descarga con estados

- **feat:** Centrar mapa en ubicación actual del usuario al abrir la app
  - El mapa se posiciona automáticamente en la ubicación del usuario al cargar `MapExploreView`
  - Se inicia tracking de ubicación inmediatamente al aparecer la vista
  - Solo se centra una vez para no interrumpir la navegación del usuario
  - Zoom más cercano (0.02) al centrar en usuario vs zoom por defecto (0.05)

#### 2024-12-06
- **fix:** Bloquear orientación a Portrait (solo vertical) en iPhone y iPad

#### Anteriores
- **feat:** Pantalla de splash nativa con logo de la app
- **feat:** Cola de audio para reproducción secuencial de paradas
- **feat:** Geofences nativos (100m) para despertar la app en background
- **feat:** Location updates de alta precisión (5m) para detección de paradas
- **feat:** Lista de rutas disponibles con información de ciudad, duración y dificultad
- **feat:** Vista de exploración con mapa y todas las paradas
- **feat:** Reproducción de audio TTS con controles (play/pause/stop)
- **feat:** Detalle de parada con script, fun facts y categoría

---

## Funcionalidades Implementadas (iOS)

### Navegación
- [x] Tab bar con pestañas: Explorar, Rutas, Perfil
- [x] Mapa centrado en ubicación actual del usuario al abrir
- [x] Botón "Mi ubicación" para recentrar manualmente

### Rutas (estilo Wikiloc)
- [x] Secciones: Favoritas, Top Rutas, Rutas de Moda (scroll horizontal)
- [x] Botón "Todas las Rutas" abre pantalla con buscador
- [x] Cards compactas y detalladas
- [x] Categorización de rutas

### Favoritos
- [x] FavoritesService con persistencia
- [x] Toggle favorito en cards de rutas
- [x] Sección "Rutas Favoritas" en pantalla principal

### Búsqueda y Filtros (AllRoutesView)
- [x] Buscador por texto (nombre, descripción, ciudad, barrio)
- [x] Filtro por dificultad
- [x] Filtro por ciudad
- [x] Ordenación múltiple (nombre, duración, distancia, paradas)

### Mis Viajes
- [x] Planificación de viajes con onboarding
- [x] Selección de destino por ciudad
- [x] Selección múltiple de rutas
- [x] Fechas opcionales del viaje
- [x] Descarga offline de rutas
- [x] Persistencia en UserDefaults

### Offline
- [x] OfflineCacheService para gestión de caché
- [x] Descarga de rutas y paradas
- [x] Cálculo de región del mapa
- [x] Estimación de tamaño de descarga
- [x] Progreso de descarga con estados

### Geolocalización
- [x] Permisos de ubicación (Always para background)
- [x] Geofences nativos iOS (máx 20, radio 100m) para wake-up
- [x] Location updates continuos (distanceFilter: 5m)
- [x] Background location indicator

### Audio
- [x] Text-to-Speech con AVSpeechSynthesizer
- [x] Cola de reproducción ordenada por `order`
- [x] Controles: play, pause, resume, stop
- [x] Evita duplicados con `processedStopIds`
- [x] Background audio mode habilitado

### Datos
- [x] Conexión a Firebase Firestore
- [x] Carga de rutas y paradas
- [x] Modelos: Route, Stop, Trip, CachedRoute

### UI
- [x] Splash screen nativo
- [x] Orientación bloqueada a Portrait
- [x] Marcadores de paradas en mapa con selección
- [x] Cards de detalle de parada
- [x] Estados de carga y error

---

## Pendiente para Android

### Prioridad Alta
- [ ] Sistema de planificación de viajes (Mis Viajes)
- [ ] Onboarding de viaje (4 pasos)
- [ ] Secciones de rutas (Favoritas, Top, Trending)
- [ ] Pantalla AllRoutes con buscador y filtros
- [ ] Sistema de favoritos
- [ ] Descarga offline de rutas
- [ ] Centrar mapa en ubicación del usuario al abrir
- [ ] Bloquear orientación a Portrait
- [ ] Implementar geofences con Google Location Services
- [ ] Cola de audio con Text-to-Speech

### Prioridad Media
- [ ] Persistencia de viajes y favoritos (SharedPreferences/Room)
- [ ] Caché de mapas offline
- [ ] Background location tracking
- [ ] Notificaciones locales al entrar en geofence
- [ ] Splash screen con logo

### Prioridad Baja
- [ ] Animaciones de transición
- [ ] Indicador de reproducción (ondas de audio)

---

## Notas Técnicas

### Equivalencias iOS → Android

| iOS | Android |
|-----|---------|
| CoreLocation | Google Location Services |
| CLCircularRegion | GeofencingClient |
| AVSpeechSynthesizer | TextToSpeech |
| MapKit | Google Maps SDK |
| SwiftUI | Jetpack Compose |
| Combine | Flow/StateFlow |
| @StateObject | viewModel() |
| @Published | MutableStateFlow |
| UserDefaults | SharedPreferences / DataStore |
| FileManager | Context.filesDir |

### Nuevos Modelos de Datos

```
Trip
├── id: String
├── destinationCity: String
├── destinationCountry: String
├── selectedRouteIds: [String]
├── createdAt: Date
├── startDate: Date? (opcional)
├── endDate: Date? (opcional)
├── isOfflineAvailable: Bool
└── lastSyncDate: Date?

CachedRoute
├── id: String
├── tripId: String
├── route: Route
├── stops: [Stop]
├── cachedAt: Date
├── mapTilesPath: String?
├── audioFilesPath: String?
└── totalSizeBytes: Int64

Destination
├── id: String
├── city: String
├── country: String
├── routeCount: Int
├── imageUrl: String?
└── isPopular: Bool
```

### Arquitectura de Pantalla de Rutas

```
RoutesListView
├── Header ("Descubre tu ciudad")
├── Mis Viajes Section
│   ├── TripCard (para cada viaje)
│   └── "Planificar Viaje" button → TripOnboardingView
├── Top Rutas (horizontal scroll)
├── Rutas de Moda (horizontal scroll)
├── Rutas Turísticas (vertical list)
└── Todas las Rutas
```

### Firebase
- Colección `routes`: Metadatos de rutas
- Colección `stops`: Paradas con `route_id`, coordenadas, scripts
- Campos en snake_case en Firebase, camelCase en código
