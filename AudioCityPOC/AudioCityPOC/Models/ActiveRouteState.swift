//
//  ActiveRouteState.swift
//  AudioCityPOC
//
//  Estado de ruta activa para persistencia entre sesiones.
//  Almacena IDs de paradas visitadas y orden personalizado.
//

import Foundation

struct ActiveRouteState: Codable {
    let routeId: String
    let routeName: String
    let routeCity: String
    let historyId: String
    let startedAt: Date

    /// IDs de las paradas que han sido visitadas
    let visitedStopIds: [String]

    /// Orden de las paradas (puede diferir del original si se optimizó)
    let stopOrder: [String]

    // MARK: - Initialization

    init(
        routeId: String,
        routeName: String,
        routeCity: String,
        historyId: String,
        startedAt: Date,
        visitedStopIds: [String],
        stopOrder: [String]
    ) {
        self.routeId = routeId
        self.routeName = routeName
        self.routeCity = routeCity
        self.historyId = historyId
        self.startedAt = startedAt
        self.visitedStopIds = visitedStopIds
        self.stopOrder = stopOrder
    }

    /// Crea el estado desde RouteStopsState
    init(
        routeId: String,
        routeName: String,
        routeCity: String,
        historyId: String,
        startedAt: Date,
        stopsState: RouteStopsState
    ) {
        let (visitedIds, order) = stopsState.toPersistenceData()
        self.routeId = routeId
        self.routeName = routeName
        self.routeCity = routeCity
        self.historyId = historyId
        self.startedAt = startedAt
        self.visitedStopIds = visitedIds
        self.stopOrder = order
    }

    // MARK: - Legacy Migration (opcional)

    /// Migra desde el formato antiguo [StopState] si es necesario
    struct LegacyStopState: Codable {
        let stopId: String
        let hasBeenVisited: Bool
    }

    /// Decoder con soporte para formato legacy
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        routeId = try container.decode(String.self, forKey: .routeId)
        routeName = try container.decode(String.self, forKey: .routeName)
        routeCity = try container.decode(String.self, forKey: .routeCity)
        historyId = try container.decode(String.self, forKey: .historyId)
        startedAt = try container.decode(Date.self, forKey: .startedAt)

        // Intentar nuevo formato primero
        if let visitedIds = try? container.decode([String].self, forKey: .visitedStopIds) {
            visitedStopIds = visitedIds
            stopOrder = try container.decodeIfPresent([String].self, forKey: .stopOrder) ?? []
        } else if let legacyStops = try? container.decode([LegacyStopState].self, forKey: .stops) {
            // Migrar desde formato legacy
            visitedStopIds = legacyStops.filter { $0.hasBeenVisited }.map { $0.stopId }
            stopOrder = legacyStops.map { $0.stopId }
        } else {
            visitedStopIds = []
            stopOrder = []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case routeId, routeName, routeCity, historyId, startedAt
        case visitedStopIds, stopOrder
        case stops // Legacy
    }

    /// Encoder - solo guarda el nuevo formato
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routeId, forKey: .routeId)
        try container.encode(routeName, forKey: .routeName)
        try container.encode(routeCity, forKey: .routeCity)
        try container.encode(historyId, forKey: .historyId)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(visitedStopIds, forKey: .visitedStopIds)
        try container.encode(stopOrder, forKey: .stopOrder)
    }
}
