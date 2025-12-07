//
//  CachedRoute.swift
//  AudioCityPOC
//
//  Modelo para almacenar rutas en caché offline
//

import Foundation
import CoreLocation

/// Información de una ruta guardada para uso offline
struct CachedRoute: Identifiable, Codable {
    let id: String
    let tripId: String
    let route: Route
    let stops: [Stop]
    let cachedAt: Date
    var mapTilesPath: String?
    var audioFilesPath: String?
    var totalSizeBytes: Int64

    init(
        id: String = UUID().uuidString,
        tripId: String,
        route: Route,
        stops: [Stop],
        cachedAt: Date = Date(),
        mapTilesPath: String? = nil,
        audioFilesPath: String? = nil,
        totalSizeBytes: Int64 = 0
    ) {
        self.id = id
        self.tripId = tripId
        self.route = route
        self.stops = stops
        self.cachedAt = cachedAt
        self.mapTilesPath = mapTilesPath
        self.audioFilesPath = audioFilesPath
        self.totalSizeBytes = totalSizeBytes
    }

    /// Tamaño formateado para mostrar
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }

    /// Región del mapa que cubre la ruta (para descargar tiles)
    var mapRegion: MapRegion {
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude

        // Incluir todas las coordenadas de las paradas
        for stop in stops {
            minLat = min(minLat, stop.latitude)
            maxLat = max(maxLat, stop.latitude)
            minLon = min(minLon, stop.longitude)
            maxLon = max(maxLon, stop.longitude)
        }

        // Incluir inicio y fin de ruta
        minLat = min(minLat, route.startLocation.latitude)
        maxLat = max(maxLat, route.startLocation.latitude)
        minLon = min(minLon, route.startLocation.longitude)
        maxLon = max(maxLon, route.startLocation.longitude)

        minLat = min(minLat, route.endLocation.latitude)
        maxLat = max(maxLat, route.endLocation.latitude)
        minLon = min(minLon, route.endLocation.longitude)
        maxLon = max(maxLon, route.endLocation.longitude)

        // Añadir padding del 10%
        let latPadding = (maxLat - minLat) * 0.1
        let lonPadding = (maxLon - minLon) * 0.1

        return MapRegion(
            minLatitude: minLat - latPadding,
            maxLatitude: maxLat + latPadding,
            minLongitude: minLon - lonPadding,
            maxLongitude: maxLon + lonPadding
        )
    }
}

/// Región del mapa para descarga de tiles
struct MapRegion: Codable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    var centerLatitude: Double {
        (minLatitude + maxLatitude) / 2
    }

    var centerLongitude: Double {
        (minLongitude + maxLongitude) / 2
    }

    var latitudeDelta: Double {
        maxLatitude - minLatitude
    }

    var longitudeDelta: Double {
        maxLongitude - minLongitude
    }

    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
}

/// Estado de descarga de caché
enum CacheDownloadStatus: String, Codable {
    case notStarted = "not_started"
    case downloading = "downloading"
    case completed = "completed"
    case failed = "failed"
    case partiallyCompleted = "partially_completed"
}

/// Progreso de descarga de caché para un viaje
struct TripCacheProgress: Identifiable {
    let id: String
    let tripId: String
    var totalRoutes: Int
    var cachedRoutes: Int
    var currentDownloadingRoute: String?
    var downloadProgress: Double // 0.0 - 1.0
    var status: CacheDownloadStatus
    var errorMessage: String?

    var isComplete: Bool {
        status == .completed
    }

    var progressPercentage: Int {
        Int(downloadProgress * 100)
    }

    var statusDescription: String {
        switch status {
        case .notStarted:
            return "Sin descargar"
        case .downloading:
            return "Descargando... \(progressPercentage)%"
        case .completed:
            return "Disponible offline"
        case .failed:
            return "Error: \(errorMessage ?? "desconocido")"
        case .partiallyCompleted:
            return "\(cachedRoutes)/\(totalRoutes) rutas descargadas"
        }
    }
}
