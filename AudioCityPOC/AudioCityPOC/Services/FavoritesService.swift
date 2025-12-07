//
//  FavoritesService.swift
//  AudioCityPOC
//
//  Servicio para gestionar rutas favoritas del usuario
//

import Foundation
import Combine

class FavoritesService: ObservableObject {

    // MARK: - Published Properties
    @Published var favoriteRouteIds: Set<String> = []

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "favoriteRouteIds"

    // MARK: - Initialization
    init() {
        loadFavorites()
    }

    // MARK: - Public Methods

    /// Verificar si una ruta es favorita
    func isFavorite(_ routeId: String) -> Bool {
        favoriteRouteIds.contains(routeId)
    }

    /// Añadir ruta a favoritos
    func addFavorite(_ routeId: String) {
        favoriteRouteIds.insert(routeId)
        saveFavorites()
        print("⭐ FavoritesService: Ruta añadida a favoritos - \(routeId)")
    }

    /// Eliminar ruta de favoritos
    func removeFavorite(_ routeId: String) {
        favoriteRouteIds.remove(routeId)
        saveFavorites()
        print("⭐ FavoritesService: Ruta eliminada de favoritos - \(routeId)")
    }

    /// Toggle favorito
    func toggleFavorite(_ routeId: String) {
        if isFavorite(routeId) {
            removeFavorite(routeId)
        } else {
            addFavorite(routeId)
        }
    }

    /// Obtener rutas favoritas de una lista
    func filterFavorites(from routes: [Route]) -> [Route] {
        routes.filter { favoriteRouteIds.contains($0.id) }
    }

    /// Número de favoritos
    var count: Int {
        favoriteRouteIds.count
    }

    // MARK: - Private Methods

    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteRouteIds = ids
            print("⭐ FavoritesService: \(ids.count) favoritos cargados")
        }
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteRouteIds) {
            userDefaults.set(data, forKey: favoritesKey)
        }
    }
}
