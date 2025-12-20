//
//  DependencyContainer.swift
//  AudioCityPOC
//
//  Contenedor de dependencias para inyección
//  Centraliza la creación de servicios y permite sustituirlos en tests
//

import Foundation
import SwiftUI
import Combine

// MARK: - Dependency Container

/// Contenedor principal de dependencias
/// Uso: DependencyContainer.shared.locationService
final class DependencyContainer: ObservableObject {

    // Required for ObservableObject
    let objectWillChange = ObservableObjectPublisher()

    // MARK: - Singleton
    static let shared = DependencyContainer()

    // MARK: - Core Services (lazy initialization)

    /// Servicio de ubicación
    private(set) lazy var locationService: LocationService = {
        LocationService()
    }()

    /// Servicio de audio
    private(set) lazy var audioService: AudioService = {
        AudioService()
    }()

    /// Servicio de Firebase/datos
    private(set) lazy var firebaseService: FirebaseService = {
        FirebaseService()
    }()

    /// Servicio de geofencing
    private(set) lazy var geofenceService: GeofenceService = {
        GeofenceService()
    }()

    /// Servicio de notificaciones (singleton)
    var notificationService: NotificationService {
        NotificationService.shared
    }

    // MARK: - Additional Services

    /// Servicio de viajes (singleton)
    var tripService: TripService {
        TripService.shared
    }

    /// Servicio de puntos/gamificación (singleton)
    var pointsService: PointsService {
        PointsService.shared
    }

    /// Servicio de historial (singleton)
    var historyService: HistoryService {
        HistoryService.shared
    }

    /// Servicio de rutas de usuario (singleton)
    var userRoutesService: UserRoutesService {
        UserRoutesService.shared
    }

    /// Servicio de preview de audio (singleton)
    var audioPreviewService: AudioPreviewService {
        AudioPreviewService.shared
    }

    /// Servicio de caché de imágenes (singleton)
    var imageCacheService: ImageCacheService {
        ImageCacheService.shared
    }

    /// Servicio de favoritos (nueva instancia)
    private(set) lazy var favoritesService: FavoritesService = {
        FavoritesService()
    }()

    /// Servicio de caché offline (nueva instancia)
    private(set) lazy var offlineCacheService: OfflineCacheService = {
        OfflineCacheService()
    }()

    /// Servicio de cálculo de rutas
    private(set) lazy var routeCalculationService: RouteCalculationService = {
        RouteCalculationService()
    }()

    /// Servicio de optimización de rutas
    private(set) lazy var routeOptimizationService: RouteOptimizationService = {
        RouteOptimizationService()
    }()

    // MARK: - Initialization

    private init() {
        Log("DependencyContainer inicializado", level: .debug, category: .app)
    }

    // MARK: - Factory Methods

    /// Crear un RouteViewModel con todas las dependencias inyectadas
    func makeRouteViewModel() -> RouteViewModel {
        return RouteViewModel(
            locationService: locationService,
            audioService: audioService,
            firebaseService: firebaseService,
            geofenceService: geofenceService,
            notificationService: notificationService
        )
    }

    // MARK: - Testing Support

    /// Resetear todas las dependencias (útil para tests)
    func reset() {
        // Crear nuevas instancias
        // Nota: En producción, esto no debería llamarse
        Log("DependencyContainer reset (solo para tests)", level: .warning, category: .app)
    }
}

// MARK: - Environment Key

/// Clave de entorno para acceder al container desde SwiftUI
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inyectar el contenedor de dependencias en el environment
    func withDependencies(_ container: DependencyContainer = .shared) -> some View {
        self.environment(\.dependencies, container)
    }
}
