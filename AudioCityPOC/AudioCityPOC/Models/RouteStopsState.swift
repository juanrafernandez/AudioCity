//
//  RouteStopsState.swift
//  AudioCityPOC
//
//  Gestión centralizada del estado de paradas durante una ruta activa.
//  Separa el estado mutable (visitadas, orden) del modelo inmutable (Stop).
//

import Foundation
import Combine

/// Clase observable que gestiona el estado runtime de las paradas.
/// Reemplaza el uso de `Stop.hasBeenVisited` mutable.
class RouteStopsState: ObservableObject {

    // MARK: - Published Properties

    /// Lista de paradas de la ruta actual (inmutables)
    @Published private(set) var stops: [Stop] = []

    /// IDs de las paradas que han sido visitadas
    @Published private(set) var visitedStopIds: Set<String> = []

    /// Orden de las paradas (puede cambiar por optimización)
    @Published private(set) var stopOrder: [String] = []

    // MARK: - Computed Properties

    /// Paradas ordenadas según el orden actual
    var orderedStops: [Stop] {
        stopOrder.compactMap { id in
            stops.first { $0.id == id }
        }
    }

    /// Paradas que aún no han sido visitadas, en orden
    var unvisitedStops: [Stop] {
        orderedStops.filter { !visitedStopIds.contains($0.id) }
    }

    /// Primera parada no visitada (próximo destino)
    var nextStop: Stop? {
        unvisitedStops.first
    }

    /// Número de paradas visitadas
    var visitedCount: Int {
        visitedStopIds.count
    }

    /// Total de paradas
    var totalStops: Int {
        stops.count
    }

    /// Progreso de la ruta (0.0 a 1.0)
    var progress: Double {
        guard !stops.isEmpty else { return 0 }
        return Double(visitedCount) / Double(stops.count)
    }

    /// Verifica si la ruta está completa
    var isComplete: Bool {
        !stops.isEmpty && visitedCount == stops.count
    }

    // MARK: - Query Methods

    /// Verifica si una parada específica ha sido visitada
    func isVisited(_ stopId: String) -> Bool {
        visitedStopIds.contains(stopId)
    }

    /// Obtiene una parada por su ID
    func stop(withId id: String) -> Stop? {
        stops.first { $0.id == id }
    }

    /// Obtiene el índice de una parada en el orden actual
    func orderIndex(of stopId: String) -> Int? {
        stopOrder.firstIndex(of: stopId)
    }

    // MARK: - Mutation Methods

    /// Inicializa el estado con las paradas de una ruta
    func initialize(with stops: [Stop]) {
        self.stops = stops
        self.stopOrder = stops.sorted { $0.order < $1.order }.map { $0.id }
        self.visitedStopIds = []

        Log("RouteStopsState inicializado con \(stops.count) paradas", level: .info, category: .app)
    }

    /// Marca una parada como visitada
    func markVisited(_ stopId: String) {
        guard stops.contains(where: { $0.id == stopId }) else {
            Log("Intento de marcar parada inexistente: \(stopId)", level: .warning, category: .app)
            return
        }

        guard !visitedStopIds.contains(stopId) else {
            Log("Parada ya visitada: \(stopId)", level: .debug, category: .app)
            return
        }

        visitedStopIds.insert(stopId)
        Log("Parada marcada como visitada: \(stopId) (\(visitedCount)/\(totalStops))", level: .info, category: .app)
    }

    /// Reordena las paradas (usado por optimización de ruta)
    func reorder(optimizedStops: [Stop]) {
        stopOrder = optimizedStops.map { $0.id }
        Log("Paradas reordenadas: \(stopOrder)", level: .info, category: .app)
    }

    /// Restaura el estado desde persistencia
    func restore(visitedIds: Set<String>, order: [String]? = nil) {
        // Solo restaurar IDs que existen en las paradas actuales
        let validIds = visitedIds.intersection(Set(stops.map { $0.id }))
        visitedStopIds = validIds

        if let order = order, !order.isEmpty {
            // Validar que el orden contiene las paradas correctas
            let orderSet = Set(order)
            let stopsSet = Set(stops.map { $0.id })
            if orderSet == stopsSet {
                stopOrder = order
            }
        }

        Log("Estado restaurado: \(visitedCount) visitadas, orden: \(stopOrder.count) paradas", level: .info, category: .app)
    }

    /// Resetea el estado (al terminar o cancelar ruta)
    func reset() {
        stops = []
        visitedStopIds = []
        stopOrder = []
        Log("RouteStopsState reseteado", level: .info, category: .app)
    }

    // MARK: - Persistence Helpers

    /// Genera datos para persistencia
    func toPersistenceData() -> (visitedIds: [String], order: [String]) {
        (Array(visitedStopIds), stopOrder)
    }
}
