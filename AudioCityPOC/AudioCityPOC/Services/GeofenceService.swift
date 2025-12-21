//
//  GeofenceService.swift
//  AudioCityPOC
//
//  Servicio para detectar cuando el usuario entra en el radio de una parada.
//  Usa RouteStopsState para gestionar el estado de visitas.
//

import Foundation
import CoreLocation
import Combine

class GeofenceService: ObservableObject, GeofenceServiceProtocol {

    // MARK: - Published Properties

    /// ID de la última parada activada (usar con stopsState para obtener Stop)
    @Published var triggeredStopId: String?

    /// IDs de todas las paradas activadas en esta sesión
    @Published var triggeredStopIds: [String] = []

    /// Paradas cercanas al usuario (para UI)
    @Published var nearbyStops: [Stop] = []

    // MARK: - Private Properties

    private var monitoredStops: [Stop] = []
    private var cancellables = Set<AnyCancellable>()
    private let proximityThreshold: Double = 50 // metros extras para "nearby"

    // MARK: - Throttle Properties

    private var lastCalculatedLocation: CLLocation?
    private let minimumMovementForRecalculation: Double = 10 // metros

    // MARK: - Dependencies

    /// Estado compartido de paradas (inyectado)
    private weak var stopsState: RouteStopsState?

    // MARK: - Lifecycle

    init() {}

    deinit {
        cancellables.removeAll()
        Log("GeofenceService deinit", level: .debug, category: .location)
    }

    // MARK: - Public Methods

    /// Configurar geofences para una ruta
    func setupGeofences(for stops: [Stop], locationService: LocationService, stopsState: RouteStopsState) {
        self.monitoredStops = stops
        self.stopsState = stopsState

        // Suscribirse a cambios de ubicación
        locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] userLocation in
                self?.checkProximity(userLocation: userLocation)
            }
            .store(in: &cancellables)

        Log("Monitoreando \(stops.count) paradas", level: .info, category: .location)
    }

    /// Limpiar geofences
    func clearGeofences() {
        monitoredStops.removeAll()
        nearbyStops.removeAll()
        triggeredStopId = nil
        triggeredStopIds.removeAll()
        cancellables.removeAll()
        lastCalculatedLocation = nil
        stopsState = nil
        Log("Geofences limpiados", level: .debug, category: .location)
    }

    /// Obtener siguiente parada no visitada
    func getNextStop() -> Stop? {
        stopsState?.nextStop
    }

    /// Obtener progreso de la ruta (0.0 - 1.0)
    func getProgress() -> Double {
        stopsState?.progress ?? 0
    }

    /// Obtener parada por ID
    func getStop(byId id: String) -> Stop? {
        monitoredStops.first { $0.id == id }
    }

    // MARK: - Private Methods

    /// Verificar proximidad a paradas (con throttle)
    private func checkProximity(userLocation: CLLocation) {
        guard let stopsState = stopsState else { return }

        // Throttle: solo recalcular si el usuario movió >10m desde última vez
        if let lastLocation = lastCalculatedLocation {
            let movement = userLocation.distance(from: lastLocation)
            if movement < minimumMovementForRecalculation {
                return
            }
        }

        lastCalculatedLocation = userLocation

        // Verificar paradas cercanas (para UI)
        updateNearbyStops(userLocation: userLocation)

        // Pre-filtro con bounding box para evitar cálculos costosos
        let maxRadius = (monitoredStops.map { $0.triggerRadiusMeters }.max() ?? 100) + proximityThreshold

        // Filtrar solo paradas no visitadas
        let unvisitedStops = monitoredStops.filter { !stopsState.isVisited($0.id) }

        let candidateStops = filterByBoundingBox(
            stops: unvisitedStops,
            userLocation: userLocation,
            maxDistance: maxRadius
        )

        // Recoger todas las paradas que entran en su radio de trigger
        var newlyTriggeredStops: [Stop] = []

        for stop in candidateStops {
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)

            if distance <= stop.triggerRadiusMeters {
                newlyTriggeredStops.append(stop)
                Log("Parada en rango - \(stop.name) (distancia: \(Int(distance))m)", level: .debug, category: .location)
            }
        }

        // Activar todas las paradas detectadas (ordenadas por su orden en la ruta)
        if !newlyTriggeredStops.isEmpty {
            let sortedStops = newlyTriggeredStops.sorted { $0.order < $1.order }
            for stop in sortedStops {
                triggerStop(stop, distance: userLocation.distance(from: stop.location))
            }
        }
    }

    /// Pre-filtro con bounding box (más eficiente que calcular distancias exactas)
    private func filterByBoundingBox(stops: [Stop], userLocation: CLLocation, maxDistance: Double) -> [Stop] {
        let latDelta = maxDistance / 111_000
        let lonDelta = maxDistance / (111_000 * cos(userLocation.coordinate.latitude * .pi / 180))

        let userLat = userLocation.coordinate.latitude
        let userLon = userLocation.coordinate.longitude

        return stops.filter { stop in
            let latDiff = abs(stop.latitude - userLat)
            let lonDiff = abs(stop.longitude - userLon)
            return latDiff <= latDelta && lonDiff <= lonDelta
        }
    }

    /// Actualizar lista de paradas cercanas
    private func updateNearbyStops(userLocation: CLLocation) {
        let nearby = monitoredStops.filter { stop in
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)
            return distance <= (stop.triggerRadiusMeters + proximityThreshold)
        }

        DispatchQueue.main.async {
            self.nearbyStops = nearby
        }
    }

    /// Activar una parada
    private func triggerStop(_ stop: Stop, distance: Double) {
        guard let stopsState = stopsState else { return }

        // Verificar que no esté ya visitada
        guard !stopsState.isVisited(stop.id) else { return }

        DispatchQueue.main.async {
            // Marcar como visitada en el estado central
            stopsState.markVisited(stop.id)

            // Añadir a la lista de paradas activadas
            self.triggeredStopIds.append(stop.id)

            // Publicar la última parada activada
            self.triggeredStopId = stop.id

            Log("Parada activada - \(stop.name) (distancia: \(Int(distance))m)", level: .success, category: .location)
        }
    }
}

// MARK: - Legacy Compatibility

extension GeofenceService {
    /// Método legacy para compatibilidad - usar setupGeofences(for:locationService:stopsState:)
    func setupGeofences(for stops: [Stop], locationService: LocationService) {
        Log("ADVERTENCIA: setupGeofences sin stopsState - funcionalidad limitada", level: .warning, category: .location)
        self.monitoredStops = stops
        // Sin stopsState, el servicio no funcionará correctamente
    }

    /// Obtener la parada activada (para compatibilidad)
    var triggeredStop: Stop? {
        guard let id = triggeredStopId else { return nil }
        return monitoredStops.first { $0.id == id }
    }
}
