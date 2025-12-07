//
//  RouteViewModel.swift
//  AudioCityPOC
//
//  ViewModel principal que orquesta todos los servicios
//

import Foundation
import CoreLocation
import Combine

class RouteViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var availableRoutes: [Route] = []  // Lista de rutas disponibles
    @Published var currentRoute: Route?
    @Published var stops: [Stop] = []
    @Published var isRouteActive = false
    @Published var currentStop: Stop?
    @Published var isLoading = false
    @Published var isLoadingRoutes = false  // Cargando lista de rutas
    @Published var errorMessage: String?
    @Published var visitedStopsCount = 0

    // MARK: - Services
    let locationService = LocationService()
    let audioService = AudioService()
    let geofenceService = GeofenceService()
    let firebaseService = FirebaseService()
    let notificationService = NotificationService.shared

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
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

    /// Iniciar ruta
    func startRoute() {
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

        // Solicitar permisos de notificaciones
        notificationService.requestAuthorization()

        // Iniciar servicios
        locationService.startTracking()
        geofenceService.setupGeofences(for: stops, locationService: locationService)

        // Registrar geofences nativos para wake-up (funciona con app suspendida)
        let stopsForGeofence = stops.map { (id: $0.id, latitude: $0.latitude, longitude: $0.longitude) }
        locationService.registerNativeGeofences(stops: stopsForGeofence)

        isRouteActive = true
        errorMessage = nil

        print("🚀 RouteViewModel: Ruta iniciada - \(route.name)")
        if locationService.isGeofencingAvailable() {
            print("📍 Geofences nativos disponibles y registrados")
        } else {
            print("⚠️ Geofences nativos no disponibles en este dispositivo")
        }
    }

    /// Detener ruta
    func endRoute() {
        locationService.stopTracking()
        locationService.clearNativeGeofences()  // Limpiar geofences nativos
        geofenceService.clearGeofences()
        audioService.stopAndClear()  // Detener y limpiar cola
        notificationService.cancelAllPendingNotifications()  // Cancelar notificaciones

        isRouteActive = false
        currentStop = nil
        visitedStopsCount = 0

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

        // Si completamos todas las paradas
        if visitedStopsCount == stops.count {
            print("🎉 RouteViewModel: ¡Ruta completada!")
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
