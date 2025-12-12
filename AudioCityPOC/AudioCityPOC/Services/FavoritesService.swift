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

    // MARK: - Dependencies
    private let repository: FavoritesRepositoryProtocol

    // MARK: - Initialization
    init(repository: FavoritesRepositoryProtocol = FavoritesRepository()) {
        self.repository = repository
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
        do {
            favoriteRouteIds = try repository.loadFavorites()
            print("⭐ FavoritesService: \(favoriteRouteIds.count) favoritos cargados")
        } catch {
            print("❌ FavoritesService: Error cargando favoritos - \(error.localizedDescription)")
            favoriteRouteIds = []
        }
    }

    private func saveFavorites() {
        do {
            try repository.saveFavorites(favoriteRouteIds)
        } catch {
            print("❌ FavoritesService: Error guardando favoritos - \(error.localizedDescription)")
        }
    }
}
