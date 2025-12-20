//
//  RouteRepository.swift
//  AudioCityPOC
//
//  Repository para acceso a datos de rutas
//  Abstrae la fuente de datos (Firebase, cache local, mock)
//

import Foundation
import Combine

// MARK: - Route Repository Protocol

/// Protocolo para acceso a datos de rutas
/// Permite cambiar la implementación (Firebase, mock, etc.) sin afectar a los consumidores
protocol RouteRepositoryProtocol {
    /// Carga todas las rutas disponibles
    func fetchAllRoutes() async throws -> [Route]

    /// Carga una ruta específica por ID
    func fetchRoute(id: String) async throws -> Route

    /// Carga las paradas de una ruta
    func fetchStops(for routeId: String) async throws -> [Stop]

    /// Carga ruta completa con sus paradas
    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop])

    /// Busca rutas por ciudad
    func fetchRoutes(forCity city: String) async throws -> [Route]
}

// MARK: - Firebase Route Repository

/// Implementación del repositorio usando Firebase
final class FirebaseRouteRepository: RouteRepositoryProtocol {

    // MARK: - Dependencies
    private let firebaseService: FirebaseService

    // MARK: - Initialization
    init(firebaseService: FirebaseService = FirebaseService()) {
        self.firebaseService = firebaseService
    }

    // MARK: - RouteRepositoryProtocol

    func fetchAllRoutes() async throws -> [Route] {
        return try await firebaseService.fetchAllRoutes()
    }

    func fetchRoute(id: String) async throws -> Route {
        return try await firebaseService.fetchRoute(id: id)
    }

    func fetchStops(for routeId: String) async throws -> [Stop] {
        return try await firebaseService.fetchStops(for: routeId)
    }

    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop]) {
        return try await firebaseService.fetchCompleteRoute(routeId: routeId)
    }

    func fetchRoutes(forCity city: String) async throws -> [Route] {
        let allRoutes = try await fetchAllRoutes()
        return allRoutes.filter { $0.city.lowercased() == city.lowercased() }
    }
}

// MARK: - Cached Route Repository

/// Implementación del repositorio con cache en memoria
final class CachedRouteRepository: RouteRepositoryProtocol {

    // MARK: - Dependencies
    private let remoteRepository: RouteRepositoryProtocol

    // MARK: - Cache
    private var routesCache: [Route]?
    private var stopsCache: [String: [Stop]] = [:]
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutos

    // MARK: - Initialization
    init(remoteRepository: RouteRepositoryProtocol) {
        self.remoteRepository = remoteRepository
    }

    // MARK: - RouteRepositoryProtocol

    func fetchAllRoutes() async throws -> [Route] {
        // Verificar cache
        if let cached = routesCache,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            Log("Usando cache de rutas", level: .debug, category: .route)
            return cached
        }

        // Fetch remoto
        let routes = try await remoteRepository.fetchAllRoutes()

        // Guardar en cache
        routesCache = routes
        cacheTimestamp = Date()
        Log("Cache de rutas actualizado", level: .debug, category: .route)

        return routes
    }

    func fetchRoute(id: String) async throws -> Route {
        // Buscar en cache primero
        if let cached = routesCache?.first(where: { $0.id == id }) {
            Log("Ruta encontrada en cache", level: .debug, category: .route)
            return cached
        }

        return try await remoteRepository.fetchRoute(id: id)
    }

    func fetchStops(for routeId: String) async throws -> [Stop] {
        // Verificar cache
        if let cached = stopsCache[routeId] {
            Log("Paradas encontradas en cache", level: .debug, category: .route)
            return cached
        }

        // Fetch remoto
        let stops = try await remoteRepository.fetchStops(for: routeId)

        // Guardar en cache
        stopsCache[routeId] = stops
        Log("Cache de paradas actualizado", level: .debug, category: .route)

        return stops
    }

    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop]) {
        async let route = fetchRoute(id: routeId)
        async let stops = fetchStops(for: routeId)
        return try await (route, stops)
    }

    func fetchRoutes(forCity city: String) async throws -> [Route] {
        let allRoutes = try await fetchAllRoutes()
        return allRoutes.filter { $0.city.lowercased() == city.lowercased() }
    }

    // MARK: - Cache Management

    /// Invalida todo el cache
    func invalidateCache() {
        routesCache = nil
        stopsCache.removeAll()
        cacheTimestamp = nil
        Log("Cache invalidado", level: .info, category: .route)
    }

    /// Invalida el cache de paradas de una ruta específica
    func invalidateStopsCache(for routeId: String) {
        stopsCache.removeValue(forKey: routeId)
    }
}

// MARK: - Mock Route Repository (para tests)

#if DEBUG
/// Implementación mock del repositorio para tests
final class MockRouteRepository: RouteRepositoryProtocol {

    var mockRoutes: [Route] = []
    var mockStops: [String: [Stop]] = [:]
    var shouldFail = false
    var failureError: Error = NSError(domain: "MockError", code: -1)

    func fetchAllRoutes() async throws -> [Route] {
        if shouldFail { throw failureError }
        return mockRoutes
    }

    func fetchRoute(id: String) async throws -> Route {
        if shouldFail { throw failureError }
        guard let route = mockRoutes.first(where: { $0.id == id }) else {
            throw FirebaseError.routeNotFound
        }
        return route
    }

    func fetchStops(for routeId: String) async throws -> [Stop] {
        if shouldFail { throw failureError }
        return mockStops[routeId] ?? []
    }

    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop]) {
        let route = try await fetchRoute(id: routeId)
        let stops = try await fetchStops(for: routeId)
        return (route, stops)
    }

    func fetchRoutes(forCity city: String) async throws -> [Route] {
        if shouldFail { throw failureError }
        return mockRoutes.filter { $0.city.lowercased() == city.lowercased() }
    }
}
#endif
