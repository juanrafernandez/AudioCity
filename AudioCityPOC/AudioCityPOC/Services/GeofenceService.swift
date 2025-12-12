//
//  GeofenceService.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//


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
        
        print("🎯 GeofenceService: Monitoreando \(stops.count) paradas")
    }
    
    /// Limpiar geofences
    func clearGeofences() {
        monitoredStops.removeAll()
        nearbyStops.removeAll()
        triggeredStop = nil
        triggeredStops.removeAll()
        cancellables.removeAll()
        print("🎯 GeofenceService: Geofences limpiados")
    }
    
    // MARK: - Private Methods
    
    /// Verificar proximidad a paradas
    private func checkProximity(userLocation: CLLocation) {
        // Verificar paradas cercanas (para UI)
        updateNearbyStops(userLocation: userLocation)

        // Recoger todas las paradas que entran en su radio de trigger
        var newlyTriggeredStops: [Stop] = []

        for stop in monitoredStops where !stop.hasBeenVisited {
            let stopLocation = CLLocation(latitude: stop.latitude,
                                         longitude: stop.longitude)
            let distance = userLocation.distance(from: stopLocation)

            // Si entramos en el radio de trigger
            if distance <= stop.triggerRadiusMeters {
                newlyTriggeredStops.append(stop)
                print("🎯 GeofenceService: Parada en rango - \(stop.name) (distancia: \(Int(distance))m)")
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

            print("🎯 GeofenceService: Parada activada - \(stop.name) (distancia: \(Int(distance))m)")
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
