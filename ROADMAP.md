# AudioCity - Roadmap a Producción
## De POC a Producto Profesional

**Fecha de inicio:** Diciembre 2025
**Target de lanzamiento MVP:** Marzo 2026 (3 meses)
**Versión completa:** Junio 2026 (6 meses)

---

## 🚨 FASE 0: SEGURIDAD Y LIMPIEZA CRÍTICA (Semana 1)
**Prioridad:** CRÍTICA - Debe completarse antes de cualquier otro trabajo

### Tareas Obligatorias

#### 1. Seguridad de Credenciales
- [ ] **CRÍTICO**: Eliminar `GoogleService-Info.plist` del repositorio git
  - Ejecutar: `git rm --cached AudioCityPOC/GoogleService-Info.plist`
  - Agregar a `.gitignore`: `**/GoogleService-Info.plist`
  - Crear plantilla `GoogleService-Info.plist.template` con valores de ejemplo
  - Documentar en README cómo configurar credenciales localmente

- [ ] **CRÍTICO**: Rotar credenciales de Firebase
  - Crear nuevo proyecto Firebase o regenerar claves
  - Actualizar configuración en consola Firebase
  - Actualizar documentación de setup

- [ ] **CRÍTICO**: Crear archivo `.gitignore` completo
  ```
  # Firebase
  **/GoogleService-Info.plist
  firebase-credentials.json

  # Secrets
  .env
  .env.local
  Secrets.plist

  # Snapshots/Screenshots
  snapshots/
  screenshots/

  # Xcode
  DerivedData/
  *.xcuserstate
  xcuserdata/

  # Build
  build/

  # macOS
  .DS_Store
  ```

#### 2. Limpieza de Repositorio
- [ ] Eliminar carpeta `snapshots/` (12.5 MB) del repositorio
  - Ejecutar: `git rm -r snapshots/`
  - Mover capturas a documentación externa o wiki

- [ ] Limpiar historial de git de archivos sensibles
  - Usar `git filter-branch` o BFG Repo-Cleaner
  - **ADVERTENCIA**: Esto reescribe el historial, coordinar con el equipo

#### 3. Configuración de Entornos
- [ ] Crear configuración por ambiente
  - Development
  - Staging
  - Production

- [ ] Implementar variables de entorno
  - Usar Xcode Configuration files (.xcconfig)
  - Separar secretos del código

**Estimación:** 2-3 días
**Responsable:** Lead Developer + DevOps
**Entregables:** Repositorio limpio, credenciales seguras, documentación actualizada

---

## 📋 FASE 1: REFACTORING TÉCNICO (Semanas 2-4)
**Prioridad:** ALTA - Base técnica sólida para desarrollo futuro

### 1.1 Sistema de Logging (Semana 2)

#### Objetivos
- Reemplazar 170+ `print()` statements con logging estructurado
- Implementar niveles de log (debug, info, warning, error)
- Facilitar debugging en producción

#### Tareas
- [ ] Crear `LoggingService.swift`
  ```swift
  import os.log

  enum LogLevel {
      case debug, info, warning, error
  }

  class LoggingService {
      static let shared = LoggingService()
      private let logger = Logger(subsystem: "com.audiocity", category: "app")

      func log(_ message: String, level: LogLevel, file: String = #file, function: String = #function) {
          // Implementación
      }
  }
  ```

- [ ] Migrar print statements por servicio:
  - `LocationService.swift` (26 prints)
  - `AudioService.swift` (27 prints)
  - `RouteViewModel.swift` (23 prints)
  - `PointsService.swift` (16 prints)
  - Resto de servicios y ViewModels

- [ ] Configurar niveles de log por ambiente
  - Development: debug
  - Staging: info
  - Production: warning/error

**Estimación:** 3 días
**Impacto:** Alto - Debugging más eficiente

### 1.2 Inyección de Dependencias (Semana 2-3)

#### Objetivos
- Eliminar singletons donde sea posible
- Centralizar creación de dependencias
- Mejorar testabilidad

