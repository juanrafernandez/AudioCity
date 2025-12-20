//
//  FirebaseService.swift
//  AudioCityPOC
//
//  Servicio para cargar datos desde Firebase Firestore
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject, FirebaseServiceProtocol {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let db = Firestore.firestore()

    // MARK: - Routes Cache (TTL: 5 minutos)
    private var routesCache: [Route]?
    private var routesCacheTimestamp: Date?
    private let routesCacheTTL: TimeInterval = 300 // 5 minutos

    private var isCacheValid: Bool {
        guard routesCache != nil,
              let timestamp = routesCacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < routesCacheTTL
    }
    
    // MARK: - Public Methods
    
    /// Cargar una ruta por ID
    func fetchRoute(id: String) async throws -> Route {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Cargar documento de ruta
            let routeDoc = try await db.collection("routes").document(id).getDocument()
            
            guard routeDoc.exists else {
                throw FirebaseError.routeNotFound
            }
            
            // Decodificar ruta
            let route = try routeDoc.data(as: Route.self)

            Log("Ruta cargada - \(route.name)", level: .success, category: .firebase)
            return route

        } catch {
            errorMessage = error.localizedDescription
            Log("Error cargando ruta - \(error.localizedDescription)", level: .error, category: .firebase)
            throw error
        }
    }
    
    /// Cargar paradas de una ruta
    func fetchStops(for routeId: String) async throws -> [Stop] {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Query de paradas (sin ordenar en Firestore para evitar índice compuesto)
            let stopsQuery = db.collection("stops")
                .whereField("route_id", isEqualTo: routeId)

            let snapshot = try await stopsQuery.getDocuments()

            // Decodificar paradas
            var stops = try snapshot.documents.compactMap { doc in
                try doc.data(as: Stop.self)
            }

            // Ordenar por campo 'order' en cliente
            stops.sort { $0.order < $1.order }

            Log("\(stops.count) paradas cargadas y ordenadas", level: .success, category: .firebase)
            return stops

        } catch {
            errorMessage = error.localizedDescription
            Log("Error cargando paradas - \(error.localizedDescription)", level: .error, category: .firebase)
            throw error
        }
    }
    
    /// Cargar ruta completa con sus paradas
    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop]) {
        async let route = fetchRoute(id: routeId)
        async let stops = fetchStops(for: routeId)
        
        return try await (route, stops)
    }
    
    /// Cargar todas las rutas disponibles (con caché)
    func fetchAllRoutes() async throws -> [Route] {
        // Retornar caché si es válida
        if isCacheValid, let cached = routesCache {
            Log("\(cached.count) rutas desde caché", level: .debug, category: .firebase)
            return cached
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("routes")
                .whereField("is_active", isEqualTo: true)
                .getDocuments()

            let routes = try snapshot.documents.compactMap { doc in
                try doc.data(as: Route.self)
            }

            // Guardar en caché
            routesCache = routes
            routesCacheTimestamp = Date()

            Log("\(routes.count) rutas disponibles (cacheadas)", level: .success, category: .firebase)
            return routes

        } catch {
            errorMessage = error.localizedDescription
            Log("Error cargando rutas - \(error.localizedDescription)", level: .error, category: .firebase)
            throw error
        }
    }

    /// Invalidar caché de rutas (forzar recarga en próxima llamada)
    func invalidateRoutesCache() {
        routesCache = nil
        routesCacheTimestamp = nil
        Log("Caché de rutas invalidada", level: .debug, category: .firebase)
    }
}

// MARK: - Errors
enum FirebaseError: AppError {
    case routeNotFound
    case stopsNotFound
    case decodingError
    case networkError(Error)

    var code: String {
        switch self {
        case .routeNotFound: return "FB001"
        case .stopsNotFound: return "FB002"
        case .decodingError: return "FB003"
        case .networkError: return "FB004"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkError:
            return true
        case .routeNotFound, .stopsNotFound, .decodingError:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .routeNotFound:
            return "Ruta no encontrada"
        case .stopsNotFound:
            return "Paradas no encontradas"
        case .decodingError:
            return "Error decodificando datos"
        case .networkError(let error):
            return "Error de conexión: \(error.localizedDescription)"
        }
    }
}