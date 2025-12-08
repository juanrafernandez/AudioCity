//
//  RouteHistory.swift
//  AudioCityPOC
//
//  Modelo para historial de rutas completadas por el usuario
//

import Foundation

/// Registro de una ruta realizada por el usuario
struct RouteHistory: Identifiable, Codable, Hashable {
    let id: String
    let routeId: String
    let routeName: String
    let routeCity: String
    let startedAt: Date
    var completedAt: Date?
    var stopsVisited: Int
    var totalStops: Int
    var distanceWalkedKm: Double
    var durationMinutes: Int

    init(
        id: String = UUID().uuidString,
        routeId: String,
        routeName: String,
        routeCity: String,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        stopsVisited: Int = 0,
        totalStops: Int,
        distanceWalkedKm: Double = 0,
        durationMinutes: Int = 0
    ) {
        self.id = id
        self.routeId = routeId
        self.routeName = routeName
        self.routeCity = routeCity
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.stopsVisited = stopsVisited
        self.totalStops = totalStops
        self.distanceWalkedKm = distanceWalkedKm
        self.durationMinutes = durationMinutes
    }

    /// Porcentaje de completado (0-100)
    var completionPercentage: Int {
        guard totalStops > 0 else { return 0 }
        return Int((Double(stopsVisited) / Double(totalStops)) * 100)
    }

    /// Si la ruta está completada (100%)
    var isCompleted: Bool {
        stopsVisited >= totalStops
    }

    /// Fecha formateada para mostrar
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: startedAt)
    }

    /// Hora de inicio formateada
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startedAt)
    }

    /// Duración formateada
    var durationFormatted: String {
        if durationMinutes < 60 {
            return "\(durationMinutes) min"
        } else {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h"
        }
    }
}
