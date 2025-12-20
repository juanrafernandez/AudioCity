//
//  OfflineCacheService.swift
//  AudioCityPOC
//
//  Servicio para gestionar la caché offline de rutas y mapas
//

import Foundation
import MapKit
import Combine

class OfflineCacheService: ObservableObject {

    // MARK: - Published Properties
    @Published var cachedRoutes: [CachedRoute] = []
    @Published var downloadProgress: TripCacheProgress?
    @Published var isDownloading = false
    @Published var totalCacheSize: Int64 = 0

    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private let cacheDirectoryName = "AudioCityOfflineCache"
    private let cachedRoutesKey = "cachedRoutes"

    // MARK: - Initialization
    init() {
        createCacheDirectoryIfNeeded()
        loadCachedRoutes()
        calculateTotalCacheSize()
    }

    // MARK: - Public Methods

    /// Descargar rutas de un viaje para uso offline
    func downloadTrip(_ trip: Trip, routes: [Route], stops: [[Stop]]) async throws {
        guard routes.count == stops.count else {
            throw CacheError.invalidData
        }

        await MainActor.run {
            self.isDownloading = true
            self.downloadProgress = TripCacheProgress(
                id: UUID().uuidString,
                tripId: trip.id,
                totalRoutes: routes.count,
                cachedRoutes: 0,
                currentDownloadingRoute: nil,
                downloadProgress: 0,
                status: .downloading
            )
        }

        do {
            for (index, route) in routes.enumerated() {
                await MainActor.run {
                    self.downloadProgress?.currentDownloadingRoute = route.name
                    self.downloadProgress?.downloadProgress = Double(index) / Double(routes.count)
                }

                // Crear entrada de caché para esta ruta
                let cachedRoute = CachedRoute(
                    tripId: trip.id,
                    route: route,
                    stops: stops[index],
                    totalSizeBytes: estimateRouteSize(route: route, stops: stops[index])
                )

                // Guardar datos de la ruta localmente
                try await cacheRouteData(cachedRoute)

                await MainActor.run {
                    self.cachedRoutes.append(cachedRoute)
                    self.downloadProgress?.cachedRoutes = index + 1
                }
            }

            await MainActor.run {
                self.downloadProgress?.status = .completed
                self.downloadProgress?.downloadProgress = 1.0
                self.isDownloading = false
            }

            // Persistir lista de rutas en caché
            saveCachedRoutesList()
            calculateTotalCacheSize()

            Log("Viaje descargado - \(routes.count) rutas", level: .success, category: .app)

        } catch {
            await MainActor.run {
                self.downloadProgress?.status = .failed
                self.downloadProgress?.errorMessage = error.localizedDescription
                self.isDownloading = false
            }
            throw error
        }
    }

    /// Verificar si una ruta está en caché
    func isRouteCached(routeId: String) -> Bool {
        return cachedRoutes.contains { $0.route.id == routeId }
    }

    /// Verificar si un viaje tiene todas sus rutas en caché
    func isTripFullyCached(trip: Trip) -> Bool {
        return trip.selectedRouteIds.allSatisfy { routeId in
            isRouteCached(routeId: routeId)
        }
    }

    /// Obtener ruta desde caché
    func getCachedRoute(routeId: String) -> CachedRoute? {
        return cachedRoutes.first { $0.route.id == routeId }
    }

    /// Obtener todas las rutas cacheadas de un viaje
    func getCachedRoutes(for trip: Trip) -> [CachedRoute] {
        return cachedRoutes.filter { $0.tripId == trip.id }
    }

    /// Eliminar caché de un viaje
    func deleteCache(for trip: Trip) throws {
        let tripCachedRoutes = cachedRoutes.filter { $0.tripId == trip.id }

        for cachedRoute in tripCachedRoutes {
            try deleteCachedRouteFiles(cachedRoute)
        }

        cachedRoutes.removeAll { $0.tripId == trip.id }
        saveCachedRoutesList()
        calculateTotalCacheSize()

        Log("Caché eliminada para viaje - \(trip.destinationCity)", level: .info, category: .app)
    }

    /// Eliminar toda la caché
    func clearAllCache() throws {
        let cacheURL = getCacheDirectoryURL()
        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }

        cachedRoutes.removeAll()
        saveCachedRoutesList()
        createCacheDirectoryIfNeeded()
        totalCacheSize = 0

        Log("Toda la caché eliminada", level: .info, category: .app)
    }

    /// Obtener tamaño de caché formateado
    func formattedCacheSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalCacheSize)
    }

    // MARK: - Private Methods

    private func getCacheDirectoryURL() -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(cacheDirectoryName)
    }

    private func createCacheDirectoryIfNeeded() {
        let cacheURL = getCacheDirectoryURL()
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
    }

    private func cacheRouteData(_ cachedRoute: CachedRoute) async throws {
        let routeDirectoryURL = getCacheDirectoryURL()
            .appendingPathComponent(cachedRoute.tripId)
            .appendingPathComponent(cachedRoute.route.id)

        // Crear directorio para la ruta
        try fileManager.createDirectory(at: routeDirectoryURL, withIntermediateDirectories: true)

        // Guardar datos de la ruta como JSON
        let routeDataURL = routeDirectoryURL.appendingPathComponent("route_data.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let routeData = try encoder.encode(cachedRoute)
        try routeData.write(to: routeDataURL)

        // TODO: Descargar tiles del mapa para la región
        // Esto requiere implementación específica según el proveedor de mapas
        // Por ahora marcamos la ruta como que tiene los datos básicos

        Log("Ruta guardada - \(cachedRoute.route.name)", level: .debug, category: .app)
    }

    private func deleteCachedRouteFiles(_ cachedRoute: CachedRoute) throws {
        let routeDirectoryURL = getCacheDirectoryURL()
            .appendingPathComponent(cachedRoute.tripId)
            .appendingPathComponent(cachedRoute.route.id)

        if fileManager.fileExists(atPath: routeDirectoryURL.path) {
            try fileManager.removeItem(at: routeDirectoryURL)
        }
    }

    private func loadCachedRoutes() {
        guard let data = userDefaults.data(forKey: cachedRoutesKey) else {
            cachedRoutes = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            cachedRoutes = try decoder.decode([CachedRoute].self, from: data)
            Log("\(cachedRoutes.count) rutas cargadas desde caché", level: .success, category: .app)
        } catch {
            Log("Error cargando rutas - \(error.localizedDescription)", level: .error, category: .app)
            cachedRoutes = []
        }
    }

    private func saveCachedRoutesList() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(cachedRoutes)
            userDefaults.set(data, forKey: cachedRoutesKey)
        } catch {
            Log("Error guardando lista - \(error.localizedDescription)", level: .error, category: .app)
        }
    }

    private func calculateTotalCacheSize() {
        totalCacheSize = cachedRoutes.reduce(0) { $0 + $1.totalSizeBytes }
    }

    private func estimateRouteSize(route: Route, stops: [Stop]) -> Int64 {
        // Estimación básica: ~50KB por ruta + ~10KB por parada
        // En producción esto sería más preciso después de la descarga real
        let baseSize: Int64 = 50_000
        let perStopSize: Int64 = 10_000
        return baseSize + (Int64(stops.count) * perStopSize)
    }
}

// MARK: - Errors
enum CacheError: LocalizedError {
    case invalidData
    case downloadFailed
    case insufficientStorage
    case fileSystemError

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Datos inválidos"
        case .downloadFailed:
            return "Error en la descarga"
        case .insufficientStorage:
            return "Espacio insuficiente"
        case .fileSystemError:
            return "Error de sistema de archivos"
        }
    }
}