#### Tareas
- [ ] Refactorizar `DependencyContainer`
  ```swift
  class DependencyContainer {
      // Servicios shared (estado global real)
      lazy var firebaseService: FirebaseServiceProtocol = FirebaseService()
      lazy var locationService: LocationServiceProtocol = LocationService()

      // Servicios stateless (pueden ser instanciados)
      func makeAudioService() -> AudioServiceProtocol {
          return AudioService()
      }
  }
  ```

- [ ] Eliminar singletons innecesarios:
  - `AudioService.shared` → Inyectar en ViewModels
  - `NotificationService.shared` → Inyectar
  - `ImageCacheService.shared` → OK mantener (caché global)

- [ ] Actualizar ViewModels para inyección:
  ```swift
  class RouteViewModel: ObservableObject {
      private let container: DependencyContainer

      init(container: DependencyContainer = .shared) {
          self.container = container
      }
  }
  ```

- [ ] Actualizar Views:
  ```swift
  @StateObject private var viewModel: RouteViewModel

  init(container: DependencyContainer = .shared) {
      _viewModel = StateObject(wrappedValue: RouteViewModel(container: container))
  }
  ```

**Estimación:** 4 días
**Impacto:** Alto - Mejora testabilidad y mantenibilidad

### 1.3 Limpieza de Código (Semana 3)

#### Tareas
- [ ] Eliminar duplicación de `RouteActivityAttributes.swift`
  - Mantener solo en target principal
  - Usar target membership para compartir con Widget Extension

- [ ] Limpiar headers duplicados en archivos:
  - `Route.swift`
  - `LocationService.swift`
  - `AudioService.swift`

- [ ] Renombrar archivos confusos:
  - `MapView.swift` → `RouteMapView.swift`

- [ ] Extraer constantes a archivo centralizado:
  ```swift
  enum AppConstants {
      enum Geofencing {
          static let prefix = "audiocity_stop_"
          static let wakeUpRadiusMeters: CLLocationDistance = 100
          static let proximityRadiusMeters: CLLocationDistance = 5
      }

      enum Cache {
          static let maxMemoryImageCount = 100
          static let maxMemorySizeMB = 50
      }
  }
  ```

**Estimación:** 2 días
**Impacto:** Medio - Código más limpio

### 1.4 Modularización de Vistas (Semana 4)

#### Objetivos
- Dividir vistas grandes en componentes reutilizables
- Mejorar legibilidad y mantenibilidad

#### Tareas
- [ ] Refactorizar `RoutesListView.swift` (1016 líneas)
  - Extraer: `MyTripsSection`, `FavoriteRoutesSection`, `TopRoutesSection`
  - Crear: `RoutesListViewModel` para lógica de negocio

- [ ] Refactorizar `MapExploreView.swift` (927 líneas)
  - Extraer: `SearchBar`, `StopDetailCard`, `ActiveRouteOverlay`

- [ ] Refactorizar `ActiveRouteView.swift` (855 líneas)
  - Extraer: `RouteProgressHeader`, `StopsList`, `MapSection`

- [ ] Refactorizar `TripOnboardingView.swift` (756 líneas)
  - Extraer: `DestinationStep`, `RoutesStep`, `OptionsStep`, `SummaryStep`

**Estimación:** 5 días
**Impacto:** Alto - Código más mantenible

**Resumen Fase 1:**
**Duración:** 3 semanas
**Esfuerzo:** 1 developer full-time

---

## 🎨 FASE 2: MEJORAS UX/UI (Semanas 5-6)
**Prioridad:** MEDIA-ALTA - Pulir experiencia de usuario

### 2.1 Imágenes de Rutas

#### Tareas
- [ ] Definir estrategia de imágenes:
  - Tamaño recomendado: 1200x630px
  - Formato: WebP o JPEG optimizado
  - CDN para hosting (Firebase Storage)

- [ ] Crear placeholders variados por categoría:
  - Histórico: Gradiente azul
  - Gastronómico: Gradiente rojo
  - Natural: Gradiente verde
  - Cultural: Gradiente morado

- [ ] Implementar sistema de fallback mejorado
- [ ] Añadir imágenes a rutas existentes:
  - Zamora Románica
  - Valladolid Histórico
  - Canal y Chamberí

### 2.2 Mejoras de Diseño

