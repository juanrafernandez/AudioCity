//
//  Trip.swift
//  AudioCityPOC
//
//  Modelo para gestionar viajes del usuario con rutas seleccionadas
//

import Foundation

/// Representa un viaje planificado por el usuario a un destino
struct Trip: Identifiable, Codable {
    let id: String
    let destinationCity: String
    let destinationCountry: String
    var selectedRouteIds: [String]
    let createdAt: Date
    var startDate: Date?
    var endDate: Date?
    var isOfflineAvailable: Bool
    var lastSyncDate: Date?

    init(
        id: String = UUID().uuidString,
        destinationCity: String,
        destinationCountry: String = "España",
        selectedRouteIds: [String] = [],
        createdAt: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        isOfflineAvailable: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.destinationCity = destinationCity
        self.destinationCountry = destinationCountry
        self.selectedRouteIds = selectedRouteIds
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isOfflineAvailable = isOfflineAvailable
        self.lastSyncDate = lastSyncDate
    }

    /// Número de rutas seleccionadas
    var routeCount: Int {
        selectedRouteIds.count
    }

    /// Indica si el viaje tiene fechas definidas
    var hasDateRange: Bool {
        startDate != nil && endDate != nil
    }

    /// Formatea el rango de fechas para mostrar
    var dateRangeFormatted: String? {
        guard let start = startDate, let end = endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "es_ES")
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    /// Indica si el viaje ya pasó (endDate < hoy)
    var isPast: Bool {
        guard let end = endDate else {
            // Sin fecha de fin, no se considera pasado
            return false
        }
        return Calendar.current.startOfDay(for: end) < Calendar.current.startOfDay(for: Date())
    }

    /// Indica si el viaje es actual (hoy está entre startDate y endDate)
    var isCurrent: Bool {
        guard let start = startDate, let end = endDate else {
            return false
        }
        let today = Calendar.current.startOfDay(for: Date())
        let startDay = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        return today >= startDay && today <= endDay
    }

    /// Indica si el viaje es futuro (startDate > hoy)
    var isFuture: Bool {
        guard let start = startDate else {
            // Sin fecha de inicio, se considera futuro/pendiente
            return true
        }
        return Calendar.current.startOfDay(for: start) > Calendar.current.startOfDay(for: Date())
    }
}

/// Destino disponible para viajes
struct Destination: Identifiable, Codable, Hashable {
    let id: String
    let city: String
    let country: String
    let routeCount: Int
    let imageUrl: String?
    let isPopular: Bool

    init(
        id: String = UUID().uuidString,
        city: String,
        country: String = "España",
        routeCount: Int,
        imageUrl: String? = nil,
        isPopular: Bool = false
    ) {
        self.id = id
        self.city = city
        self.country = country
        self.routeCount = routeCount
        self.imageUrl = imageUrl
        self.isPopular = isPopular
    }
}

/// Categorías de rutas para las secciones
enum RouteCategory: String, CaseIterable, Codable {
    case top = "top"
    case trending = "trending"
    case tourist = "tourist"
    case cultural = "cultural"
    case gastronomic = "gastronomic"
    case nature = "nature"

    var displayName: String {
        switch self {
        case .top: return "Top Rutas"
        case .trending: return "Rutas de Moda"
        case .tourist: return "Turísticas"
        case .cultural: return "Arte y Cultura"
        case .gastronomic: return "Gastronomía"
        case .nature: return "Naturaleza"
        }
    }

    var icon: String {
        switch self {
        case .top: return "star.fill"
        case .trending: return "flame.fill"
        case .tourist: return "camera.fill"
        case .cultural: return "theatermasks.fill"
        case .gastronomic: return "fork.knife"
        case .nature: return "leaf.fill"
        }
    }

    var color: String {
        switch self {
        case .top: return "yellow"
        case .trending: return "orange"
        case .tourist: return "blue"
        case .cultural: return "purple"
        case .gastronomic: return "red"
        case .nature: return "green"
        }
    }
}

/// Sección de rutas para la UI
struct RouteSection: Identifiable {
    let id: String
    let category: RouteCategory
    var routes: [Route]

    init(category: RouteCategory, routes: [Route] = []) {
        self.id = category.rawValue
        self.category = category
        self.routes = routes
    }

    var title: String {
        category.displayName
    }

    var icon: String {
        category.icon
    }
}
