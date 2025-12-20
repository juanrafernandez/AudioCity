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
- [UI/UX - Pantallas](#uiux---pantallas)
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
├── Info.plist                 # Permisos, Launch Screen config
│
├── Assets.xcassets/
│   ├── AppIcon.appiconset/    # Icono de la app
│   ├── AppLogo_transp.imageset/ # Logo transparente (splash/launch)
│   ├── LaunchBackground.colorset/ # Color de fondo del launch screen
│   └── AccentColor.colorset/  # Color de acento
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
    ├── MainTabView.swift      # Navegación por tabs (3 tabs)
    ├── MapExploreView.swift   # Tab 1: Mapa de exploración
    ├── RoutesListView.swift   # Tab 2: Lista de rutas + detalle
    ├── MapView.swift          # Mapa durante ruta activa
    └── ProfileView.swift      # Tab 3: Perfil y configuración
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

**Kotlin equivalente:**
```kotlin
data class Route(
    val id: String,
    val name: String,
    val description: String,
    val city: String,
    val neighborhood: String,
    @PropertyName("duration_minutes") val durationMinutes: Int,
    @PropertyName("distance_km") val distanceKm: Double,
    val difficulty: String,
    @PropertyName("num_stops") val numStops: Int,
    val language: String,
    @PropertyName("is_active") val isActive: Boolean,
    @PropertyName("created_at") val createdAt: String,
    @PropertyName("updated_at") val updatedAt: String,
    @PropertyName("thumbnail_url") val thumbnailUrl: String,
    @PropertyName("start_location") val startLocation: Location,
    @PropertyName("end_location") val endLocation: Location
)

data class Location(
    val latitude: Double,
    val longitude: Double,
    val name: String
)
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
    var hasBeenVisited: Bool          // Estado mutable (local, no en Firebase)
}
```

**Kotlin equivalente:**
```kotlin
data class Stop(
    val id: String,
    @PropertyName("route_id") val routeId: String,
    val order: Int,
    val name: String,
    val description: String,
    val category: String,
    val latitude: Double,
    val longitude: Double,
    @PropertyName("trigger_radius_meters") val triggerRadiusMeters: Double,
    @PropertyName("audio_duration_seconds") val audioDurationSeconds: Int,
    @PropertyName("image_url") val imageUrl: String,
    @PropertyName("script_es") val scriptEs: String,
    @PropertyName("fun_fact") val funFact: String,
    var hasBeenVisited: Boolean = false  // Local state
)
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

**Configuración crítica iOS:**
```swift
locationManager.allowsBackgroundLocationUpdates = true
locationManager.pausesLocationUpdatesAutomatically = false
locationManager.showsBackgroundLocationIndicator = true
locationManager.desiredAccuracy = kCLLocationAccuracyBest
locationManager.distanceFilter = 5  // metros
```

**Configuración equivalente Android:**
```kotlin
val locationRequest = LocationRequest.Builder(
    Priority.PRIORITY_HIGH_ACCURACY,
    5000  // interval ms
).apply {
    setMinUpdateDistanceMeters(5f)
    setWaitForAccurateLocation(true)
}.build()
```

**Geofences nativos:**
- Radio de wake-up: 100m (más amplio para despertar la app)
- Sirven para activar la app cuando está suspendida
- Límite de iOS: 20 regiones simultáneas
- Límite de Android: 100 geofences por app

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
                    → encolar audio en AudioService
```

### AudioService

Reproduce narraciones usando Text-to-Speech con sistema de cola.

**Características:**
- Cola de reproducción ordenada por `order`
- Evita duplicados con `processedStopIds`
- Reproducción automática del siguiente al terminar
- Controles: play, pause, resume, stop, skipToNext

**Configuración para background iOS:**
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

**Kotlin equivalente:**
```kotlin
data class AudioQueueItem(
    val id: String,
    val stopId: String,
    val stopName: String,
    val text: String,
    val order: Int
)
```

### FirebaseService

Comunicación con Firestore.

**Métodos principales:**
- `fetchAllRoutes()` - Obtiene rutas con `is_active == true`
- `fetchStops(for routeId:)` - Obtiene paradas ordenadas por `order`
- `fetchCompleteRoute(routeId:)` - Carga ruta + paradas en paralelo

**Queries Firestore:**
```kotlin
// Obtener rutas activas
db.collection("routes")
    .whereEqualTo("is_active", true)
    .get()

// Obtener paradas de una ruta ordenadas
db.collection("stops")
    .whereEqualTo("route_id", routeId)
    .orderBy("order")
    .get()
```

---

## Flujo de Geolocalización

### Sistema Híbrido

```
┌─────────────────────────────────────────────────────────────┐
│                    APP SUSPENDIDA/CERRADA                    │
│  Geofences nativos (100m) → Sistema despierta la app        │
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
| Máximo 20 (iOS) / 100 (Android) | Sin límite |

**Solución:** Geofences nativos para "despertar" la app, Location Updates para precisión.

---

## Sistema de Audio

### Arquitectura de Cola

```
Stop detectada → enqueueStop() → audioQueue (ordenada por order)
                                      ↓
                               playNextInQueue()
                                      ↓
                               TTS Engine
                                      ↓
                               onDone → playNextInQueue()
```

### Configuración TTS iOS

```swift
utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
utterance.rate = 0.50      // Velocidad natural
utterance.pitchMultiplier = 1.0
utterance.volume = 1.0
```

### Configuración TTS Android

```kotlin
val tts = TextToSpeech(context) { status ->
    if (status == TextToSpeech.SUCCESS) {
        tts.language = Locale("es", "ES")
        tts.setSpeechRate(0.9f)  // Android usa escala diferente
    }
}

// Con listener para reproducción secuencial
tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
    override fun onDone(utteranceId: String?) {
        playNextInQueue()
    }
    override fun onStart(utteranceId: String?) {}
    override fun onError(utteranceId: String?) {}
})