- [ ] Implementar skeleton loaders para carga
- [ ] Mejorar animaciones de transición entre pantallas
- [ ] Añadir haptic feedback en acciones clave
- [ ] Optimizar rendimiento de scroll en listas largas
- [ ] Implementar pull-to-refresh en listas

### 2.3 Accesibilidad

- [ ] Añadir VoiceOver labels
- [ ] Verificar contraste de colores (WCAG AA)
- [ ] Implementar Dynamic Type support
- [ ] Añadir reducción de movimiento

**Estimación:** 2 semanas
**Impacto:** Alto - Experiencia de usuario profesional

---

## 🧪 FASE 3: TESTING (Semanas 7-8)
**Prioridad:** ALTA - Garantizar calidad

### 3.1 Unit Tests

#### Cobertura objetivo: 70%

**Prioridad alta:**
- [ ] Services (todos)
  - `LocationService` - geofencing, tracking
  - `AudioService` - cola de reproducción
  - `FirebaseService` - CRUD operaciones
  - `PointsService` - cálculo de puntos
  - `HistoryService` - gestión de historial

- [ ] ViewModels
  - `RouteViewModel` - lógica de rutas
  - `ExploreViewModel` - estado del mapa

- [ ] Repositories
  - `TripRepository`
  - `HistoryRepository`
  - `PointsRepository`

**Tareas:**
- [ ] Configurar target de Tests
- [ ] Implementar mocks para Firebase
- [ ] Crear helpers de testing
- [ ] Escribir tests para cada servicio
- [ ] Configurar CI/CD para ejecutar tests

### 3.2 UI Tests

- [ ] Flujos críticos:
  - Onboarding de viaje
  - Inicio de ruta
  - Navegación entre tabs
  - Creación de ruta personalizada

- [ ] Casos edge:
  - Sin conexión a internet
  - Permisos de ubicación denegados
  - Sin rutas disponibles

### 3.3 Integration Tests

- [ ] Firebase integration
- [ ] Location services
- [ ] Audio playback
- [ ] Live Activities

**Estimación:** 2 semanas
**Esfuerzo:** 1 developer + 1 QA

---

## 🚀 FASE 4: FUNCIONALIDADES MVP (Semanas 9-11)
**Prioridad:** ALTA - Features esenciales para lanzamiento

### 4.1 Sistema de Autenticación

#### Objetivos
- Usuarios pueden crear cuenta
- Sincronizar datos entre dispositivos
- Gestionar perfil

#### Tareas
- [ ] Implementar Firebase Auth
  - Email/Password
  - Sign in with Apple (obligatorio App Store)
  - Google Sign-In (opcional)

- [ ] Crear flujo de onboarding
  - Bienvenida
  - Permisos (ubicación, notificaciones)
  - Login/Registro

- [ ] Sincronizar datos del usuario:
  - Viajes planificados
  - Rutas favoritas
  - Historial de rutas
  - Puntos y nivel
  - Rutas creadas

- [ ] Implementar perfil de usuario:
  - Avatar
  - Nombre y bio
  - Estadísticas
  - Configuración de privacidad

**Estimación:** 1 semana

### 4.2 Sistema de Sincronización

#### Objetivos
- Datos persistentes en la nube
- Sincronización offline-first
- Resolución de conflictos

#### Tareas
- [ ] Migrar de UserDefaults a Firestore:
  - Trips → colección `users/{userId}/trips`
  - Favorites → `users/{userId}/favorites`
  - History → `users/{userId}/history`
  - Points → `users/{userId}/profile`

- [ ] Implementar sincronización:
  ```swift
  class SyncService {
      func syncUserData() async throws
      func syncTrips() async throws
      func syncFavorites() async throws
      func syncHistory() async throws
  }
  ```

- [ ] Manejar conflictos:
  - Last-write-wins para datos simples
  - Merge strategy para listas (favoritos, historial)

- [ ] Implementar caché local + sincronización:
  - Room/Core Data para caché local
  - Sync en background cuando hay conexión
  - Indicador de estado de sync

**Estimación:** 1 semana

### 4.3 Audio Pregrabado

