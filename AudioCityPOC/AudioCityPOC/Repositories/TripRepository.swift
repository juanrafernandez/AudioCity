//
//  TripRepository.swift
//  AudioCityPOC
//
//  Repository para persistencia de viajes del usuario
//  Abstrae el almacenamiento de TripService
//

import Foundation

// MARK: - Trip Repository Protocol

protocol TripRepositoryProtocol {
    /// Carga todos los viajes
    func loadTrips() throws -> [Trip]

    /// Guarda todos los viajes
    func saveTrips(_ trips: [Trip]) throws

    /// Guarda un viaje individual
    func saveTrip(_ trip: Trip) throws

    /// Elimina un viaje por ID
    func deleteTrip(id: String) throws

    /// Verifica si existe un viaje
    func tripExists(id: String) -> Bool
}

// MARK: - Trip Repository Implementation

final class TripRepository: TripRepositoryProtocol {

    // MARK: - Dependencies
    private let storage: StorageRepositoryProtocol

    // MARK: - Initialization

    init(storage: StorageRepositoryProtocol = UserDefaultsStorageRepository()) {
        self.storage = storage
    }

    // MARK: - TripRepositoryProtocol

    func loadTrips() throws -> [Trip] {
        let trips: [Trip]? = try storage.load(forKey: StorageKeys.trips)
        return trips ?? []
    }

    func saveTrips(_ trips: [Trip]) throws {
        try storage.save(trips, forKey: StorageKeys.trips)
    }

    func saveTrip(_ trip: Trip) throws {
        var trips = try loadTrips()

        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        } else {
            trips.append(trip)
        }

        try saveTrips(trips)
    }

    func deleteTrip(id: String) throws {
        var trips = try loadTrips()
        trips.removeAll { $0.id == id }
        try saveTrips(trips)
    }

    func tripExists(id: String) -> Bool {
        guard let trips: [Trip] = try? loadTrips() else { return false }
        return trips.contains { $0.id == id }
    }
}

// MARK: - Favorites Repository Protocol

protocol FavoritesRepositoryProtocol {
    /// Carga los IDs de rutas favoritas
    func loadFavorites() throws -> Set<String>

    /// Guarda los IDs de rutas favoritas
    func saveFavorites(_ favoriteIds: Set<String>) throws

    /// Añade un favorito
    func addFavorite(_ routeId: String) throws

    /// Elimina un favorito
    func removeFavorite(_ routeId: String) throws
}

// MARK: - Favorites Repository Implementation

final class FavoritesRepository: FavoritesRepositoryProtocol {

    // MARK: - Dependencies
    private let storage: StorageRepositoryProtocol

    // MARK: - Initialization

    init(storage: StorageRepositoryProtocol = UserDefaultsStorageRepository()) {
        self.storage = storage
    }

    // MARK: - FavoritesRepositoryProtocol

    func loadFavorites() throws -> Set<String> {
        let favorites: Set<String>? = try storage.load(forKey: StorageKeys.favorites)
        return favorites ?? []
    }

    func saveFavorites(_ favoriteIds: Set<String>) throws {
        try storage.save(favoriteIds, forKey: StorageKeys.favorites)
    }

    func addFavorite(_ routeId: String) throws {
        var favorites = try loadFavorites()
        favorites.insert(routeId)
        try saveFavorites(favorites)
    }

    func removeFavorite(_ routeId: String) throws {
        var favorites = try loadFavorites()
        favorites.remove(routeId)
        try saveFavorites(favorites)
    }
}

#if DEBUG
// MARK: - Mock Repositories for Tests

final class MockTripRepository: TripRepositoryProtocol {
    var mockTrips: [Trip] = []
    var shouldFail = false

    func loadTrips() throws -> [Trip] {
        if shouldFail { throw StorageError.notFound("trips") }
        return mockTrips
    }

    func saveTrips(_ trips: [Trip]) throws {
        if shouldFail { throw StorageError.writeFailed(NSError(domain: "", code: -1)) }
        mockTrips = trips
    }

    func saveTrip(_ trip: Trip) throws {
        if let index = mockTrips.firstIndex(where: { $0.id == trip.id }) {
            mockTrips[index] = trip
        } else {
            mockTrips.append(trip)
        }
    }

    func deleteTrip(id: String) throws {
        mockTrips.removeAll { $0.id == id }
    }

    func tripExists(id: String) -> Bool {
        return mockTrips.contains { $0.id == id }
    }
}

final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    var mockFavorites: Set<String> = []

    func loadFavorites() throws -> Set<String> { mockFavorites }
    func saveFavorites(_ favoriteIds: Set<String>) throws { mockFavorites = favoriteIds }
    func addFavorite(_ routeId: String) throws { mockFavorites.insert(routeId) }
    func removeFavorite(_ routeId: String) throws { mockFavorites.remove(routeId) }
}
#endif
