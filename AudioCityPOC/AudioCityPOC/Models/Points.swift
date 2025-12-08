//
//  Points.swift
//  AudioCityPOC
//
//  Modelos para el sistema de puntos y niveles
//

import Foundation

// MARK: - Tipos de acciones que dan puntos
enum PointsAction: String, Codable {
    case createRouteSmall = "create_route_small"       // 3-4 paradas
    case createRouteMedium = "create_route_medium"     // 5-9 paradas
    case createRouteLarge = "create_route_large"       // 10+ paradas
    case completeRoute = "complete_route"              // Completar ruta 100%
    case firstRouteOfDay = "first_route_day"           // Primera ruta del día
    case streakThreeDays = "streak_three_days"         // Racha de 3 días
    case streakSevenDays = "streak_seven_days"         // Racha de 7 días
    case publishRoute = "publish_route"                // Publicar ruta
    case routeUsedByOthers = "route_used_by_others"    // Alguien usa tu ruta

    var points: Int {
        switch self {
        case .createRouteSmall: return 50
        case .createRouteMedium: return 100
        case .createRouteLarge: return 200
        case .completeRoute: return 30
        case .firstRouteOfDay: return 10
        case .streakThreeDays: return 50
        case .streakSevenDays: return 100
        case .publishRoute: return 20
        case .routeUsedByOthers: return 5
        }
    }

    var displayName: String {
        switch self {
        case .createRouteSmall: return "Crear ruta (3+ paradas)"
        case .createRouteMedium: return "Crear ruta (5+ paradas)"
        case .createRouteLarge: return "Crear ruta (10+ paradas)"
        case .completeRoute: return "Completar ruta"
        case .firstRouteOfDay: return "Primera ruta del día"
        case .streakThreeDays: return "Racha de 3 días"
        case .streakSevenDays: return "Racha de 7 días"
        case .publishRoute: return "Publicar ruta"
        case .routeUsedByOthers: return "Tu ruta fue usada"
        }
    }

    var icon: String {
        switch self {
        case .createRouteSmall, .createRouteMedium, .createRouteLarge: return "map.fill"
        case .completeRoute: return "checkmark.circle.fill"
        case .firstRouteOfDay: return "sun.max.fill"
        case .streakThreeDays, .streakSevenDays: return "flame.fill"
        case .publishRoute: return "paperplane.fill"
        case .routeUsedByOthers: return "person.2.fill"
        }
    }
}

// MARK: - Transacción de puntos
struct PointsTransaction: Identifiable, Codable {
    let id: String
    let action: PointsAction
    let points: Int
    let date: Date
    let routeId: String?
    let routeName: String?

    init(
        id: String = UUID().uuidString,
        action: PointsAction,
        points: Int? = nil,
        date: Date = Date(),
        routeId: String? = nil,
        routeName: String? = nil
    ) {
        self.id = id
        self.action = action
        self.points = points ?? action.points
        self.date = date
        self.routeId = routeId
        self.routeName = routeName
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Niveles de usuario
enum UserLevel: Int, Codable, CaseIterable {
    case explorer = 1
    case traveler = 2
    case localGuide = 3
    case expert = 4
    case master = 5

    var name: String {
        switch self {
        case .explorer: return "Explorador"
        case .traveler: return "Viajero"
        case .localGuide: return "Guía Local"
        case .expert: return "Experto"
        case .master: return "Maestro AudioCity"
        }
    }

    var icon: String {
        switch self {
        case .explorer: return "figure.walk"
        case .traveler: return "airplane"
        case .localGuide: return "map"
        case .expert: return "star.fill"
        case .master: return "crown.fill"
        }
    }

    var minPoints: Int {
        switch self {
        case .explorer: return 0
        case .traveler: return 100
        case .localGuide: return 300
        case .expert: return 600
        case .master: return 1000
        }
    }

    var maxPoints: Int {
        switch self {
        case .explorer: return 99
        case .traveler: return 299
        case .localGuide: return 599
        case .expert: return 999
        case .master: return Int.max
        }
    }

    /// Siguiente nivel (nil si es el máximo)
    var nextLevel: UserLevel? {
        switch self {
        case .explorer: return .traveler
        case .traveler: return .localGuide
        case .localGuide: return .expert
        case .expert: return .master
        case .master: return nil
        }
    }

    /// Obtener nivel basado en puntos
    static func level(for points: Int) -> UserLevel {
        if points >= 1000 { return .master }
        if points >= 600 { return .expert }
        if points >= 300 { return .localGuide }
        if points >= 100 { return .traveler }
        return .explorer
    }
}

// MARK: - Estadísticas del usuario
struct UserPointsStats: Codable {
    var totalPoints: Int
    var currentLevel: UserLevel
    var routesCreated: Int
    var routesCompleted: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?

    init(
        totalPoints: Int = 0,
        currentLevel: UserLevel = .explorer,
        routesCreated: Int = 0,
        routesCompleted: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActivityDate: Date? = nil
    ) {
        self.totalPoints = totalPoints
        self.currentLevel = currentLevel
        self.routesCreated = routesCreated
        self.routesCompleted = routesCompleted
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
    }

    /// Progreso hacia el siguiente nivel (0.0 - 1.0)
    var progressToNextLevel: Double {
        guard let nextLevel = currentLevel.nextLevel else { return 1.0 }
        let pointsInCurrentLevel = totalPoints - currentLevel.minPoints
        let pointsNeededForNext = nextLevel.minPoints - currentLevel.minPoints
        return Double(pointsInCurrentLevel) / Double(pointsNeededForNext)
    }

    /// Puntos restantes para el siguiente nivel
    var pointsToNextLevel: Int {
        guard let nextLevel = currentLevel.nextLevel else { return 0 }
        return nextLevel.minPoints - totalPoints
    }
}