#### Objetivos
- Opción de audio profesional vs TTS
- Mejor calidad de narración

#### Tareas
- [ ] Diseñar modelo de datos:
  ```swift
  struct Stop {
      let audioUrl: String?  // URL de audio pregrabado
      let scriptEs: String   // Fallback TTS
      let audioType: AudioType  // .prerecorded, .tts
  }
  ```

- [ ] Implementar descarga y caché de audio:
  - Descargar al guardar ruta offline
  - Caché en disco
  - Reproducción desde caché

- [ ] Actualizar `AudioService`:
  - Detectar tipo de audio
  - Priorizar pregrabado sobre TTS
  - Fallback a TTS si falla

- [ ] Herramientas de gestión:
  - Script para subir audios a Firebase Storage
  - Validación de formato (MP3, duración)

**Estimación:** 1 semana

### 4.4 Compartir Rutas

#### Objetivos
- Usuarios pueden compartir rutas creadas
- Deep linking para abrir rutas compartidas

#### Tareas
- [ ] Implementar deep links:
  - `audiocity://route/{routeId}`
  - Universal Links para `audiocity.app/routes/{routeId}`

- [ ] Funcionalidad de compartir:
  - Botón "Compartir" en detalle de ruta
  - Share sheet nativo de iOS
  - Generar link con preview (metadata)

- [ ] Preview de rutas compartidas:
  - Open Graph tags para web
  - Rich preview en iMessage

- [ ] Analítica:
  - Trackear rutas compartidas
  - Medir conversión

**Estimación:** 3 días

**Resumen Fase 4:**
**Duración:** 3 semanas
**Features:** Auth, Sync, Audio profesional, Compartir

---

## 📱 FASE 5: DESARROLLO ANDROID (Semanas 12-20)
**Prioridad:** ALTA - Paridad de plataformas

### Arquitectura Android
- **UI:** Jetpack Compose
- **Arquitectura:** MVVM + Flow (equivalente a Combine)
- **DI:** Hilt/Dagger
- **Backend:** Firebase (mismo que iOS)
- **Maps:** Google Maps SDK
- **Location:** Fused Location Provider
- **Persistencia:** Room + DataStore

### Fases de desarrollo

#### 5.1 Setup y Arquitectura (Semana 12)
- [ ] Crear proyecto Android con Jetpack Compose
- [ ] Configurar Firebase
- [ ] Implementar design system Android
  - Equivalente a ACColors, ACTypography
  - Material 3 theming

#### 5.2 Features Core (Semanas 13-15)
- [ ] Exploración de rutas
- [ ] Detalle de ruta
- [ ] Inicio de ruta con geofencing
- [ ] Reproducción de audio (TTS)
- [ ] Mapa con seguimiento

#### 5.3 Features Avanzadas (Semanas 16-18)
- [ ] Planificación de viajes
- [ ] Rutas favoritas
- [ ] Creación de rutas (UGC)
- [ ] Historial
- [ ] Sistema de puntos

#### 5.4 Notificaciones Persistentes (Semana 19)
- [ ] Implementar equivalente a Live Activity
  - Foreground Service con notificación
  - Actualización en tiempo real de distancia
  - Colores según proximidad

#### 5.5 Testing y Pulido (Semana 20)
- [ ] Unit tests
- [ ] UI tests con Compose
- [ ] Optimización de rendimiento
- [ ] Testing en múltiples dispositivos

**Estimación:** 9 semanas
**Esfuerzo:** 1-2 Android developers

---

## 🔧 FASE 6: OPTIMIZACIÓN Y ESCALABILIDAD (Semanas 21-23)

### 6.1 Performance

#### Objetivos
- App launch < 2s
- Scroll fluido (60 fps)
- Uso de memoria optimizado

#### Tareas
- [ ] Profiling con Instruments:
  - Time Profiler
  - Leaks
  - Allocations

- [ ] Optimizaciones:
  - Lazy loading de imágenes
  - Paginación en listas largas
  - Reducir tamaño de imágenes
  - Optimizar queries Firebase

- [ ] Caché strategy:
  - Imágenes en memoria + disco
  - Datos de rutas
  - TTL apropiado

### 6.2 Backend Improvements