tts.speak(text, TextToSpeech.QUEUE_ADD, null, uniqueUtteranceId)
```

### Futuro: Audio Pregrabado

Para producción, reemplazar TTS por archivos de audio:
- Almacenar en Firebase Storage
- Descargar y cachear localmente
- iOS: usar `AVAudioPlayer`
- Android: usar `ExoPlayer` o `MediaPlayer`

---

## UI/UX - Pantallas

### Launch Screen (Nativo)
- **iOS:** Configurado en `Info.plist` con `UILaunchScreen`
- **Android:** Usar SplashScreen API (Android 12+) o tema con windowBackground
- Color de fondo: Azul marca (#3361FA)
- Logo centrado: `AppLogo_transp`

### Splash View (Animado)
Pantalla de carga con animaciones mientras se inicializa la app:
- Logo con animación de pulso suave
- Ondas circulares expandiéndose (efecto "audio waves")
- Texto "AudioCity" + tagline
- Barras de audio animadas como indicador de carga
- Duración: ~2.5 segundos

**Implementación Android:**
```kotlin
@Composable
fun SplashScreen(onFinished: () -> Unit) {
    var isAnimating by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        isAnimating = true
        delay(2500)
        onFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BrandColor),
        contentAlignment = Alignment.Center
    ) {
        // Logo con animación
        Image(
            painter = painterResource(R.drawable.app_logo_transp),
            modifier = Modifier
                .size(150.dp)
                .scale(if (isAnimating) 1.05f else 1f)
        )
        // Ondas animadas...
    }
}
```

### Navegación Principal (Tab Bar)
3 tabs:
1. **Explorar** - Mapa con todas las paradas
2. **Rutas** - Lista de rutas disponibles
3. **Perfil** - Configuración y estado

### Lista de Rutas
- Cards con: icono por categoría, nombre, ubicación, descripción
- Stats: duración, distancia, número de paradas
- Badge de dificultad (Easy/Medium/Hard)
- Colores por barrio/categoría

### Detalle de Ruta
- Header con icono y nombre
- Descripción completa
- Stats en grid (duración, distancia, dificultad, barrio, paradas)
- Lista de paradas con indicador de orden
- Botón "Iniciar Ruta"

### Mapa Activo (Durante Ruta)
- Marcadores numerados por orden de parada
- Colores: naranja (pendiente), azul (actual), verde (visitada)
- Banner superior con parada en reproducción
- Controles de audio (pause/resume, stop)
- Barra de progreso
- Botón X para finalizar ruta

---

## Firebase - Estructura de Datos

### Colección: `routes`

```json
{
  "id": "arganzuela-poc-001",
  "name": "Descubre Arganzuela",
  "description": "Paseo por la transformación urbana de uno de los barrios más dinámicos de Madrid",
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
  "description": "Centro de creación contemporánea en antiguo matadero",
  "category": "cultura",
  "latitude": 40.3917,
  "longitude": -3.6989,
  "trigger_radius_meters": 25,
  "audio_duration_seconds": 75,
  "image_url": "",
  "script_es": "Bienvenido al Matadero Madrid. Este lugar es uno de los mejores ejemplos de regeneración urbana en España...",
  "fun_fact": "El Matadero ocupa 165,000 metros cuadrados, casi el tamaño de 23 campos de fútbol",
  "has_been_visited": false
}
```

### Índices Requeridos

```
Collection: stops
Fields: route_id (ASC), order (ASC)
```

### Rutas de ejemplo en el POC

| ID | Nombre | Barrio | Paradas |
|----|--------|--------|---------|
| arganzuela-poc-001 | Descubre Arganzuela | Arganzuela | 6 |
| letras-poc-001 | Barrio de las Letras | Centro | 5 |
| canal-poc-001 | Canal y Chamberí | Chamberí | 5 |

---

## Guía para Android

### Equivalencias iOS → Android

| iOS | Android |
|-----|---------|
| SwiftUI | Jetpack Compose |
| @Published / Combine | StateFlow / Flow |
| @StateObject / @ObservedObject | viewModel() con Hilt |
| CoreLocation | FusedLocationProviderClient |
| CLCircularRegion | GeofencingClient |
| AVSpeechSynthesizer | TextToSpeech |
| MapKit | Google Maps SDK |
| UserDefaults | DataStore Preferences |
| Info.plist | AndroidManifest.xml |
| UILaunchScreen | SplashScreen API |

### Permisos Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Estructura Recomendada Android

```
app/
├── src/main/
│   ├── java/com/audiocity/
│   │   ├── di/                        # Hilt modules
│   │   │   ├── AppModule.kt
│   │   │   └── FirebaseModule.kt
│   │   │
│   │   ├── data/
│   │   │   ├── model/
│   │   │   │   ├── Route.kt
│   │   │   │   ├── Stop.kt
│   │   │   │   └── AudioQueueItem.kt
│   │   │   ├── repository/
│   │   │   │   └── RouteRepository.kt
│   │   │   └── firebase/
│   │   │       └── FirebaseService.kt
│   │   │
│   │   ├── service/
│   │   │   ├── LocationService.kt     # Foreground Service
│   │   │   ├── GeofenceService.kt
│   │   │   ├── GeofenceBroadcastReceiver.kt
│   │   │   └── AudioService.kt
│   │   │
│   │   ├── ui/
│   │   │   ├── theme/
│   │   │   │   ├── Color.kt
│   │   │   │   ├── Theme.kt
│   │   │   │   └── Type.kt
│   │   │   ├── splash/
│   │   │   │   └── SplashScreen.kt
│   │   │   ├── routes/
│   │   │   │   ├── RoutesListScreen.kt
│   │   │   │   ├── RouteDetailScreen.kt
│   │   │   │   ├── RouteCard.kt
│   │   │   │   └── RoutesViewModel.kt
│   │   │   ├── map/
│   │   │   │   ├── MapExploreScreen.kt
│   │   │   │   ├── ActiveRouteMapScreen.kt
│   │   │   │   └── MapViewModel.kt
│   │   │   ├── profile/
│   │   │   │   └── ProfileScreen.kt
│   │   │   └── navigation/
│   │   │       ├── NavGraph.kt
│   │   │       └── BottomNavBar.kt
│   │   │
│   │   ├── util/
│   │   │   ├── PermissionHelper.kt
│   │   │   └── Extensions.kt
│   │   │
│   │   └── AudioCityApp.kt            # Application class
│   │
│   ├── res/
│   │   ├── drawable/
│   │   │   └── app_logo_transp.png
│   │   ├── values/
│   │   │   ├── colors.xml
│   │   │   ├── strings.xml
│   │   │   └── themes.xml
│   │   └── xml/
│   │       └── backup_rules.xml
│   │
│   └── AndroidManifest.xml
│
└── build.gradle.kts
```

### Dependencias Android (build.gradle.kts)

```kotlin
dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.navigation:navigation-compose:2.7.6")

    // Lifecycle + ViewModel
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Location
    implementation("com.google.android.gms:play-services-location:21.0.1")

    // Maps
    implementation("com.google.maps.android:maps-compose:4.3.0")
    implementation("com.google.android.gms:play-services-maps:18.2.0")

    // Splash Screen
    implementation("androidx.core:core-splashscreen:1.0.1")
}
```

### Geofencing en Android

```kotlin
class GeofenceService @Inject constructor(
    private val geofencingClient: GeofencingClient,
    private val context: Context
) {
    private val geofencePendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    fun registerGeofences(stops: List<Stop>) {
        val geofences = stops.map { stop ->
            Geofence.Builder()
                .setRequestId(stop.id)
                .setCircularRegion(
                    stop.latitude,
                    stop.longitude,
                    stop.triggerRadiusMeters.toFloat()
                )
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
                .build()
        }

        val request = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofences)
            .build()

        geofencingClient.addGeofences(request, geofencePendingIntent)
    }

    fun clearGeofences() {
        geofencingClient.removeGeofences(geofencePendingIntent)
    }
}
```

### Location Updates en Android

```kotlin
class LocationService @Inject constructor(
    private val fusedLocationClient: FusedLocationProviderClient
) {
    private val _userLocation = MutableStateFlow<Location?>(null)
    val userLocation: StateFlow<Location?> = _userLocation.asStateFlow()

    private val locationRequest = LocationRequest.Builder(
        Priority.PRIORITY_HIGH_ACCURACY,
        5000  // interval ms
    ).apply {
        setMinUpdateDistanceMeters(5f)
        setWaitForAccurateLocation(true)
    }.build()

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { location ->
                _userLocation.value = location
            }
        }
    }

    fun startTracking() {
        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    fun stopTracking() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }
}
```

### TextToSpeech con Cola en Android

```kotlin
class AudioService(context: Context) {
    private var tts: TextToSpeech? = null
    private val audioQueue = mutableListOf<AudioQueueItem>()
    private val processedStopIds = mutableSetOf<String>()

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _currentItem = MutableStateFlow<AudioQueueItem?>(null)
    val currentItem: StateFlow<AudioQueueItem?> = _currentItem.asStateFlow()

