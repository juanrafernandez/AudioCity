//
//  FirebaseService.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//


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

class FirebaseService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
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
            
            print("✅ FirebaseService: Ruta cargada - \(route.name)")
            return route
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ FirebaseService: Error cargando ruta - \(error.localizedDescription)")
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

            print("✅ FirebaseService: \(stops.count) paradas cargadas y ordenadas")
            return stops

        } catch {
            errorMessage = error.localizedDescription
            print("❌ FirebaseService: Error cargando paradas - \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Cargar ruta completa con sus paradas
    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop]) {
        async let route = fetchRoute(id: routeId)
        async let stops = fetchStops(for: routeId)
        
        return try await (route, stops)
    }
    
    /// Cargar todas las rutas disponibles
    func fetchAllRoutes() async throws -> [Route] {
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
            
            print("✅ FirebaseService: \(routes.count) rutas disponibles")
            return routes
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ FirebaseService: Error cargando rutas - \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Errors
enum FirebaseError: LocalizedError {
    case routeNotFound
    case stopsNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .routeNotFound:
            return "Ruta no encontrada"
        case .stopsNotFound:
            return "Paradas no encontradas"
        case .decodingError:
            return "Error decodificando datos"
        }
    }
}