- [ ] Implementar Cloud Functions:
  ```javascript
  // Calcular popularidad de rutas
  exports.calculateRoutePopularity = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
      // Lógica
    });

  // Generar thumbnails de imágenes
  exports.generateThumbnails = functions.storage
    .object()
    .onFinalize(async (object) => {
      // Resize imagen
    });
  ```

- [ ] Configurar índices Firestore:
  - Queries complejas optimizadas
  - Composite indexes

- [ ] Implementar rate limiting:
  - Prevenir abuso de API
  - Limitar creación de rutas

### 6.3 Monitoring y Analytics

- [ ] Implementar Crashlytics:
  - Reporte automático de crashes
  - Custom logs

- [ ] Google Analytics / Firebase Analytics:
  - Screen views
  - Eventos de usuario
  - Conversión de funnel

- [ ] Custom metrics:
  - Tiempo promedio de ruta
  - Rutas más populares
  - Tasa de finalización de rutas

**Estimación:** 3 semanas

---

## 🎯 FASE 7: PRE-LANZAMIENTO (Semanas 24-26)

### 7.1 Beta Testing

#### Objetivos
- Validar con usuarios reales
- Detectar bugs críticos
- Recoger feedback

#### Tareas
- [ ] TestFlight para iOS:
  - Invitar 50-100 beta testers
  - Crear grupos de testing
  - Feedback forms

- [ ] Google Play Beta para Android:
  - Closed testing track
  - Mismo grupo de testers

- [ ] Iteración basada en feedback:
  - Priorizar bugs críticos
  - Implementar mejoras UX
  - Ajustar onboarding

**Duración:** 2 semanas

### 7.2 App Store Preparation

