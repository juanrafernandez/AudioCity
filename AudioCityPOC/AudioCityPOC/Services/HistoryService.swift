//
//  HistoryService.swift
//  AudioCityPOC
//
//  Servicio para gestionar el historial de rutas completadas
//

import Foundation
import Combine

class HistoryService: ObservableObject {

    // MARK: - Singleton
    static let shared = HistoryService()

    // MARK: - Published Properties
    @Published var history: [RouteHistory] = []
    @Published var isLoading = false

    // MARK: - Dependencies
    private let repository: HistoryRepositoryProtocol

    // MARK: - Initialization
    init(repository: HistoryRepositoryProtocol = HistoryRepository()) {
        self.repository = repository
        loadHistory()
    }

    // MARK: - Public Methods

    /// Iniciar una nueva ruta (crear registro en historial)
    func startRoute(routeId: String, routeName: String, routeCity: String, totalStops: Int) -> RouteHistory {
        let record = RouteHistory(
            routeId: routeId,
            routeName: routeName,
            routeCity: routeCity,
            totalStops: totalStops
        )

        history.insert(record, at: 0) // Añadir al principio
        saveHistory()

        print("✅ HistoryService: Ruta iniciada - \(routeName)")
        return record
    }

    /// Actualizar progreso de una ruta en curso
    func updateProgress(historyId: String, stopsVisited: Int, distanceWalkedKm: Double) {
        guard let index = history.firstIndex(where: { $0.id == historyId }) else {
            return
        }

        history[index].stopsVisited = stopsVisited
        history[index].distanceWalkedKm = distanceWalkedKm

        // Calcular duración
        let elapsed = Date().timeIntervalSince(history[index].startedAt)
        history[index].durationMinutes = Int(elapsed / 60)

        // Si completó todas las paradas, marcar como completada
        if history[index].stopsVisited >= history[index].totalStops {
            history[index].completedAt = Date()
        }

        saveHistory()
    }

    /// Marcar ruta como completada
    func completeRoute(historyId: String) {
        guard let index = history.firstIndex(where: { $0.id == historyId }) else {
            return
        }

        history[index].completedAt = Date()
        history[index].stopsVisited = history[index].totalStops

        // Calcular duración final
        let elapsed = Date().timeIntervalSince(history[index].startedAt)
        history[index].durationMinutes = Int(elapsed / 60)

        saveHistory()

        // Publicar evento de ruta completada (PointsService lo escuchará)
        EventBus.shared.publishRouteCompleted(
            routeId: history[index].routeId,
            routeName: history[index].routeName
        )

        print("✅ HistoryService: Ruta completada - \(history[index].routeName)")
    }

    /// Cancelar/abandonar una ruta en curso
    func abandonRoute(historyId: String) {
        guard let index = history.firstIndex(where: { $0.id == historyId }) else {
            return
        }

        // Calcular duración hasta el abandono
        let elapsed = Date().timeIntervalSince(history[index].startedAt)
        history[index].durationMinutes = Int(elapsed / 60)

        saveHistory()
        print("⚠️ HistoryService: Ruta abandonada - \(history[index].routeName)")
    }

    /// Eliminar registro del historial
    func deleteRecord(_ historyId: String) {
        history.removeAll { $0.id == historyId }
        saveHistory()
        print("🗑️ HistoryService: Registro eliminado")
    }

    /// Limpiar todo el historial
    func clearHistory() {
        history.removeAll()
        saveHistory()
        print("🗑️ HistoryService: Historial limpiado")
    }

    /// Obtener historial por fecha (agrupado)
    func getHistoryGroupedByDate() -> [(date: String, routes: [RouteHistory])] {
        let grouped = Dictionary(grouping: history) { record in
            record.dateFormatted
        }

        return grouped.map { (date: $0.key, routes: $0.value) }
            .sorted { $0.routes.first?.startedAt ?? Date() > $1.routes.first?.startedAt ?? Date() }
    }

    /// Obtener estadísticas generales
    func getStats() -> HistoryStats {
        let completed = history.filter { $0.isCompleted }
        let totalDistance = history.reduce(0) { $0 + $1.distanceWalkedKm }
        let totalDuration = history.reduce(0) { $0 + $1.durationMinutes }
        let totalStopsVisited = history.reduce(0) { $0 + $1.stopsVisited }

        return HistoryStats(
            totalRoutes: history.count,
            completedRoutes: completed.count,
            totalDistanceKm: totalDistance,
            totalDurationMinutes: totalDuration,
            totalStopsVisited: totalStopsVisited
        )
    }

    /// Obtener ruta en curso (si hay alguna)
    func getCurrentRoute() -> RouteHistory? {
        return history.first { $0.completedAt == nil && !$0.isCompleted }
    }

    // MARK: - Private Methods

    private func loadHistory() {
        do {
            history = try repository.loadHistory()
            print("✅ HistoryService: \(history.count) registros cargados")
        } catch {
            print("❌ HistoryService: Error cargando historial - \(error.localizedDescription)")
            history = []
        }
    }

    private func saveHistory() {
        do {
            try repository.saveHistory(history)
        } catch {
            print("❌ HistoryService: Error guardando historial - \(error.localizedDescription)")
        }
    }
}

// MARK: - History Stats
struct HistoryStats {
    let totalRoutes: Int
    let completedRoutes: Int
    let totalDistanceKm: Double
    let totalDurationMinutes: Int
    let totalStopsVisited: Int

    var completionRate: Int {
        guard totalRoutes > 0 else { return 0 }
        return Int((Double(completedRoutes) / Double(totalRoutes)) * 100)
    }

    var totalDurationFormatted: String {
        if totalDurationMinutes < 60 {
            return "\(totalDurationMinutes) min"
        } else {
            let hours = totalDurationMinutes / 60
            return "\(hours)h"
        }
    }

    var totalDistanceFormatted: String {
        return String(format: "%.1f km", totalDistanceKm)
    }
}