    init {
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale("es", "ES")
                tts?.setSpeechRate(0.9f)

                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        _isPlaying.value = true
                    }
                    override fun onDone(utteranceId: String?) {
                        _isPlaying.value = false
                        playNextInQueue()
                    }
                    override fun onError(utteranceId: String?) {
                        _isPlaying.value = false
                    }
                })
            }
        }
    }

    fun enqueueStop(stop: Stop) {
        if (processedStopIds.contains(stop.id)) return

        val item = AudioQueueItem(
            id = UUID.randomUUID().toString(),
            stopId = stop.id,
            stopName = stop.name,
            text = stop.scriptEs,
            order = stop.order
        )

        // Insertar ordenado
        val index = audioQueue.indexOfFirst { it.order > stop.order }
        if (index == -1) audioQueue.add(item) else audioQueue.add(index, item)
        processedStopIds.add(stop.id)

        if (!_isPlaying.value) {
            playNextInQueue()
        }
    }

    private fun playNextInQueue() {
        if (audioQueue.isEmpty()) {
            _currentItem.value = null
            return
        }

        val item = audioQueue.removeAt(0)
        _currentItem.value = item

        tts?.speak(item.text, TextToSpeech.QUEUE_FLUSH, null, item.id)
    }

    fun pause() = tts?.stop()
    fun stop() {
        tts?.stop()
        audioQueue.clear()
        _currentItem.value = null
    }

    fun release() {
        tts?.shutdown()
        tts = null
    }
}
```

### Splash Screen Android 12+

```kotlin
// En themes.xml
<style name="Theme.AudioCity.Splash" parent="Theme.SplashScreen">
    <item name="windowSplashScreenBackground">@color/brand_blue</item>
    <item name="windowSplashScreenAnimatedIcon">@drawable/app_logo_transp</item>
    <item name="postSplashScreenTheme">@style/Theme.AudioCity</item>