#### iOS App Store
- [ ] Screenshots (6.7", 6.5", 5.5")
- [ ] Preview videos
- [ ] App description (ES, EN)
- [ ] Keywords optimization
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Support URL

#### Google Play Store
- [ ] Screenshots
- [ ] Feature graphic
- [ ] Description (ES, EN)
- [ ] Privacy policy
- [ ] Data safety section

#### Legal
- [ ] Política de privacidad
- [ ] Términos y condiciones
- [ ] Licencias de terceros
- [ ] GDPR compliance

**Duración:** 1 semana

### 7.3 Infraestructura de Producción

- [ ] Firebase en modo producción:
  - Reglas de seguridad Firestore
  - Storage rules
  - Limits y quotas configurados

- [ ] CDN para assets:
  - Imágenes optimizadas
  - Audio files

- [ ] Monitoring:
  - Alertas de errores
  - Dashboard de métricas

- [ ] Backup strategy:
  - Backup diario de Firestore
  - Disaster recovery plan

**Duración:** 3 días

---

## 📊 CRONOGRAMA GENERAL

| Fase | Semanas | Esfuerzo | Entregables |
|------|---------|----------|-------------|
| 0. Seguridad | 1 | 1 dev | Repo limpio, secretos seguros |
| 1. Refactoring | 3 | 1 dev | Código limpio, DI, logging |
| 2. UX/UI | 2 | 1 dev + 1 designer | Imágenes, animaciones, a11y |
| 3. Testing | 2 | 1 dev + 1 QA | Tests automatizados, CI/CD |
| 4. Features MVP | 3 | 2 devs | Auth, sync, audio, compartir |
| 5. Android | 9 | 2 Android devs | App Android completa |
| 6. Optimización | 3 | 1 dev + 1 backend | Performance, monitoring |
| 7. Pre-launch | 3 | 1 dev + 1 PM | Beta, App Store, infra |
| **TOTAL** | **26 semanas** | **~6 meses** | **MVP en producción** |

---

## 👥 EQUIPO RECOMENDADO

### Fase 0-4 (iOS MVP)
- 1 iOS Developer Senior (lead)
- 1 iOS Developer Mid
- 1 Backend Developer (Firebase, Cloud Functions)
- 1 UI/UX Designer
- 1 QA Engineer (medio tiempo)
- 1 Product Manager (medio tiempo)

### Fase 5 (Android)
- Mantener equipo iOS (mantenimiento)
- 2 Android Developers
- Compartir: Backend, Designer, QA, PM

### Fase 6-7 (Optimización y lanzamiento)
- Full team
- Agregar: Marketing Manager

---

## 💰 ESTIMACIÓN DE COSTOS (aproximada)

### Desarrollo
- iOS Devs (6 meses): ~€60-80k
- Android Devs (3 meses): ~€30-40k
- Backend Dev (6 meses): ~€40-50k
- UI/UX Designer (6 meses): ~€35-45k
- QA Engineer (4 meses): ~€20-25k
- PM (6 meses): ~€30-35k

**Total desarrollo:** ~€215-275k

### Infraestructura y Servicios
- Firebase (Blaze plan): ~€200-500/mes
- Apple Developer Program: €99/año
- Google Play Developer: €25 (único)
- Dominio + Hosting web: ~€100/año
- CDN: ~€50-100/mes
- Tools (analytics, monitoring): ~€100/mes

**Total año 1:** ~€3-5k

### Marketing (post-lanzamiento)
- ASO optimization: €2-3k
- Paid ads (Google, Meta): €5-10k/mes
- Influencer marketing: €3-5k
- PR y comunicación: €2-3k

---

## 🎯 KPIs Y MÉTRICAS DE ÉXITO

### Pre-lanzamiento
- ✅ 0 bugs críticos en beta
- ✅ >90% satisfacción de beta testers
- ✅ >70% code coverage en tests
- ✅ App launch < 2 segundos
- ✅ Crash rate < 0.5%

### Post-lanzamiento (3 meses)
- 📈 10,000 descargas
- 📈 5,000 usuarios activos mensuales (MAU)
- 📈 Retención día 1: >40%
- 📈 Retención día 7: >20%
- 📈 Rating App Store: >4.5 ⭐
- 📈 100 rutas activas en la plataforma
- 📈 1,000 rutas completadas

### Crecimiento (12 meses)
- 📈 100,000 descargas
- 📈 30,000 MAU
- 📈 5+ ciudades con >50 rutas
- 📈 Revenue: modelo freemium operativo
- 📈 Comunidad: 500 creadores de rutas

---

## 🔄 ESTRATEGIA DE LANZAMIENTO

### Soft Launch (Mes 1)
- Lanzar en España solo
- Marketing orgánico (redes sociales, PR)
- Foco: Madrid, Barcelona, Valencia
- Objetivo: 1,000 early adopters

### Expansión Nacional (Mes 2-3)
- Resto de España
- Partnerships con oficinas de turismo
- Colaboraciones con guías turísticos

### Internacionalización (Mes 6+)
- Portugal, Francia, Italia
- Localización completa
- Marketing regional

---

## 📝 RIESGOS Y MITIGACIÓN

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Retrasos en desarrollo | Media | Alto | Buffer de 2 semanas, sprints ágiles |
| Bugs críticos en producción | Media | Crítico | Testing exhaustivo, beta extensa |
| Bajo engagement inicial | Alta | Medio | Marketing pre-lanzamiento, early access |
| Problemas de escalabilidad | Baja | Alto | Load testing, arquitectura escalable |
| Costos Firebase excesivos | Media | Medio | Monitoring de quotas, optimización |
| Competencia fuerte | Alta | Medio | Diferenciación (UGC, gamificación) |
| Problemas legales (GDPR) | Baja | Alto | Legal review, compliance desde día 1 |

---

## 🚀 PRÓXIMOS PASOS INMEDIATOS

### Esta semana:
1. ✅ Revisión de auditoría con equipo
2. ⏳ Aprobación de roadmap
3. ⏳ Setup de proyecto en herramientas:
   - Jira/Linear para task tracking
   - Slack para comunicación
   - GitHub Projects para sprints
4. ⏳ Iniciar Fase 0: Seguridad

### Próxima semana:
1. Sprint Planning Fase 1
2. Contratar equipo faltante
3. Setup de CI/CD
4. Kickoff oficial del proyecto

---

**Documento creado:** Diciembre 2025
**Próxima revisión:** Enero 2026
**Owner:** Product Manager
**Stakeholders:** CTO, Lead iOS Dev, Lead Android Dev
