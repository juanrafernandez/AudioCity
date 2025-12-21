//
//  RouteNavigationManager.swift
//  AudioCityPOC
//
//  Gestor de navegación y cálculo de rutas
//  Encapsula la lógica de cálculo de rutas y optimización
//

import Foundation
import CoreLocation
import MapKit
import Combine

/// Gestor de navegación y cálculo de rutas
/// Responsabilidad única: cálculo de rutas y optimización de orden
final class RouteNavigationManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var routePolylines: [MKPolyline] = []
    @Published private(set) var routeDistances: [CLLocationDistance] = []
    @Published private(set) var distanceToNextStop: CLLocationDistance = 0
    @Published private(set) var isCalculating = false

    // MARK: - Computed Properties

    /// Distancia total de la ruta (suma de todos los segmentos excepto usuario→primera parada)
    var totalRouteDistance: CLLocationDistance {
        guard routeDistances.count > 1 else { return routeDistances.first ?? 0 }
        return routeDistances.dropFirst().reduce(0, +)
    }

    /// Distancia total incluyendo desde la posición del usuario
    var totalDistanceFromUser: CLLocationDistance {
        return routeDistances.reduce(0, +)
    }

    // MARK: - Dependencies

    private let routeCalculationService = RouteCalculationService()
    private let routeOptimizationService = RouteOptimizationService()

    // MARK: - Initialization

    init() {}

    // MARK: - Route Calculation

    /// Calcular rutas caminando entre cada par de puntos consecutivos
    func calculateWalkingRoute(
        from userLocation: CLLocationCoordinate2D?,
        through stops: [Stop],
        completion: @escaping (Bool) -> Void
    ) {
        let stopCoordinates = stops
            .sorted(by: { $0.order < $1.order })
            .map { $0.coordinate }

        guard !stopCoordinates.isEmpty else {
            completion(true)
            return
        }

        isCalculating = true

        routeCalculationService.calculateRoute(
            from: userLocation,
            through: stopCoordinates
        ) { [weak self] result in
            guard let self = self else { return }

            self.isCalculating = false

            switch result {
            case .success(let calcResult):
                self.routePolylines = calcResult.polylines
                self.routeDistances = calcResult.distances
                self.distanceToNextStop = calcResult.distanceToNext
                Log("Ruta calculada, distancia: \(Int(calcResult.distanceToNext))m", level: .success, category: .route)
                completion(true)

            case .failure(let error):
                Log("Error calculando ruta - \(error.localizedDescription)", level: .error, category: .route)
                completion(false)
            }
        }
    }

    /// Actualiza solo el primer segmento (usuario → próxima parada) cuando el usuario se mueve
    func updateUserSegment(
        from userLocation: CLLocationCoordinate2D,
        to nextStop: CLLocationCoordinate2D,
        onUpdate: (() -> Void)? = nil
    ) {
        routeCalculationService.calculateSegment(from: userLocation, to: nextStop) { [weak self] result in
            guard let self = self, !self.routePolylines.isEmpty else { return }

            switch result {
            case .success(let (polyline, distance)):
                self.routePolylines[0] = polyline
                self.routeDistances[0] = distance
                self.distanceToNextStop = distance
                Log("Distancia actualizada: \(Int(distance))m", level: .debug, category: .route)
                onUpdate?()

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

    // MARK: - Route Optimization

    /// Verificar si conviene optimizar la ruta
    func shouldSuggestOptimization(stops: [Stop], userLocation: CLLocation) -> Bool {
        return routeOptimizationService.shouldSuggestOptimization(stops: stops, userLocation: userLocation)
    }

    /// Obtener info del punto más cercano para mostrar en el diálogo
    func getNearestStopInfo(stops: [Stop], userLocation: CLLocation) -> (name: String, distance: Int, originalOrder: Int)? {
        return routeOptimizationService.getNearestStopInfo(stops: stops, userLocation: userLocation)
    }

    /// Optimizar ruta empezando por el punto más cercano
    func optimizeRoute(stops: [Stop], userLocation: CLLocation, stopsState: RouteStopsState) {
        let result = routeOptimizationService.optimizeRoute(stops: stops, startLocation: userLocation)
        routeOptimizationService.applyOptimization(to: stopsState, from: result)
    }

    // MARK: - Cleanup

    /// Limpiar datos de navegación
    func reset() {
        routePolylines = []
        routeDistances = []
        distanceToNextStop = 0
        isCalculating = false
    }
}