</style>

// En MainActivity.kt
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)

        // Mantener splash mientras carga
        splashScreen.setKeepOnScreenCondition { viewModel.isLoading.value }

        setContent {
            AudioCityTheme {
                // ...
            }
        }
    }
}
```

---

## Configuración del Proyecto

### iOS - Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <!-- Permisos de ubicación -->
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Necesitamos tu ubicación para activar las audioguías cuando llegues a los puntos de interés</string>

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Necesitamos tu ubicación para mostrarte las rutas cercanas</string>

    <!-- Background modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>location</string>
    </array>

    <!-- Launch Screen -->
    <key>UILaunchScreen</key>
    <dict>
        <key>UIColorName</key>
        <string>LaunchBackground</string>
        <key>UIImageName</key>
        <string>AppLogo_transp</string>
        <key>UIImageRespectsSafeAreaInsets</key>
        <true/>
    </dict>
</dict>
</plist>
```

### Firebase Setup

1. Crear proyecto en Firebase Console
2. Añadir app iOS con Bundle ID: `com.audiocity.poc`
3. Añadir app Android con package: `com.audiocity.android`
4. Descargar `GoogleService-Info.plist` (iOS) y `google-services.json` (Android)
5. Habilitar Firestore
6. Crear índice para `stops`: `route_id (ASC), order (ASC)`

