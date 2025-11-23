//
//  RouteViewModel.swift
//  AudioCityPOC
//
//  ViewModel principal que orquesta todos los servicios
//

import Foundation
import Combine
import CoreLocation

class RouteViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentRoute: Route?
    @Published var stops: [Stop] = []
    @Published var isRouteActive = false
    @Published var currentStop: Stop?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var visitedStopsCount = 0

    // MARK: - Services
    let locationService = LocationService()
    let audioService = AudioService()
    let geofenceService = GeofenceService()
    let firebaseService = FirebaseService()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let routeId = "arganzuela-poc-001"

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

        // Observar ubicación del usuario
        locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateNearestStop(for: location)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Cargar ruta desde Firebase
    func loadRoute() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Cargar ruta y paradas en paralelo
                let (route, fetchedStops) = try await firebaseService.fetchCompleteRoute(routeId: routeId)

                await MainActor.run {
                    self.currentRoute = route
                    self.stops = fetchedStops
                    self.isLoading = false

                    print("✅ RouteViewModel: Ruta cargada - \(route.name)")
                    print("✅ RouteViewModel: \(fetchedStops.count) paradas cargadas")
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando la ruta: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ RouteViewModel: Error - \(error.localizedDescription)")
                }
            }
        }
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

        // Iniciar servicios
        locationService.startTracking()
        geofenceService.setupGeofences(for: stops, locationService: locationService)

        isRouteActive = true
        errorMessage = nil

        print("🚀 RouteViewModel: Ruta iniciada - \(route.name)")
    }

    /// Detener ruta
    func endRoute() {
        locationService.stopTracking()
        geofenceService.clearGeofences()
        audioService.stop()

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

        // Actualizar parada actual
        currentStop = stop

        // Actualizar contador de visitadas
        visitedStopsCount = getVisitedCount()

        // Reproducir audio automáticamente
        audioService.speak(text: stop.scriptEs, language: "es-ES")

        print("🎯 RouteViewModel: Parada activada - \(stop.name)")
        print("📊 Progreso: \(visitedStopsCount)/\(stops.count) paradas completadas")

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
