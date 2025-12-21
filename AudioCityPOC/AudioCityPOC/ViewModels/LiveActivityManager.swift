//
//  LiveActivityManager.swift
//  AudioCityPOC
//
//  Gestor de Live Activity para Dynamic Island
//  Encapsula toda la lógica de Live Activities en un solo lugar
//

import Foundation
import Combine

/// Gestor de Live Activity para Dynamic Island
/// Responsabilidad única: gestionar el ciclo de vida de Live Activities
final class LiveActivityManager: ObservableObject {

    // MARK: - Dependencies

    private let stopsState: RouteStopsState

    // MARK: - State

    @Published private(set) var isActivityActive = false

    // MARK: - Initialization

    init(stopsState: RouteStopsState) {
        self.stopsState = stopsState
    }

    // MARK: - Public Methods

    /// Iniciar Live Activity para una ruta
    func startActivity(
        route: Route,
        distanceToNextStop: Double,
        totalStops: Int
    ) {
        guard let nextStop = stopsState.nextStop else { return }

        LiveActivityServiceWrapper.shared.startActivity(
            routeId: route.id,
            routeName: route.name,
            routeCity: route.city,
            nextStopName: nextStop.name,
            nextStopOrder: nextStop.order,
            distanceToNextStop: distanceToNextStop,
            totalStops: totalStops
        )

        isActivityActive = true
        Log("Live Activity iniciada para \(route.name)", level: .info, category: .route)
    }

    /// Actualizar Live Activity con nueva información
    func updateActivity(
        distanceToNextStop: Double,
        totalStops: Int,
        isPlaying: Bool
    ) {
        guard let nextStop = stopsState.nextStop else {
            // No hay más paradas, finalizar mostrando estado final
            endActivity(showFinalState: true)
            return
        }

        LiveActivityServiceWrapper.shared.updateActivity(
            distanceToNextStop: distanceToNextStop,
            nextStopName: nextStop.name,
            nextStopOrder: nextStop.order,
            visitedStops: stopsState.visitedCount,
            totalStops: totalStops,
            isPlaying: isPlaying
        )
    }

    /// Finalizar Live Activity
    func endActivity(showFinalState: Bool = false) {
        LiveActivityServiceWrapper.shared.endActivity(showFinalState: showFinalState)
        isActivityActive = false
        Log("Live Activity finalizada", level: .info, category: .route)
    }
}
