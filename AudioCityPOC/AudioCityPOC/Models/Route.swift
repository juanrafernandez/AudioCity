//
//  Route.swift
//  AudioCityPOC
//
//  Modelo de ruta turística
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - RouteTheme

/// Temática de contenido de las rutas turísticas
enum RouteTheme: String, Codable, CaseIterable, Hashable {
    case historicas = "Historicas"
    case gastronomicas = "Gastronomicas"
    case arte = "Arte"
    case naturaleza = "Naturaleza"
    case arquitectura = "Arquitectura"
    case nocturnas = "Nocturnas"
    case familiar = "Familiar"
    case general = "General"

    /// Nombre para mostrar en la UI
    var displayName: String {
        switch self {
        case .historicas: return "Históricas"
        case .gastronomicas: return "Gastronómicas"
        case .arte: return "Arte y Cultura"
        case .naturaleza: return "Naturaleza"
        case .arquitectura: return "Arquitectura"
        case .nocturnas: return "Nocturnas"
        case .familiar: return "Familiar"
        case .general: return "General"
        }
    }

    /// Icono SF Symbol para la categoría
    var icon: String {
        switch self {
        case .historicas: return "building.columns.fill"
        case .gastronomicas: return "fork.knife"
        case .arte: return "paintpalette.fill"
        case .naturaleza: return "leaf.fill"
        case .arquitectura: return "building.2.fill"
        case .nocturnas: return "moon.stars.fill"
        case .familiar: return "figure.2.and.child.holdinghands"
        case .general: return "map.fill"
        }
    }

    /// Color asociado a la categoría
    var color: Color {
        switch self {
        case .historicas: return ACColors.primary
        case .gastronomicas: return .orange
        case .arte: return .purple
        case .naturaleza: return .green
        case .arquitectura: return .blue
        case .nocturnas: return .indigo
        case .familiar: return .pink
        case .general: return ACColors.secondary
        }
    }
}

// MARK: - Route

struct Route: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let city: String
    let neighborhood: String
    let durationMinutes: Int
    let distanceKm: Double
    let difficulty: String
    let numStops: Int
    let language: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let thumbnailUrl: String
    let startLocation: Location
    let endLocation: Location

    // Nuevos campos para ordenación y categorización
    let rating: Double       // 0.0-5.0 estrellas
    let usageCount: Int      // Veces completada por usuarios
    let theme: RouteTheme    // Temática de la ruta

    enum CodingKeys: String, CodingKey {
        case id, name, description, city, neighborhood, difficulty, language
        case durationMinutes = "duration_minutes"
        case distanceKm = "distance_km"
        case numStops = "num_stops"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case thumbnailUrl = "thumbnail_url"
        case startLocation = "start_location"
        case endLocation = "end_location"
        case rating
        case usageCount = "usage_count"
        case theme
    }

    // MARK: - Custom Decoder

    /// Decoder personalizado con valores por defecto para compatibilidad con datos existentes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Campos existentes (requeridos)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        city = try container.decode(String.self, forKey: .city)
        neighborhood = try container.decode(String.self, forKey: .neighborhood)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        distanceKm = try container.decode(Double.self, forKey: .distanceKm)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        numStops = try container.decode(Int.self, forKey: .numStops)
        language = try container.decode(String.self, forKey: .language)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl) ?? ""
        startLocation = try container.decode(Location.self, forKey: .startLocation)
        endLocation = try container.decode(Location.self, forKey: .endLocation)

        // Nuevos campos con valores por defecto (para compatibilidad con datos existentes)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0.0
        usageCount = try container.decodeIfPresent(Int.self, forKey: .usageCount) ?? 0

        // Decodificar temática con fallback a .general
        if let themeString = try container.decodeIfPresent(String.self, forKey: .theme) {
            theme = RouteTheme(rawValue: themeString) ?? RouteTheme.general
        } else {
            theme = RouteTheme.general
        }
    }

    // MARK: - Memberwise Initializer

    /// Inicializador para crear rutas programáticamente (tests, mocks)
    init(
        id: String,
        name: String,
        description: String,
        city: String,
        neighborhood: String,
        durationMinutes: Int,
        distanceKm: Double,
        difficulty: String,
        numStops: Int,
        language: String,
        isActive: Bool,
        createdAt: String,
        updatedAt: String,
        thumbnailUrl: String,
        startLocation: Location,
        endLocation: Location,
        rating: Double = 0.0,
        usageCount: Int = 0,
        theme: RouteTheme = .general
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.city = city
        self.neighborhood = neighborhood
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.difficulty = difficulty
        self.numStops = numStops
        self.language = language
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailUrl = thumbnailUrl
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.rating = rating
        self.usageCount = usageCount
        self.theme = theme
    }

    // MARK: - Location

    struct Location: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        let name: String

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Convierte a CLLocation para cálculos de distancia
        var clLocation: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
    }
}

// MARK: - Computed Properties

extension Route {
    /// Rating formateado con una decimal (ej: "4.5")
    var ratingFormatted: String {
        String(format: "%.1f", rating)
    }

    /// Distancia formateada (ej: "2.5 km")
    var distanceFormatted: String {
        String(format: "%.1f km", distanceKm)
    }

    /// Duración formateada (ej: "45 min")
    var durationFormatted: String {
        "\(durationMinutes) min"
    }

    /// Número de usos formateado (ej: "1.2k" para 1200)
    var usageCountFormatted: String {
        if usageCount >= 1000 {
            return String(format: "%.1fk", Double(usageCount) / 1000.0)
        }
        return "\(usageCount)"
    }
}
