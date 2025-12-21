//
//  ActiveRouteViewModel.swift
//  AudioCityPOC
//
//  ViewModel orquestador para rutas activas
//  Coordina los managers especializados para gestionar una ruta en progreso
//

import Foundation
import CoreLocation
import Combine
import MapKit

/// ViewModel orquestador para rutas activas
/// Responsabilidad: coordinar el ciclo de vida de una ruta activa
final class ActiveRouteViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isRouteActive = false
    @Published private(set) var isRouteReady = false
    @Published private(set) var route: Route?
    @Published private(set) var stops: [Stop] = []
    @Published var errorMessage: String?

    // MARK: - Managers (Composición)

    let stopsState: RouteStopsState
    let navigationManager: RouteNavigationManager
    let liveActivityManager: LiveActivityManager
    private let progressManager: RouteProgressManager

    // MARK: - Dependencies

    private let locationService: LocationServiceProtocol
    private let geofenceService: GeofenceServiceProtocol
    private let historyService: HistoryServiceProtocol
    private let firebaseService: FirebaseServiceProtocol

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var currentHistoryId: String?
    private let activeRouteStateKey = "activeRouteState"

    // MARK: - Computed Properties (Delegados)

    var currentStop: Stop? { progressManager.currentStop }
    var visitedStopsCount: Int { progressManager.visitedStopsCount }
    var routePolylines: [MKPolyline] { navigationManager.routePolylines }
    var routeDistances: [CLLocationDistance] { navigationManager.routeDistances }
    var distanceToNextStop: CLLocationDistance { navigationManager.distanceToNextStop }
    var totalRouteDistance: CLLocationDistance { navigationManager.totalRouteDistance }

    // MARK: - Initialization

    init(
        locationService: LocationServiceProtocol,
        geofenceService: GeofenceServiceProtocol,
        historyService: HistoryServiceProtocol,
        audioService: AudioServiceProtocol,
        notificationService: NotificationServiceProtocol,
        firebaseService: FirebaseServiceProtocol,
        stopsState: RouteStopsState = RouteStopsState()
    ) {
        self.locationService = locationService
        self.geofenceService = geofenceService
        self.historyService = historyService
        self.firebaseService = firebaseService
        self.stopsState = stopsState

        // Inicializar managers
        self.navigationManager = RouteNavigationManager()
        self.liveActivityManager = LiveActivityManager(stopsState: stopsState)
        self.progressManager = RouteProgressManager(
            stopsState: stopsState,
            audioService: audioService,
            notificationService: notificationService
        )

        setupObservers()
    }

    deinit {
        cancellables.removeAll()
        Log("ActiveRouteViewModel deinit", level: .debug, category: .route)
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observar paradas activadas por geofencing
        geofenceService.triggeredStopId
            .compactMap { $0 }
            .sink { [weak self] stopId in
                guard let self = self,
                      let stop = self.stops.first(where: { $0.id == stopId }) else { return }
                self.handleStopTriggered(stop)
            }
            .store(in: &cancellables)

        // Observar ubicación del usuario para actualizar distancias
        locationService.userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Iniciar ruta
    func startRoute(_ route: Route, stops: [Stop], optimized: Bool = false) {
        guard !stops.isEmpty else {
            errorMessage = "No hay paradas en la ruta"
            return
        }

        // Verificar permisos de ubicación
        guard locationService.authorizationStatus == .authorizedAlways ||
              locationService.authorizationStatus == .authorizedWhenInUse else {
            locationService.requestLocationPermission()
            errorMessage = "Se necesitan permisos de ubicación para continuar"
            return
        }

        self.route = route
        self.stops = stops

        // Inicializar estado de paradas
        stopsState.initialize(with: stops)

        // Optimizar ruta si se solicitó
        if optimized, let userLocation = locationService.userLocation {
            navigationManager.optimizeRoute(stops: stops, userLocation: userLocation, stopsState: stopsState)
        }

        // Registrar en el historial
        let historyRecord = historyService.startRoute(
            routeId: route.id,
            routeName: route.name,
            routeCity: route.city,
            totalStops: stops.count
        )
        currentHistoryId = historyRecord.id

        // Iniciar servicios de ubicación
        locationService.enableHighAccuracyMode()
        locationService.startTracking()

        // Configurar geofences
        if let locationService = locationService as? LocationService,
           let geofenceService = geofenceService as? GeofenceService {
            geofenceService.setupGeofences(for: stops, locationService: locationService, stopsState: stopsState)
        }

        // Registrar geofences nativos
        let stopsForGeofence = stops.map { (id: $0.id, latitude: $0.latitude, longitude: $0.longitude) }
        locationService.registerNativeGeofences(stops: stopsForGeofence)

        isRouteActive = true
        isRouteReady = false
        errorMessage = nil

        // Guardar estado para persistencia
        saveActiveRouteState()

        Log("Ruta iniciada\(optimized ? " (optimizada)" : "") - \(route.name)", level: .success, category: .route)

        // Calcular la ruta (Live Activity se inicia cuando termina)
        calculateWalkingRoute()
    }

    /// Finalizar ruta
    func endRoute() {
        // Detener GPS
        locationService.stopTracking()
        locationService.disableHighAccuracyMode()
        locationService.clearNativeGeofences()
        geofenceService.clearGeofences()

        // Limpiar managers
        progressManager.reset()
        navigationManager.reset()
        liveActivityManager.endActivity()

        // Resetear estado
        isRouteActive = false
        isRouteReady = false
        route = nil
        stops = []
        currentHistoryId = nil
        stopsState.reset()

        // Limpiar estado guardado
        clearActiveRouteState()

        Log("Ruta finalizada", level: .info, category: .route)
    }

    /// Verificar si conviene optimizar la ruta
    func shouldSuggestOptimization(userLocation: CLLocation) -> Bool {
        return navigationManager.shouldSuggestOptimization(stops: stops, userLocation: userLocation)
    }

    /// Obtener info del punto más cercano para mostrar en diálogo
    func getNearestStopInfo(userLocation: CLLocation) -> (name: String, distance: Int, originalOrder: Int)? {
        return navigationManager.getNearestStopInfo(stops: stops, userLocation: userLocation)
    }

    /// Solicitar ubicación actual
    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        if let location = locationService.userLocation {
            completion(location)
            return
        }
        locationService.requestSingleLocation(completion: completion)
    }

    /// Obtiene la distancia formateada de un segmento
    func formattedSegmentDistance(at index: Int) -> String? {
        return navigationManager.formattedSegmentDistance(at: index)
    }

    /// Actualizar segmento de usuario manualmente
    func updateUserSegment(from userLocation: CLLocationCoordinate2D, to nextStop: CLLocationCoordinate2D) {
        navigationManager.updateUserSegment(from: userLocation, to: nextStop) { [weak self] in
            self?.updateLiveActivity()
        }
    }

    // MARK: - Audio Controls (Delegados)

    func pauseAudio() { progressManager.pauseAudio() }
    func resumeAudio() { progressManager.resumeAudio() }
    func stopAudio() { progressManager.stopAudio() }
    func playStop(_ stop: Stop) { progressManager.playStop(stop) }

    // MARK: - Progress (Delegados)

    func getProgress() -> Double { stopsState.progress }
    func getVisitedCount() -> Int { stopsState.visitedCount }

    // MARK: - Private Methods

    private func calculateWalkingRoute() {
        navigationManager.calculateWalkingRoute(
            from: locationService.userLocation?.coordinate,
            through: stops
        ) { [weak self] success in
            guard let self = self else { return }

            self.isRouteReady = true

            if success {
                // Iniciar Live Activity después de calcular la ruta
                if let route = self.route {
                    self.liveActivityManager.startActivity(
                        route: route,
                        distanceToNextStop: self.navigationManager.distanceToNextStop,
                        totalStops: self.stops.count
                    )
                }
            } else {
                self.errorMessage = "Error calculando la ruta"
            }
        }
    }

    private func handleStopTriggered(_ stop: Stop) {
        progressManager.handleStopTriggered(stop, stops: stops)
        updateLiveActivity()

        // Verificar si completamos la ruta
        if progressManager.isRouteCompleted(totalStops: stops.count) {
            Log("¡Ruta completada!", level: .success, category: .route)
            liveActivityManager.endActivity(showFinalState: true)
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        // Logging de parada más cercana
        if let nearestStop = stopsState.unvisitedStops.min(by: {
            location.distance(from: $0.location) < location.distance(from: $1.location)
        }) {
            let distance = location.distance(from: nearestStop.location)
            if distance < 100 {
                Log("Cerca de: \(nearestStop.name) - \(Int(distance))m", level: .debug, category: .location)
            }
        }
    }

    private func updateLiveActivity() {
        liveActivityManager.updateActivity(
            distanceToNextStop: navigationManager.distanceToNextStop,
            totalStops: stops.count,
            isPlaying: progressManager.isAudioPlaying
        )
    }

    // MARK: - Persistence

    private func saveActiveRouteState() {
        guard let route = route, let historyId = currentHistoryId else { return }

        let state = ActiveRouteState(
            routeId: route.id,
            routeName: route.name,
            routeCity: route.city,
            historyId: historyId,
            startedAt: Date(),
            stopsState: stopsState
        )

        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: activeRouteStateKey)
            Log("Estado de ruta guardado", level: .debug, category: .route)
        }
    }

    private func clearActiveRouteState() {
        UserDefaults.standard.removeObject(forKey: activeRouteStateKey)
        Log("Estado de ruta limpiado", level: .debug, category: .route)
    }

    /// Obtener estado de ruta activa guardado
    func getActiveRouteState() -> ActiveRouteState? {
        guard let data = UserDefaults.standard.data(forKey: activeRouteStateKey),
              let state = try? JSONDecoder().decode(ActiveRouteState.self, from: data) else {
            return nil
        }
        return state
    }

    /// Limpiar ruta guardada
    func clearSavedRoute() {
        clearActiveRouteState()
    }

    /// Restaurar ruta desde estado guardado
    func restoreRoute(from state: ActiveRouteState, completion: @escaping (Bool) -> Void) {
        Log("Restaurando ruta - \(state.routeName)", level: .info, category: .route)

        currentHistoryId = state.historyId

        Task {
            do {
                // Cargar paradas desde Firebase
                let fetchedStops = try await firebaseService.fetchStops(for: state.routeId)

                // Buscar la ruta
                let routes = try await firebaseService.fetchAllRoutes()
                guard let foundRoute = routes.first(where: { $0.id == state.routeId }) else {
                    await MainActor.run {
                        self.errorMessage = "No se pudo encontrar la ruta"
                        completion(false)
                    }
                    return
                }

                await MainActor.run {
                    self.route = foundRoute
                    self.stops = fetchedStops

                    // Inicializar y restaurar stopsState
                    self.stopsState.initialize(with: fetchedStops)
                    self.stopsState.restore(
                        visitedIds: Set(state.visitedStopIds),
                        order: state.stopOrder.isEmpty ? nil : state.stopOrder
                    )

                    Log("Ruta restaurada - \(fetchedStops.count) paradas", level: .success, category: .route)
                    completion(true)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error restaurando ruta: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
}

// MARK: - Protocol Extensions for Publishers

private extension GeofenceServiceProtocol {
    var triggeredStopId: AnyPublisher<String?, Never> {
        Just(self.triggeredStopId).eraseToAnyPublisher()
    }
}

private extension LocationServiceProtocol {
    var userLocation: AnyPublisher<CLLocation?, Never> {
        Just(self.userLocation).eraseToAnyPublisher()
    }

    func enableHighAccuracyMode() {
        // Default implementation - override in actual service
    }

    func disableHighAccuracyMode() {
        // Default implementation - override in actual service
    }
}
