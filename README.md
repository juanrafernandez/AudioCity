# AudioCity - Audio Tour Platform

Plataforma de turismo basada en audio-guías geolocalizadas. El usuario compra una ruta, se pone los auriculares y camina. Cuando llega a puntos de interés, automáticamente se reproduce la narración del guía turístico.

## Tabla de Contenidos

- [Arquitectura General](#arquitectura-general)
- [Stack Tecnológico](#stack-tecnológico)
- [Estructura del Proyecto iOS](#estructura-del-proyecto-ios)
- [Modelos de Datos](#modelos-de-datos)
- [Servicios](#servicios)
- [Flujo de Geolocalización](#flujo-de-geolocalización)
- [Sistema de Audio](#sistema-de-audio)
- [Firebase - Estructura de Datos](#firebase---estructura-de-datos)
- [Guía para Android](#guía-para-android)

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTE                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   iOS App   │  │ Android App │  │   Web App   │          │
│  │  (SwiftUI)  │  │  (Kotlin)   │  │  (Future)   │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                      FIREBASE                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  Firestore  │  │    Auth     │  │   Storage   │          │
│  │   (datos)   │  │  (usuarios) │  │   (audio)   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## Stack Tecnológico

### iOS (Actual)
| Componente | Tecnología |
|------------|------------|
| UI | SwiftUI |
| Arquitectura | MVVM + Combine |
| Base de datos | Firebase Firestore |
| Geolocalización | CoreLocation |
| Audio | AVFoundation (TTS) |
| Mapas | MapKit |

### Android (Planificado)
| Componente | Tecnología Recomendada |
|------------|------------------------|
| UI | Jetpack Compose |
| Arquitectura | MVVM + Flow/StateFlow |
| Base de datos | Firebase Firestore |
| Geolocalización | Google Location Services |
| Audio | Android TTS / ExoPlayer |
| Mapas | Google Maps SDK |

---

## Estructura del Proyecto iOS

```
AudioCityPOC/
├── AudioCityPOCApp.swift      # Entry point, configuración Firebase
├── ContentView.swift          # Vista raíz con splash screen
├── Info.plist                 # Permisos y configuración
│
├── Models/
│   ├── Route.swift            # Modelo de ruta turística
│   └── Stop.swift             # Modelo de parada/punto de interés
│
├── Services/
│   ├── LocationService.swift  # Gestión de ubicación y geofences nativos
│   ├── GeofenceService.swift  # Detección de proximidad a paradas
│   ├── AudioService.swift     # Reproducción TTS con cola
│   └── FirebaseService.swift  # Comunicación con Firestore
│
├── ViewModels/
│   ├── RouteViewModel.swift   # Orquestador principal de una ruta
│   └── ExploreViewModel.swift # Exploración de paradas en mapa
│
└── Views/
    ├── SplashView.swift       # Pantalla de carga animada
    ├── MainTabView.swift      # Navegación por tabs
    ├── MapExploreView.swift   # Mapa de exploración
    ├── MapView.swift          # Mapa durante ruta activa
    ├── RoutesListView.swift   # Lista de rutas disponibles
    └── ProfileView.swift      # Perfil y configuración
```

---

## Modelos de Datos

### Route (Ruta)

```swift
struct Route: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let city: String
    let neighborhood: String
    let durationMinutes: Int
    let distanceKm: Double
    let difficulty: String        // "easy", "medium", "hard"
    let numStops: Int
    let language: String          // "es", "en", etc.
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let thumbnailUrl: String
    let startLocation: Location
    let endLocation: Location
}
```

### Stop (Parada)

```swift
struct Stop: Identifiable, Codable {
    let id: String
    let routeId: String
    let order: Int                    // Orden en la ruta (1, 2, 3...)
    let name: String
    let description: String
    let category: String              // "historia", "cultura", "gastronomía"...
    let latitude: Double
    let longitude: Double
    let triggerRadiusMeters: Double   // Radio para activar audio (default: 25-30m)
    let audioDurationSeconds: Int
    let imageUrl: String
    let scriptEs: String              // Texto a narrar en español
    let funFact: String               // Dato curioso
    var hasBeenVisited: Bool          // Estado mutable
}
```

---

## Servicios

### LocationService

Gestiona la ubicación del usuario con soporte para background.

**Responsabilidades:**
- Solicitar permisos de ubicación ("Always" para background)
- Tracking continuo con `distanceFilter = 5m`
- Registro de geofences nativos de iOS (máximo 20)
- Despertar la app cuando está suspendida

**Configuración crítica:**
```swift
locationManager.allowsBackgroundLocationUpdates = true
locationManager.pausesLocationUpdatesAutomatically = false
locationManager.showsBackgroundLocationIndicator = true
locationManager.desiredAccuracy = kCLLocationAccuracyBest
locationManager.distanceFilter = 5  // metros
```

**Geofences nativos:**
- Radio de wake-up: 100m (más amplio para despertar la app)
- Sirven para activar la app cuando está suspendida
- Límite de iOS: 20 regiones simultáneas

### GeofenceService

Detecta cuando el usuario entra en el radio de una parada.

**Características:**
- Suscripción a cambios de `userLocation` del LocationService
- Detección de múltiples paradas simultáneas
- Ordenación por `order` antes de activar
- Threshold de proximidad: `triggerRadiusMeters` de cada Stop

**Flujo:**
```
userLocation cambia
    → checkProximity()
        → para cada stop no visitada
            → si distancia <= triggerRadiusMeters
                → triggerStop()
                    → marcar como visitada
                    → publicar en @Published triggeredStop
```

### AudioService

Reproduce narraciones usando Text-to-Speech con sistema de cola.

**Características:**
- Cola de reproducción ordenada por `order`
- Evita duplicados con `processedStopIds`
- Reproducción automática del siguiente al terminar
- Controles: play, pause, resume, stop, skipToNext

**Configuración para background:**
```swift
audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
```

**Estructura de cola:**
```swift
struct AudioQueueItem {
    let id: String
    let stopId: String
    let stopName: String
    let text: String
    let order: Int
}
```

### FirebaseService

Comunicación con Firestore.

**Métodos principales:**
- `fetchAllRoutes()` - Obtiene rutas con `is_active == true`
- `fetchStops(for routeId:)` - Obtiene paradas ordenadas por `order`
- `fetchCompleteRoute(routeId:)` - Carga ruta + paradas en paralelo

---

## Flujo de Geolocalización

### Sistema Híbrido

```
┌─────────────────────────────────────────────────────────────┐
│                    APP SUSPENDIDA                            │
│  Geofences nativos (100m) → iOS despierta la app            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    APP EN BACKGROUND                         │
│  Location updates (5m) → GeofenceService (trigger 25-50m)   │
│  → AudioService cola → Reproducción secuencial              │
└─────────────────────────────────────────────────────────────┘
```

### ¿Por qué sistema híbrido?

| Geofences Nativos | Location Updates |
|-------------------|------------------|
| Funciona con app cerrada | Requiere app en background |
| Bajo consumo batería | Mayor consumo |
| Precisión ~100m | Precisión ~5m |
| Máximo 20 regiones | Sin límite |

**Solución:** Geofences nativos para "despertar" la app, Location Updates para precisión.

---

## Sistema de Audio

### Arquitectura de Cola

```
Stop detectada → enqueueStop() → audioQueue (ordenada por order)
                                      ↓
                               playNextInQueue()
                                      ↓
                               AVSpeechSynthesizer
                                      ↓
                               didFinish → playNextInQueue()
```

### Configuración TTS

```swift
utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
utterance.rate = 0.50      // Velocidad natural
utterance.pitchMultiplier = 1.0
utterance.volume = 1.0
```

### Futuro: Audio Pregrabado

Para producción, reemplazar TTS por archivos de audio:
- Almacenar en Firebase Storage
- Descargar y cachear localmente
- Usar AVAudioPlayer en lugar de AVSpeechSynthesizer

---

## Firebase - Estructura de Datos

### Colección: `routes`

```json
{
  "id": "arganzuela-poc-001",
  "name": "Descubre Arganzuela",
  "description": "Paseo por la transformación urbana...",
  "city": "Madrid",
  "neighborhood": "Arganzuela",
  "language": "es",
  "difficulty": "easy",
  "duration_minutes": 45,
  "distance_km": 2.0,
  "num_stops": 6,
  "is_active": true,
  "thumbnail_url": "",
  "start_location": {
    "name": "Matadero Madrid",
    "latitude": 40.3917,
    "longitude": -3.6989
  },
  "end_location": {
    "name": "Zona Legazpi",
    "latitude": 40.3927,
    "longitude": -3.6918
  },
  "created_at": "2025-11-23T00:00:00Z",
  "updated_at": "2025-11-23T00:00:00Z"
}
```

### Colección: `stops`

```json
{
  "id": "arg-001",
  "route_id": "arganzuela-poc-001",
  "order": 1,
  "name": "Matadero Madrid",
  "description": "Centro de creación contemporánea...",
  "category": "cultura",
  "latitude": 40.3917,
  "longitude": -3.6989,
  "trigger_radius_meters": 25,
  "audio_duration_seconds": 75,
  "image_url": "",
  "script_es": "Bienvenido al Matadero Madrid...",
  "fun_fact": "El Matadero ocupa 165,000 metros cuadrados...",
  "has_been_visited": false
}
```

### Índices Requeridos

```
Collection: stops
Fields: route_id (ASC), order (ASC)
```

---

## Guía para Android

### Equivalencias iOS → Android

| iOS | Android |
|-----|---------|
| SwiftUI | Jetpack Compose |
| @Published / Combine | StateFlow / Flow |
| @StateObject | viewModel() con Hilt |
| CoreLocation | FusedLocationProviderClient |
| CLCircularRegion | GeofencingClient |
| AVSpeechSynthesizer | TextToSpeech |
| MapKit | Google Maps SDK |
| UserDefaults | DataStore |

### Permisos Android

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

### Estructura Recomendada Android

```
app/
├── di/                        # Dependency Injection (Hilt)
├── data/
│   ├── model/
│   │   ├── Route.kt
│   │   └── Stop.kt
│   ├── repository/
│   │   └── RouteRepository.kt
│   └── firebase/
│       └── FirebaseService.kt
├── domain/
│   └── usecase/
├── service/
│   ├── LocationService.kt     # Foreground Service
│   ├── GeofenceService.kt
│   └── AudioService.kt
├── ui/
│   ├── splash/
│   ├── routes/
│   ├── map/
│   └── profile/
└── util/
```

### Geofencing en Android

```kotlin
// Crear geofence
val geofence = Geofence.Builder()
    .setRequestId(stopId)
    .setCircularRegion(latitude, longitude, radiusMeters)
    .setExpirationDuration(Geofence.NEVER_EXPIRE)
    .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
    .build()

// Registrar con GeofencingClient
geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent)
```

### Location Updates en Android

```kotlin
val locationRequest = LocationRequest.Builder(
    Priority.PRIORITY_HIGH_ACCURACY,
    5000  // interval ms
).apply {
    setMinUpdateDistanceMeters(5f)
    setWaitForAccurateLocation(true)
}.build()

fusedLocationClient.requestLocationUpdates(
    locationRequest,
    locationCallback,
    Looper.getMainLooper()
)
```

### TextToSpeech en Android

```kotlin
val tts = TextToSpeech(context) { status ->
    if (status == TextToSpeech.SUCCESS) {
        tts.language = Locale("es", "ES")
        tts.setSpeechRate(0.9f)
    }
}

tts.speak(text, TextToSpeech.QUEUE_ADD, null, utteranceId)
```

---

## Configuración del Proyecto

### iOS - Info.plist

Permisos requeridos:
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para activar las audioguías cuando llegues a los puntos de interés</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte las rutas cercanas</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>location</string>
</array>
```

### Firebase

1. Crear proyecto en Firebase Console
2. Añadir app iOS con Bundle ID
3. Descargar `GoogleService-Info.plist`
4. Habilitar Firestore en modo producción
5. Crear índice para `stops` (route_id + order)

---

## Roadmap

### Fase 1 - POC (Actual)
- [x] Arquitectura base MVVM
- [x] Integración Firebase
- [x] Geolocalización background
- [x] Sistema de audio TTS
- [x] Lista de rutas
- [x] Mapa interactivo
- [x] Cola de reproducción
- [x] Splash screen animado

### Fase 2 - MVP
- [ ] Autenticación de usuarios
- [ ] Compra de rutas (in-app purchase)
- [ ] Audio pregrabado (Firebase Storage)
- [ ] Modo offline
- [ ] Notificaciones push
- [ ] Analytics

### Fase 3 - Escalado
- [ ] App Android
- [ ] Sistema de descuentos/negocios
- [ ] Panel de administración web
- [ ] Múltiples idiomas
- [ ] Rutas generadas por usuarios

---

## Licencia

Proyecto privado - AudioCity POC
