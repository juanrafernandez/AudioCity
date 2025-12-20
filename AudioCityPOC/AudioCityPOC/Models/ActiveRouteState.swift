//
//  ActiveRouteState.swift
//  AudioCityPOC
//
//  Estado de ruta activa para persistencia entre sesiones
//

import Foundation

struct ActiveRouteState: Codable {
    let routeId: String
    let routeName: String
    let routeCity: String
    let historyId: String
    let startedAt: Date
    let stops: [StopState]

    struct StopState: Codable {
        let stopId: String
        let hasBeenVisited: Bool
    }
}
