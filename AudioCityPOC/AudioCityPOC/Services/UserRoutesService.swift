//
//  UserRoutesService.swift
//  AudioCityPOC
//
//  Servicio para gestionar rutas creadas por el usuario
//

import Foundation
import Combine
import SwiftUI

class UserRoutesService: ObservableObject {

    // MARK: - Singleton
    static let shared = UserRoutesService()

    // MARK: - Published Properties
    @Published var userRoutes: [UserRoute] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let routesKey = "userCreatedRoutes"

    // MARK: - Initialization
    init() {
        loadRoutes()
    }

    // MARK: - Public Methods

    /// Crear una nueva ruta
    func createRoute(name: String, city: String, description: String = "", neighborhood: String = "") -> UserRoute {
        var route = UserRoute(
            name: name,
            description: description,
            city: city,
            neighborhood: neighborhood
        )

        userRoutes.append(route)
        saveRoutes()

        print("✅ UserRoutesService: Ruta creada - \(name)")
        return route
    }

    /// Actualizar una ruta existente
    func updateRoute(_ route: UserRoute) {
        guard let index = userRoutes.firstIndex(where: { $0.id == route.id }) else {
            print("❌ UserRoutesService: Ruta no encontrada - \(route.id)")
            return
        }

        var updatedRoute = route
        updatedRoute.updatedAt = Date()
        updatedRoute.calculateDistance()
        updatedRoute.estimateDuration()

        userRoutes[index] = updatedRoute
        saveRoutes()

        print("✅ UserRoutesService: Ruta actualizada - \(route.name)")
    }

    /// Eliminar una ruta
    func deleteRoute(_ routeId: String) {
        userRoutes.removeAll { $0.id == routeId }
        saveRoutes()
        print("🗑️ UserRoutesService: Ruta eliminada")
    }

    /// Añadir parada a una ruta
    func addStop(to routeId: String, stop: UserStop) {
        guard let index = userRoutes.firstIndex(where: { $0.id == routeId }) else {
            return
        }

        let previousStopCount = userRoutes[index].stops.count

        var newStop = stop
        newStop.order = previousStopCount + 1

        userRoutes[index].stops.append(newStop)
        userRoutes[index].updatedAt = Date()
        userRoutes[index].calculateDistance()
        userRoutes[index].estimateDuration()

        saveRoutes()

        // Otorgar puntos si la ruta alcanza 3+ paradas por primera vez
        let newStopCount = userRoutes[index].stops.count
        if previousStopCount < 3 && newStopCount >= 3 {
            PointsService.shared.awardPointsForCreatingRoute(
                routeId: routeId,
                routeName: userRoutes[index].name,
                stopsCount: newStopCount
            )
        } else if (previousStopCount < 5 && newStopCount >= 5) ||
                  (previousStopCount < 10 && newStopCount >= 10) {
            // Bonus por alcanzar 5 o 10 paradas (diferencia de puntos)
            PointsService.shared.awardPointsForCreatingRoute(
                routeId: routeId,
                routeName: userRoutes[index].name,
                stopsCount: newStopCount
            )
        }

        print("✅ UserRoutesService: Parada añadida - \(stop.name)")
    }

    /// Eliminar parada de una ruta
    func removeStop(from routeId: String, stopId: String) {
        guard let routeIndex = userRoutes.firstIndex(where: { $0.id == routeId }) else {
            return
        }

        userRoutes[routeIndex].stops.removeAll { $0.id == stopId }

        // Reordenar paradas
        for i in 0..<userRoutes[routeIndex].stops.count {
            userRoutes[routeIndex].stops[i].order = i + 1
        }

        userRoutes[routeIndex].updatedAt = Date()
        userRoutes[routeIndex].calculateDistance()
        userRoutes[routeIndex].estimateDuration()

        saveRoutes()
        print("✅ UserRoutesService: Parada eliminada")
    }

    /// Reordenar paradas
    func reorderStops(in routeId: String, from source: IndexSet, to destination: Int) {
        guard let routeIndex = userRoutes.firstIndex(where: { $0.id == routeId }) else {
            return
        }

        userRoutes[routeIndex].stops.move(fromOffsets: source, toOffset: destination)

        // Actualizar orden
        for i in 0..<userRoutes[routeIndex].stops.count {
            userRoutes[routeIndex].stops[i].order = i + 1
        }

        userRoutes[routeIndex].updatedAt = Date()
        saveRoutes()
    }

    /// Obtener ruta por ID
    func getRoute(by id: String) -> UserRoute? {
        return userRoutes.first { $0.id == id }
    }

    /// Publicar/despublicar ruta
    func togglePublish(_ routeId: String) {
        guard let index = userRoutes.firstIndex(where: { $0.id == routeId }) else {
            return
        }

        let wasPublished = userRoutes[index].isPublished
        userRoutes[index].isPublished.toggle()
        userRoutes[index].updatedAt = Date()
        saveRoutes()

        // Otorgar puntos solo al publicar (no al despublicar)
        if !wasPublished && userRoutes[index].isPublished {
            PointsService.shared.awardPointsForPublishingRoute(
                routeId: routeId,
                routeName: userRoutes[index].name
            )
        }

        let status = userRoutes[index].isPublished ? "publicada" : "despublicada"
        print("✅ UserRoutesService: Ruta \(status)")
    }

    // MARK: - Private Methods

    private func loadRoutes() {
        guard let data = userDefaults.data(forKey: routesKey) else {
            userRoutes = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            userRoutes = try decoder.decode([UserRoute].self, from: data)
            print("✅ UserRoutesService: \(userRoutes.count) rutas cargadas")
        } catch {
            print("❌ UserRoutesService: Error cargando rutas - \(error.localizedDescription)")
            userRoutes = []
        }
    }

    private func saveRoutes() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(userRoutes)
            userDefaults.set(data, forKey: routesKey)
        } catch {
            print("❌ UserRoutesService: Error guardando rutas - \(error.localizedDescription)")
        }
    }
}
