//
//  RouteOptimizationService.swift
//  AudioCityPOC
//
//  Servicio para optimizar el orden de las paradas de una ruta
//  Usa el algoritmo "nearest neighbor" para minimizar la distancia total
//

import Foundation
import CoreLocation

// MARK: - Optimization Result

/// Resultado de la optimización de ruta
struct RouteOptimizationResult {
    /// Paradas en el orden optimizado
    let optimizedStops: [Stop]
    /// Indica si el orden cambió respecto al original
    let wasOptimized: Bool
    /// Distancia total estimada de la ruta optimizada (línea recta)
    let estimatedTotalDistance: CLLocationDistance
}

// MARK: - Route Optimization Service

/// Servicio para optimizar el orden de paradas en una ruta
/// Implementa el algoritmo "nearest neighbor" (vecino más cercano)
final class RouteOptimizationService {

    // MARK: - Public Methods

    /// Verifica si conviene optimizar la ruta
    /// Retorna true si el punto más cercano al usuario NO es el primer punto de la ruta
    /// - Parameters:
    ///   - stops: Lista de paradas
    ///   - userLocation: Ubicación actual del usuario
    /// - Returns: true si se recomienda optimizar
    func shouldSuggestOptimization(stops: [Stop], userLocation: CLLocation) -> Bool {
        guard stops.count >= 2 else { return false }

        let sortedByOrder = stops.sorted { $0.order < $1.order }
        guard let firstStop = sortedByOrder.first else { return false }

        // Encontrar el punto más cercano al usuario
        let nearestStop = findNearestStop(to: userLocation, from: stops)

        // Si el más cercano no es el primero, sugerir optimización
        return nearestStop?.id != firstStop.id
    }

    /// Obtiene información del punto más cercano al usuario
    /// - Parameters:
    ///   - stops: Lista de paradas
    ///   - userLocation: Ubicación actual del usuario
    /// - Returns: Tupla con nombre, distancia y orden original del punto más cercano
    func getNearestStopInfo(
        stops: [Stop],
        userLocation: CLLocation
    ) -> (name: String, distance: Int, originalOrder: Int)? {
        guard let nearestStop = findNearestStop(to: userLocation, from: stops) else {
            return nil
        }

        let distance = Int(userLocation.distance(from: nearestStop.location))
        return (nearestStop.name, distance, nearestStop.order)
    }

    /// Optimiza la ruta usando el algoritmo "nearest neighbor"
    /// - Parameters:
    ///   - stops: Lista de paradas a optimizar
    ///   - startLocation: Ubicación desde donde empezar (normalmente la del usuario)
    /// - Returns: Resultado de la optimización con las paradas reordenadas
    func optimizeRoute(stops: [Stop], startLocation: CLLocation) -> RouteOptimizationResult {
        guard !stops.isEmpty else {
            return RouteOptimizationResult(
                optimizedStops: [],
                wasOptimized: false,
                estimatedTotalDistance: 0
            )
        }

        var remainingStops = stops
        var optimizedStops: [Stop] = []
        var currentLocation = startLocation
        var totalDistance: CLLocationDistance = 0

        // Guardar orden original para comparar después
        let originalOrder = stops.sorted { $0.order < $1.order }.map { $0.id }

        // Algoritmo nearest neighbor: siempre ir al punto más cercano
        while !remainingStops.isEmpty {
            // Encontrar el más cercano a la ubicación actual
            guard let nearestIndex = remainingStops.indices.min(by: { i1, i2 in
                let d1 = currentLocation.distance(from: remainingStops[i1].location)
                let d2 = currentLocation.distance(from: remainingStops[i2].location)
                return d1 < d2
            }) else { break }

            let nearestStop = remainingStops[nearestIndex]
            let distanceToNearest = currentLocation.distance(from: nearestStop.location)
            totalDistance += distanceToNearest

            // Crear copia con nuevo orden
            var optimizedStop = nearestStop
            optimizedStop.order = optimizedStops.count + 1
            optimizedStops.append(optimizedStop)

            // Mover ubicación actual al punto seleccionado
            currentLocation = nearestStop.location

            // Eliminar de los restantes
            remainingStops.remove(at: nearestIndex)
        }

        // Verificar si el orden cambió
        let newOrder = optimizedStops.map { $0.id }
        let wasOptimized = originalOrder != newOrder

        if wasOptimized {
            Log("Ruta optimizada - Original: \(originalOrder.prefix(3).joined(separator: " → "))... → Optimizada: \(newOrder.prefix(3).joined(separator: " → "))...", level: .info, category: .route)
            Log("Distancia estimada: \(String(format: "%.2f", totalDistance / 1000)) km", level: .debug, category: .route)
        } else {
            Log("El orden original ya es óptimo", level: .info, category: .route)
        }

        return RouteOptimizationResult(
            optimizedStops: optimizedStops,
            wasOptimized: wasOptimized,
            estimatedTotalDistance: totalDistance
        )
    }

    /// Aplica el resultado de optimización a un array de paradas (modifica in-place los órdenes)
    /// - Parameters:
    ///   - stops: Array de paradas a modificar (inout)
    ///   - optimizationResult: Resultado de la optimización
    func applyOptimization(to stops: inout [Stop], from optimizationResult: RouteOptimizationResult) {
        for optimizedStop in optimizationResult.optimizedStops {
            if let index = stops.firstIndex(where: { $0.id == optimizedStop.id }) {
                stops[index].order = optimizedStop.order
            }
        }

        // Reordenar el array
        stops.sort { $0.order < $1.order }

        Log("Nuevo orden aplicado - \(stops.map { "\($0.order).\($0.name)" }.joined(separator: " → "))", level: .info, category: .route)
    }

    // MARK: - Private Methods

    private func findNearestStop(to location: CLLocation, from stops: [Stop]) -> Stop? {
        return stops.min { stop1, stop2 in
            let d1 = location.distance(from: stop1.location)
            let d2 = location.distance(from: stop2.location)
            return d1 < d2
        }
    }
}

// MARK: - Protocol

/// Protocolo para el servicio de optimización de rutas
protocol RouteOptimizationServiceProtocol {
    func shouldSuggestOptimization(stops: [Stop], userLocation: CLLocation) -> Bool
    func getNearestStopInfo(stops: [Stop], userLocation: CLLocation) -> (name: String, distance: Int, originalOrder: Int)?
    func optimizeRoute(stops: [Stop], startLocation: CLLocation) -> RouteOptimizationResult
    func applyOptimization(to stops: inout [Stop], from optimizationResult: RouteOptimizationResult)
}

extension RouteOptimizationService: RouteOptimizationServiceProtocol {}