### Colores de Marca

```
Brand Blue:    #3361FA (RGB: 51, 97, 250)
Brand Blue Dark: #1E47D9 (para dark mode)
```

---

## Roadmap

### Fase 1 - POC (Actual)
- [x] Arquitectura base MVVM
- [x] Integración Firebase
- [x] Geolocalización background
- [x] Sistema de audio TTS con cola
- [x] Lista de rutas dinámica
- [x] Mapa interactivo
- [x] Launch Screen nativo
- [x] Splash screen animado
- [x] Documentación técnica

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

## 🔧 Setup de Desarrollo

### Prerequisitos
- Xcode 15.0+
- iOS 16.0+ deployment target
- Firebase account

### Configuración Inicial

1. **Firebase Credentials:**
   ```bash
   # Copiar la plantilla
   cp AudioCityPOC/AudioCityPOC/GoogleService-Info.plist.template AudioCityPOC/AudioCityPOC/GoogleService-Info.plist

   # Editar con tus credenciales de Firebase
   # Obtener desde: https://console.firebase.google.com/
   ```

2. **Instalación:**
   ```bash
   # Abrir el proyecto
   open AudioCityPOC/AudioCityPOC.xcodeproj

   # Build el proyecto (⌘+B)
   ```

3. **Verificar:**
   - El archivo `GoogleService-Info.plist` NO debe aparecer en git
   - Verificar con: `git status` (no debe listarse)

### ⚠️ NUNCA COMMITEAR:
- `GoogleService-Info.plist`
- `firebase-credentials.json`
- Archivos en `/snapshots/`

---

## Licencia

Proyecto privado - AudioCity POC
