//
//  PointsRepository.swift
//  AudioCityPOC
//
//  Repository para persistencia de puntos y gamificación
//  Abstrae el almacenamiento de PointsService
//

import Foundation

// MARK: - Points Repository Protocol

protocol PointsRepositoryProtocol {
    /// Carga las estadísticas de puntos del usuario
    func loadStats() throws -> UserPointsStats

    /// Guarda las estadísticas de puntos
    func saveStats(_ stats: UserPointsStats) throws

    /// Carga el historial de transacciones
    func loadTransactions() throws -> [PointsTransaction]

    /// Guarda el historial de transacciones
    func saveTransactions(_ transactions: [PointsTransaction]) throws

    /// Añade una transacción al historial
    func addTransaction(_ transaction: PointsTransaction) throws

    /// Carga la fecha de última completación de ruta
    func loadLastCompletionDate() throws -> Date?

    /// Guarda la fecha de última completación de ruta
    func saveLastCompletionDate(_ date: Date) throws
}

// MARK: - Points Repository Implementation

final class PointsRepository: PointsRepositoryProtocol {

    // MARK: - Dependencies
    private let storage: StorageRepositoryProtocol

    // MARK: - Initialization

    init(storage: StorageRepositoryProtocol = UserDefaultsStorageRepository()) {
        self.storage = storage
    }

    // MARK: - PointsRepositoryProtocol

    func loadStats() throws -> UserPointsStats {
        let stats: UserPointsStats? = try storage.load(forKey: StorageKeys.points)
        return stats ?? UserPointsStats()
    }

    func saveStats(_ stats: UserPointsStats) throws {
        try storage.save(stats, forKey: StorageKeys.points)
    }

    func loadTransactions() throws -> [PointsTransaction] {
        let transactions: [PointsTransaction]? = try storage.load(forKey: StorageKeys.pointsTransactions)
        return transactions ?? []
    }

    func saveTransactions(_ transactions: [PointsTransaction]) throws {
        try storage.save(transactions, forKey: StorageKeys.pointsTransactions)
    }

    func addTransaction(_ transaction: PointsTransaction) throws {
        var transactions = try loadTransactions()
        transactions.insert(transaction, at: 0) // Más reciente primero
        try saveTransactions(transactions)
    }

    func loadLastCompletionDate() throws -> Date? {
        return try storage.load(forKey: StorageKeys.lastRouteCompletionDate)
    }

    func saveLastCompletionDate(_ date: Date) throws {
        try storage.save(date, forKey: StorageKeys.lastRouteCompletionDate)
    }
}

// MARK: - User Routes Repository Protocol

protocol UserRoutesRepositoryProtocol {
    /// Carga todas las rutas creadas por el usuario
    func loadUserRoutes() throws -> [UserRoute]

    /// Guarda todas las rutas del usuario
    func saveUserRoutes(_ routes: [UserRoute]) throws

    /// Guarda una ruta individual
    func saveUserRoute(_ route: UserRoute) throws

    /// Elimina una ruta por ID
    func deleteUserRoute(id: String) throws

    /// Obtiene una ruta por ID
    func getUserRoute(id: String) throws -> UserRoute?
}

// MARK: - User Routes Repository Implementation

final class UserRoutesRepository: UserRoutesRepositoryProtocol {

    // MARK: - Dependencies
    private let storage: StorageRepositoryProtocol

    // MARK: - Initialization

    init(storage: StorageRepositoryProtocol = UserDefaultsStorageRepository()) {
        self.storage = storage
    }

    // MARK: - UserRoutesRepositoryProtocol

    func loadUserRoutes() throws -> [UserRoute] {
        let routes: [UserRoute]? = try storage.load(forKey: StorageKeys.userRoutes)
        return routes ?? []
    }

    func saveUserRoutes(_ routes: [UserRoute]) throws {
        try storage.save(routes, forKey: StorageKeys.userRoutes)
    }

    func saveUserRoute(_ route: UserRoute) throws {
        var routes = try loadUserRoutes()

        if let index = routes.firstIndex(where: { $0.id == route.id }) {
            routes[index] = route
        } else {
            routes.append(route)
        }

        try saveUserRoutes(routes)
    }

    func deleteUserRoute(id: String) throws {
        var routes = try loadUserRoutes()
        routes.removeAll { $0.id == id }
        try saveUserRoutes(routes)
    }

    func getUserRoute(id: String) throws -> UserRoute? {
        let routes = try loadUserRoutes()
        return routes.first { $0.id == id }
    }
}

#if DEBUG
// MARK: - Mock Repositories for Tests

final class MockPointsRepository: PointsRepositoryProtocol {
    var mockStats = UserPointsStats()
    var mockTransactions: [PointsTransaction] = []
    var mockLastCompletionDate: Date?
    var shouldFail = false

    func loadStats() throws -> UserPointsStats {
        if shouldFail { throw StorageError.notFound("stats") }
        return mockStats
    }

    func saveStats(_ stats: UserPointsStats) throws {
        if shouldFail { throw StorageError.writeFailed(NSError(domain: "", code: -1)) }
        mockStats = stats
    }

    func loadTransactions() throws -> [PointsTransaction] {
        return mockTransactions
    }

    func saveTransactions(_ transactions: [PointsTransaction]) throws {
        mockTransactions = transactions
    }

    func addTransaction(_ transaction: PointsTransaction) throws {
        mockTransactions.insert(transaction, at: 0)
    }

    func loadLastCompletionDate() throws -> Date? {
        return mockLastCompletionDate
    }

    func saveLastCompletionDate(_ date: Date) throws {
        mockLastCompletionDate = date
    }
}

final class MockUserRoutesRepository: UserRoutesRepositoryProtocol {
    var mockRoutes: [UserRoute] = []

    func loadUserRoutes() throws -> [UserRoute] { mockRoutes }
    func saveUserRoutes(_ routes: [UserRoute]) throws { mockRoutes = routes }

    func saveUserRoute(_ route: UserRoute) throws {
        if let index = mockRoutes.firstIndex(where: { $0.id == route.id }) {
            mockRoutes[index] = route
        } else {
            mockRoutes.append(route)
        }
    }

    func deleteUserRoute(id: String) throws {
        mockRoutes.removeAll { $0.id == id }
    }

    func getUserRoute(id: String) throws -> UserRoute? {
        mockRoutes.first { $0.id == id }
    }
}
#endif
