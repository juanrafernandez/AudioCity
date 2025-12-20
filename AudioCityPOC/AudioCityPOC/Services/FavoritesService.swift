//
//  FavoritesService.swift
//  AudioCityPOC
//
//  Servicio para gestionar rutas favoritas del usuario
//

import Foundation
import Combine

class FavoritesService: ObservableObject, FavoritesServiceProtocol {

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
        Log("Ruta añadida a favoritos - \(routeId)", level: .info, category: .app)
    }

    /// Eliminar ruta de favoritos
    func removeFavorite(_ routeId: String) {
        favoriteRouteIds.remove(routeId)
        saveFavorites()
        Log("Ruta eliminada de favoritos - \(routeId)", level: .info, category: .app)
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
            Log("\(favoriteRouteIds.count) favoritos cargados", level: .success, category: .app)
        } catch {
            Log("Error cargando favoritos - \(error.localizedDescription)", level: .error, category: .app)
            favoriteRouteIds = []
        }
    }

    private func saveFavorites() {
        do {
            try repository.saveFavorites(favoriteRouteIds)
        } catch {
            Log("Error guardando favoritos - \(error.localizedDescription)", level: .error, category: .app)
        }
    }
}
