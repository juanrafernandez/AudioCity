//
//  ACUser.swift
//  AudioCityPOC
//
//  Modelo de usuario para autenticación
//

import Foundation

/// Proveedor de autenticación
enum AuthProvider: String, Codable {
    case apple
    case google
    case email
}

/// Usuario autenticado de AudioCity
struct ACUser: Codable, Identifiable {
    let id: String                    // Firebase UID
    var email: String?
    var displayName: String?
    var photoURL: String?
    var authProvider: AuthProvider
    let createdAt: Date
    var lastLoginAt: Date

    // Stats embebidos (sincronizados con PointsService)
    var stats: UserPointsStats?

    // Favoritos embebidos
    var favoriteRouteIds: [String]

    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: String? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        stats: UserPointsStats? = nil,
        favoriteRouteIds: [String] = []
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.stats = stats
        self.favoriteRouteIds = favoriteRouteIds
    }

    /// Nombre para mostrar (o email si no hay nombre)
    var displayNameOrEmail: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        if let email = email {
            return email.components(separatedBy: "@").first ?? email
        }
        return "Usuario"
    }

    /// Iniciales del usuario para avatar
    var initials: String {
        let name = displayName ?? email ?? "U"
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let second = components[1].prefix(1)
            return "\(first)\(second)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Firestore Conversion

extension ACUser {
    /// Convierte a diccionario para Firestore
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "authProvider": authProvider.rawValue,
            "createdAt": createdAt,
            "lastLoginAt": lastLoginAt,
            "favoriteRouteIds": favoriteRouteIds
        ]

        if let email = email {
            data["email"] = email
        }
        if let displayName = displayName {
            data["displayName"] = displayName
        }
        if let photoURL = photoURL {
            data["photoURL"] = photoURL
        }
        if let stats = stats {
            data["stats"] = [
                "totalPoints": stats.totalPoints,
                "currentLevel": stats.currentLevel.rawValue,
                "routesCreated": stats.routesCreated,
                "routesCompleted": stats.routesCompleted,
                "currentStreak": stats.currentStreak,
                "longestStreak": stats.longestStreak
            ]
        }

        return data
    }

    /// Crea un ACUser desde datos de Firestore
    static func fromFirestore(_ data: [String: Any], id: String) -> ACUser? {
        guard let providerString = data["authProvider"] as? String,
              let authProvider = AuthProvider(rawValue: providerString),
              let createdAt = (data["createdAt"] as? Date) ?? (data["createdAt"] as? Timestamp)?.dateValue(),
              let lastLoginAt = (data["lastLoginAt"] as? Date) ?? (data["lastLoginAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        var stats: UserPointsStats?
        if let statsData = data["stats"] as? [String: Any],
           let totalPoints = statsData["totalPoints"] as? Int,
           let levelRaw = statsData["currentLevel"] as? Int,
           let level = UserLevel(rawValue: levelRaw) {
            stats = UserPointsStats(
                totalPoints: totalPoints,
                currentLevel: level,
                routesCreated: statsData["routesCreated"] as? Int ?? 0,
                routesCompleted: statsData["routesCompleted"] as? Int ?? 0,
                currentStreak: statsData["currentStreak"] as? Int ?? 0,
                longestStreak: statsData["longestStreak"] as? Int ?? 0,
                lastActivityDate: nil
            )
        }

        return ACUser(
            id: id,
            email: data["email"] as? String,
            displayName: data["displayName"] as? String,
            photoURL: data["photoURL"] as? String,
            authProvider: authProvider,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            stats: stats,
            favoriteRouteIds: data["favoriteRouteIds"] as? [String] ?? []
        )
    }
}

// MARK: - Firebase Timestamp compatibility
import FirebaseFirestore

private extension Timestamp {
    func dateValue() -> Date {
        return self.dateValue()
    }
}
