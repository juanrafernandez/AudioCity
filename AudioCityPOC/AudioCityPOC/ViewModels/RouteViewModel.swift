//
//  RouteViewModel.swift
//  AudioCityPOC
//
//  ViewModel principal que orquesta todos los servicios
//  Refactorizado para delegar responsabilidades a servicios especializados
//

import Foundation
import CoreLocation
import Combine
import MapKit

class RouteViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var availableRoutes: [Route] = []  // Lista de rutas disponibles
    @Published var currentRoute: Route?
    @Published var stops: [Stop] = []
    @Published var isRouteActive = false
    @Published var isRouteReady = false  // True cuando la ruta está calculada y lista para mostrar
    @Published var currentStop: Stop?
    @Published var isLoading = false
    @Published var isLoadingRoutes = false  // Cargando lista de rutas
    @Published var errorMessage: String?
    @Published var visitedStopsCount = 0

    // MARK: - Route Calculator (datos precalculados para ActiveRouteView)
    @Published var routePolylines: [MKPolyline] = []
    @Published var routeDistances: [CLLocationDistance] = []
    @Published var distanceToNextStop: CLLocationDistance = 0

    /// Distancia total de la ruta (suma de todos los segmentos excepto usuario→primera parada)
    var totalRouteDistance: CLLocationDistance {
        guard routeDistances.count > 1 else { return routeDistances.first ?? 0 }
        return routeDistances.dropFirst().reduce(0, +)
    }

    /// Distancia total incluyendo desde la posición del usuario
    var totalDistanceFromUser: CLLocationDistance {
        return routeDistances.reduce(0, +)
    }

    // MARK: - Services (Inyectados)
    let locationService: LocationService
    let audioService: AudioService
    let geofenceService: GeofenceService
    let firebaseService: FirebaseService
    let notificationService: NotificationService

    // MARK: - Specialized Services
    private let routeCalculationService = RouteCalculationService()
    private let routeOptimizationService = RouteOptimizationService()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Inicializador con inyección de dependencias
    /// - Parameters:
    ///   - locationService: Servicio de ubicación
    ///   - audioService: Servicio de audio
    ///   - firebaseService: Servicio de datos
    ///   - geofenceService: Servicio de geofencing
    ///   - notificationService: Servicio de notificaciones
    init(
        locationService: LocationService = LocationService(),
        audioService: AudioService = AudioService(),
        firebaseService: FirebaseService = FirebaseService(),
        geofenceService: GeofenceService = GeofenceService(),
        notificationService: NotificationService = NotificationService.shared
    ) {
        self.locationService = locationService
        self.audioService = audioService
        self.firebaseService = firebaseService
        self.geofenceService = geofenceService
        self.notificationService = notificationService
        setupObservers()
    }

    // MARK: - Setup

    /// Configurar observadores de cambios
    private func setupObservers() {
        // Observar cambios en paradas activadas
        geofenceService.$triggeredStop
            .compactMap { $0 }
            .sink { [weak self] stop in
                self?.handleStopTriggered(stop)
            }
            .store(in: &cancellables)

        // Observar estado de audio
        audioService.$isPlaying
            .sink { [weak self] isPlaying in
                print("🎵 Audio playing: \(isPlaying)")
            }
            .store(in: &cancellables)

        // Observar item actual en reproducción para actualizar currentStop
        audioService.$currentQueueItem
            .compactMap { $0 }
            .sink { [weak self] queueItem in
                guard let self = self else { return }
                // Buscar la parada correspondiente y actualizar currentStop
                if let stop = self.stops.first(where: { $0.id == queueItem.stopId }) {
                    self.currentStop = stop
                    print("🎵 Reproduciendo ahora: \(stop.name)")
                }
            }
            .store(in: &cancellables)

        // Observar ubicación del usuario
        locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateNearestStop(for: location)
            }
            .store(in: &cancellables)

        // Observar acciones de notificación
        notificationService.$lastAction
            .compactMap { $0 }
            .sink { [weak self] action in
                self?.handleNotificationAction(action)
            }
            .store(in: &cancellables)
    }

    /// Manejar acción del usuario desde notificación
    private func handleNotificationAction(_ action: NotificationService.NotificationAction) {
        guard let stopId = notificationService.lastActionStopId else { return }

        switch action {
        case .listen:
            // El audio ya se está reproduciendo, no hacer nada
            print("🎵 RouteViewModel: Usuario confirmó escuchar - \(stopId)")

        case .skip:
            // Saltar/detener el audio de esta parada
            print("⏭️ RouteViewModel: Usuario saltó parada - \(stopId)")
            audioService.stop()
        }
    }

    // MARK: - Public Methods

    /// Cargar todas las rutas disponibles desde Firebase
    func loadAvailableRoutes() {
        isLoadingRoutes = true
        errorMessage = nil

        Task {
            do {
                let routes = try await firebaseService.fetchAllRoutes()

                await MainActor.run {
                    self.availableRoutes = routes
                    self.isLoadingRoutes = false
                    print("✅ RouteViewModel: \(routes.count) rutas disponibles")
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando rutas: \(error.localizedDescription)"
                    self.isLoadingRoutes = false
                    print("❌ RouteViewModel: Error cargando rutas - \(error.localizedDescription)")
                }
            }
        }
    }

    /// Seleccionar y cargar una ruta específica
    func selectRoute(_ route: Route) {
        isLoading = true
        errorMessage = nil
        currentRoute = route

        Task {
            do {
                let fetchedStops = try await firebaseService.fetchStops(for: route.id)

                await MainActor.run {
                    self.stops = fetchedStops
                    self.isLoading = false

                    print("✅ RouteViewModel: Ruta seleccionada - \(route.name)")
                    print("✅ RouteViewModel: \(fetchedStops.count) paradas cargadas")
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando paradas: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ RouteViewModel: Error - \(error.localizedDescription)")
                }
            }
        }
    }

    /// Volver a la lista de rutas
    func backToRoutesList() {
        if isRouteActive {
            endRoute()
        }
        currentRoute = nil
        stops = []
        errorMessage = nil
    }

    /// Solicitar ubicación actual (para usar antes de verificar optimización)
    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // Si ya tenemos ubicación reciente, usarla
        if let location = locationService.userLocation {
            completion(location)
            return
        }

        // Solicitar una ubicación única
        locationService.requestSingleLocation { location in
            completion(location)
        }
    }

    /// Verificar si conviene optimizar la ruta (el punto más cercano NO es el primero)
    func shouldSuggestRouteOptimization(userLocation: CLLocation) -> Bool {
        return routeOptimizationService.shouldSuggestOptimization(stops: stops, userLocation: userLocation)
    }

    /// Obtener info del punto más cercano para mostrar en el diálogo
    func getNearestStopInfo(userLocation: CLLocation) -> (name: String, distance: Int, originalOrder: Int)? {
        return routeOptimizationService.getNearestStopInfo(stops: stops, userLocation: userLocation)
    }

    /// Optimizar ruta empezando por el punto más cercano (algoritmo nearest neighbor)
    func optimizeRouteFromCurrentLocation() {
        guard let userLocation = locationService.userLocation else {
            print("⚠️ No hay ubicación del usuario para optimizar")
            return
        }

        let result = routeOptimizationService.optimizeRoute(stops: stops, startLocation: userLocation)
        routeOptimizationService.applyOptimization(to: &stops, from: result)
    }

    /// Iniciar ruta (con opción de optimizar)
    func startRoute(optimized: Bool = false) {
        guard let route = currentRoute, !stops.isEmpty else {
            errorMessage = "No hay ruta cargada"
            return
        }

        // Verificar permisos de ubicación
        guard locationService.authorizationStatus == .authorizedAlways ||
              locationService.authorizationStatus == .authorizedWhenInUse else {
            locationService.requestLocationPermission()
            errorMessage = "Se necesitan permisos de ubicación para continuar"
            return
        }

        // Optimizar ruta si se solicitó
        if optimized {
            optimizeRouteFromCurrentLocation()
        }

        // Solicitar permisos de notificaciones
        notificationService.requestAuthorization()

        // Iniciar servicios
        locationService.startTracking()
        geofenceService.setupGeofences(for: stops, locationService: locationService)

        // Registrar geofences nativos para wake-up (funciona con app suspendida)
        let stopsForGeofence = stops.map { (id: $0.id, latitude: $0.latitude, longitude: $0.longitude) }
        locationService.registerNativeGeofences(stops: stopsForGeofence)

        isRouteActive = true
        isRouteReady = false
        errorMessage = nil

        print("🚀 RouteViewModel: Ruta iniciada\(optimized ? " (optimizada)" : "") - \(route.name)")
        if locationService.isGeofencingAvailable() {
            print("📍 Geofences nativos disponibles y registrados")
        } else {
            print("⚠️ Geofences nativos no disponibles en este dispositivo")
        }

        // Calcular la ruta (Live Activity se inicia cuando termina el cálculo)
        calculateWalkingRoute()
    }

    // MARK: - Live Activity

    /// Iniciar Live Activity en Dynamic Island
    private func startLiveActivity() {
        guard let route = currentRoute else { return }

        // Obtener próxima parada
        let nextStop = stops.filter { !$0.hasBeenVisited }.sorted { $0.order < $1.order }.first
        guard let next = nextStop else { return }

        LiveActivityServiceWrapper.shared.startActivity(
            routeId: route.id,
            routeName: route.name,
            routeCity: route.city,
            nextStopName: next.name,
            nextStopOrder: next.order,
            distanceToNextStop: distanceToNextStop,
            totalStops: stops.count
        )
    }

    /// Actualizar Live Activity con nueva información
    func updateLiveActivity() {
        // Obtener próxima parada
        let nextStop = stops.filter { !$0.hasBeenVisited }.sorted { $0.order < $1.order }.first

        guard let next = nextStop else {
            // No hay más paradas, finalizar Live Activity
            LiveActivityServiceWrapper.shared.endActivity(showFinalState: true)
            return
        }

        LiveActivityServiceWrapper.shared.updateActivity(
            distanceToNextStop: distanceToNextStop,
            nextStopName: next.name,
            nextStopOrder: next.order,
            visitedStops: getVisitedCount(),
            totalStops: stops.count,
            isPlaying: audioService.isPlaying
        )
    }

    // MARK: - Route Calculation

    /// Calcular rutas caminando entre cada par de puntos consecutivos
    private func calculateWalkingRoute() {
        let stopCoordinates = stops
            .sorted(by: { $0.order < $1.order })
            .map { $0.coordinate }

        guard !stopCoordinates.isEmpty else {
            isRouteReady = true
            return
        }

        // Usar el servicio de cálculo de rutas
        routeCalculationService.calculateRoute(
            from: locationService.userLocation?.coordinate,
            through: stopCoordinates
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let calcResult):
                self.routePolylines = calcResult.polylines
                self.routeDistances = calcResult.distances
                self.distanceToNextStop = calcResult.distanceToNext
                self.isRouteReady = true
                print("✅ RouteViewModel: Ruta lista para mostrar, distancia: \(Int(calcResult.distanceToNext))m")

                // Iniciar Live Activity DESPUÉS de tener la distancia calculada
                self.startLiveActivity()

            case .failure(let error):
                self.errorMessage = "Error calculando ruta: \(error.localizedDescription)"
                self.isRouteReady = true // Marcar como lista aunque falle
                print("❌ RouteViewModel: Error calculando ruta - \(error.localizedDescription)")

                // Iniciar Live Activity aunque falle (mostrará 0m)
                self.startLiveActivity()
            }
        }
    }

    /// Actualiza solo el primer segmento (usuario → próxima parada) cuando el usuario se mueve
    func updateUserSegment(from userLocation: CLLocationCoordinate2D, to nextStop: CLLocationCoordinate2D) {
        routeCalculationService.calculateSegment(from: userLocation, to: nextStop) { [weak self] result in
            guard let self = self, !self.routePolylines.isEmpty else { return }

            switch result {
            case .success(let (polyline, distance)):
                self.routePolylines[0] = polyline
                self.routeDistances[0] = distance
                self.distanceToNextStop = distance
                print("📍 Distancia actualizada: \(Int(distance))m caminando")

                // Actualizar Live Activity con la nueva distancia
                self.updateLiveActivity()

            case .failure:
                // Fallback: mantener valores actuales
                break
            }
        }
    }

    /// Obtiene la distancia formateada de un segmento específico
    func formattedSegmentDistance(at index: Int) -> String? {
        guard index < routeDistances.count else { return nil }
        let distance = routeDistances[index]
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    /// Detener ruta
    func endRoute() {
        locationService.stopTracking()
        locationService.clearNativeGeofences()  // Limpiar geofences nativos
        geofenceService.clearGeofences()
        audioService.stopAndClear()  // Detener y limpiar cola
        notificationService.cancelAllPendingNotifications()  // Cancelar notificaciones

        // Finalizar Live Activity
        LiveActivityServiceWrapper.shared.endActivity()

        isRouteActive = false
        isRouteReady = false
        currentStop = nil
        visitedStopsCount = 0

        // Limpiar datos de ruta calculada
        routePolylines = []
        routeDistances = []
        distanceToNextStop = 0

        // Resetear estado de visita de paradas
        for index in stops.indices {
            stops[index].hasBeenVisited = false
        }

        print("⏹️ RouteViewModel: Ruta finalizada")
    }

    /// Pausar audio
    func pauseAudio() {
        audioService.pause()
    }

    /// Reanudar audio
    func resumeAudio() {
        audioService.resume()
    }

    /// Detener audio
    func stopAudio() {
        audioService.stop()
    }

    /// Reproducir parada manualmente
    func playStop(_ stop: Stop) {
        currentStop = stop
        audioService.speak(text: stop.scriptEs, language: "es-ES")
    }

    /// Obtener progreso de la ruta (0.0 - 1.0)
    func getProgress() -> Double {
        guard !stops.isEmpty else { return 0 }
        let visited = stops.filter { $0.hasBeenVisited }.count
        return Double(visited) / Double(stops.count)
    }

    /// Obtener número de paradas visitadas
    func getVisitedCount() -> Int {
        return stops.filter { $0.hasBeenVisited }.count
    }

    // MARK: - Private Methods

    /// Manejar parada activada por geofencing
    private func handleStopTriggered(_ stop: Stop) {
        // Actualizar estado de la parada en el array
        if let index = stops.firstIndex(where: { $0.id == stop.id }) {
            stops[index].hasBeenVisited = true
        }

        // Actualizar parada actual (si no hay ninguna reproduciéndose)
        if currentStop == nil || !audioService.isPlaying {
            currentStop = stop
        }

        // Actualizar contador de visitadas
        visitedStopsCount = getVisitedCount()

        // Mostrar notificación local
        notificationService.showStopArrivalNotification(stop: stop)

        // Encolar audio para reproducción (en vez de reproducir directamente)
        audioService.enqueueStop(
            stopId: stop.id,
            stopName: stop.name,
            text: stop.scriptEs,
            order: stop.order
        )

        print("🎯 RouteViewModel: Parada activada y encolada - \(stop.name)")
        print("📊 Progreso: \(visitedStopsCount)/\(stops.count) paradas completadas")
        print("🔊 Cola de audio: \(audioService.getQueueCount()) pendientes")

        // Actualizar Live Activity con el nuevo progreso
        updateLiveActivity()

        // Si completamos todas las paradas
        if visitedStopsCount == stops.count {
            print("🎉 RouteViewModel: ¡Ruta completada!")
            // Finalizar Live Activity mostrando estado final
            LiveActivityServiceWrapper.shared.endActivity(showFinalState: true)
        }
    }

    /// Actualizar parada más cercana (para UI)
    private func updateNearestStop(for location: CLLocation) {
        guard !stops.isEmpty else { return }

        // Encontrar parada más cercana no visitada
        let unvisitedStops = stops.filter { !$0.hasBeenVisited }
        guard !unvisitedStops.isEmpty else { return }

        let nearest = unvisitedStops.min { stop1, stop2 in
            let distance1 = location.distance(from: stop1.location)
            let distance2 = location.distance(from: stop2.location)
            return distance1 < distance2
        }

        // No actualizar currentStop automáticamente, solo cuando se active por geofencing
        // Esto es solo para logging
        if let nearestStop = nearest {
            let distance = location.distance(from: nearestStop.location)
            if distance < 100 { // Menos de 100 metros
                print("📍 Cerca de: \(nearestStop.name) - \(Int(distance))m")
            }
        }
    }
}
