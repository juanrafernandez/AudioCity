//
//  GeofenceService.swift
//  AudioCityPOC
//
//  Servicio para detectar cuando el usuario entra en el radio de una parada
//

import Foundation
import CoreLocation
import Combine

class GeofenceService: ObservableObject, GeofenceServiceProtocol {

    // MARK: - Published Properties
    @Published var triggeredStop: Stop?
    @Published var triggeredStops: [Stop] = []  // Múltiples paradas activadas
    @Published var nearbyStops: [Stop] = []

    // MARK: - Private Properties
    private var monitoredStops: [Stop] = []
    private var cancellables = Set<AnyCancellable>()
    private let proximityThreshold: Double = 50 // metros extras para "nearby"

    // MARK: - Throttle Properties (solo recalcular si movió >10m)
    private var lastCalculatedLocation: CLLocation?
    private let minimumMovementForRecalculation: Double = 10 // metros

    // MARK: - Lifecycle

    deinit {
        cancellables.removeAll()
        Log("GeofenceService deinit", level: .debug, category: .location)
    }

    // MARK: - Public Methods
    
    /// Configurar geofences para una ruta
    func setupGeofences(for stops: [Stop], locationService: LocationService) {
        monitoredStops = stops
        
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
        triggeredStop = nil
        triggeredStops.removeAll()
        cancellables.removeAll()
        lastCalculatedLocation = nil // Reset throttle
        Log("Geofences limpiados", level: .debug, category: .location)
    }
    
    // MARK: - Private Methods

    /// Verificar proximidad a paradas (con throttle)
    private func checkProximity(userLocation: CLLocation) {
        // Throttle: solo recalcular si el usuario movió >10m desde última vez
        if let lastLocation = lastCalculatedLocation {
            let movement = userLocation.distance(from: lastLocation)
            if movement < minimumMovementForRecalculation {
                return // No recalcular, usuario no se ha movido suficiente
            }
        }

        // Actualizar última ubicación calculada
        lastCalculatedLocation = userLocation

        // Verificar paradas cercanas (para UI)
        updateNearbyStops(userLocation: userLocation)

        // Pre-filtro con bounding box para evitar cálculos costosos
        let maxRadius = (monitoredStops.map { $0.triggerRadiusMeters }.max() ?? 100) + proximityThreshold
        let candidateStops = filterByBoundingBox(
            stops: monitoredStops.filter { !$0.hasBeenVisited },
            userLocation: userLocation,
            maxDistance: maxRadius
        )

        // Recoger todas las paradas que entran en su radio de trigger
        var newlyTriggeredStops: [Stop] = []

        for stop in candidateStops {
            let stopLocation = CLLocation(latitude: stop.latitude,
                                         longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)

            // Si entramos en el radio de trigger
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
        // Convertir maxDistance a grados aproximados (1° lat ≈ 111km)
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
            let stopLocation = CLLocation(latitude: stop.latitude, 
                                         longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)
            return distance <= (stop.triggerRadiusMeters + proximityThreshold)
        }
        
        DispatchQueue.main.async {
            self.nearbyStops = nearby
        }
    }
    
    /// Activar una parada
    private func triggerStop(_ stop: Stop, distance: Double) {
        // Verificar que no esté ya marcada como visitada
        guard !stop.hasBeenVisited else { return }

        DispatchQueue.main.async {
            // Marcar como visitada
            if let index = self.monitoredStops.firstIndex(where: { $0.id == stop.id }) {
                self.monitoredStops[index].hasBeenVisited = true
            }

            var visitedStop = stop
            visitedStop.hasBeenVisited = true

            // Añadir a la lista de paradas activadas
            self.triggeredStops.append(visitedStop)

            // Mantener compatibilidad: triggeredStop es la última activada
            self.triggeredStop = visitedStop

            Log("Parada activada - \(stop.name) (distancia: \(Int(distance))m)", level: .success, category: .location)
        }
    }
    
    /// Obtener siguiente parada no visitada
    func getNextStop() -> Stop? {
        return monitoredStops.first(where: { !$0.hasBeenVisited })
    }
    
    /// Obtener progreso de la ruta (0.0 - 1.0)
    func getProgress() -> Double {
        let total = monitoredStops.count
        guard total > 0 else { return 0 }
        
        let visited = monitoredStops.filter { $0.hasBeenVisited }.count
        return Double(visited) / Double(total)
    }
}
