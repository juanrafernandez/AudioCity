# AudioCity - Changelog

Registro de cambios para sincronización entre iOS y Android.

---

## [Unreleased]

### iOS (POC)

#### 2024-12-07
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
- [x] Modelos: Route, Stop con CodingKeys para snake_case

### UI
- [x] Splash screen nativo
- [x] Orientación bloqueada a Portrait
- [x] Marcadores de paradas en mapa con selección
- [x] Cards de detalle de parada
- [x] Estados de carga y error

---

## Pendiente para Android

### Prioridad Alta
- [ ] Centrar mapa en ubicación del usuario al abrir
- [ ] Bloquear orientación a Portrait
- [ ] Implementar geofences con Google Location Services
- [ ] Cola de audio con Text-to-Speech

### Prioridad Media
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

### Firebase
- Colección `routes`: Metadatos de rutas
- Colección `stops`: Paradas con `route_id`, coordenadas, scripts
- Campos en snake_case en Firebase, camelCase en código
