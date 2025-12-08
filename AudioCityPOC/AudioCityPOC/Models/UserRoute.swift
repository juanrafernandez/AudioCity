//
//  UserRoute.swift
//  AudioCityPOC
//
//  Modelo para rutas creadas por el usuario
//

import Foundation
import CoreLocation

/// Ruta creada por el usuario
struct UserRoute: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var city: String
    var neighborhood: String
    var stops: [UserStop]
    let createdAt: Date
    var updatedAt: Date
    var isPublished: Bool
    var totalDistanceKm: Double
    var estimatedDurationMinutes: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        city: String,
        neighborhood: String = "",
        stops: [UserStop] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPublished: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.city = city
        self.neighborhood = neighborhood
        self.stops = stops
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublished = isPublished
        self.totalDistanceKm = 0
        self.estimatedDurationMinutes = stops.count * 5 // 5 min por parada estimado
    }

    /// Número de paradas
    var numStops: Int {
        stops.count
    }

    /// Calcular distancia total entre paradas
    mutating func calculateDistance() {
        guard stops.count > 1 else {
            totalDistanceKm = 0
            return
        }

        var total: Double = 0
        for i in 0..<(stops.count - 1) {
            let from = CLLocation(latitude: stops[i].latitude, longitude: stops[i].longitude)
            let to = CLLocation(latitude: stops[i + 1].latitude, longitude: stops[i + 1].longitude)
            total += from.distance(from: to)
        }
        totalDistanceKm = total / 1000.0
    }

    /// Estimar duración basada en paradas y distancia
    mutating func estimateDuration() {
        // 5 min por parada + 12 min/km caminando
        let walkingTime = Int(totalDistanceKm * 12)
        let stopTime = stops.count * 5
        estimatedDurationMinutes = walkingTime + stopTime
    }
}

/// Parada creada por el usuario
struct UserStop: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var script: String
    var order: Int
    var imageUrl: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        latitude: Double,
        longitude: Double,
        script: String = "",
        order: Int,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.script = script
        self.order = order
        self.imageUrl = imageUrl
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
