//
//  DependencyContainer.swift
//  AudioCityPOC
//
//  Contenedor de dependencias para inyección
//  Centraliza la creación de servicios y permite sustituirlos en tests
//
//  NOTA: Este es el ÚNICO punto de acceso a servicios.
//  Las vistas deben obtener servicios via @EnvironmentObject.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Dependency Container

/// Contenedor principal de dependencias
/// Único punto de creación de instancias - NO usar .shared en servicios
final class DependencyContainer: ObservableObject {

    // Required for ObservableObject
    let objectWillChange = ObservableObjectPublisher()

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

    /// Servicio de notificaciones - instancia única del container
    private(set) lazy var notificationService: NotificationService = {
        NotificationService()
    }()

    // MARK: - Business Services (lazy initialization)

    /// Servicio de viajes - instancia única del container
    private(set) lazy var tripService: TripService = {
        TripService()
    }()

    /// Servicio de puntos/gamificación - instancia única del container
    private(set) lazy var pointsService: PointsService = {
        PointsService()
    }()

    /// Servicio de historial - instancia única del container
    private(set) lazy var historyService: HistoryService = {
        HistoryService()
    }()

    /// Servicio de rutas de usuario - instancia única del container
    private(set) lazy var userRoutesService: UserRoutesService = {
        UserRoutesService()
    }()

    /// Servicio de preview de audio - instancia única del container
    private(set) lazy var audioPreviewService: AudioPreviewService = {
        AudioPreviewService()
    }()

    /// Servicio de caché de imágenes - instancia única del container
    private(set) lazy var imageCacheService: ImageCacheService = {
        ImageCacheService()
    }()

    /// Servicio de favoritos
    private(set) lazy var favoritesService: FavoritesService = {
        FavoritesService()
    }()

    /// Servicio de caché offline
    private(set) lazy var offlineCacheService: OfflineCacheService = {
        OfflineCacheService()
    }()

    /// Servicio de autenticación
    private(set) lazy var authService: AuthService = {
        AuthService()
    }()

    /// Servicio de almacenamiento (Firebase Storage)
    private(set) lazy var storageService: StorageService = {
        StorageService()
    }()

    /// Servicio de cálculo de rutas
    private(set) lazy var routeCalculationService: RouteCalculationService = {
        RouteCalculationService()
    }()

    /// Servicio de optimización de rutas
    private(set) lazy var routeOptimizationService: RouteOptimizationService = {
        RouteOptimizationService()
    }()

    // MARK: - State Objects

    /// Estado compartido de paradas para rutas activas
    private(set) lazy var routeStopsState: RouteStopsState = {
        RouteStopsState()
    }()

    // MARK: - ViewModels (lazy initialization)

    /// ViewModel para descubrimiento de rutas
    private(set) lazy var routeDiscoveryViewModel: RouteDiscoveryViewModel = {
        RouteDiscoveryViewModel(firebaseService: firebaseService)
    }()

    /// ViewModel para exploración del mapa
    private(set) lazy var exploreViewModel: ExploreViewModel = {
        ExploreViewModel(
            firebaseService: firebaseService,
            locationService: locationService,
            audioService: audioService
        )
    }()

    /// ViewModel para ruta activa
    private(set) lazy var activeRouteViewModel: ActiveRouteViewModel = {
        ActiveRouteViewModel(
            locationService: locationService,
            geofenceService: geofenceService,
            historyService: historyService,
            audioService: audioService,
            notificationService: notificationService,
            firebaseService: firebaseService,
            stopsState: routeStopsState
        )
    }()

    // MARK: - Initialization

    init() {
        Log("DependencyContainer inicializado", level: .debug, category: .app)
    }

    // MARK: - Factory Methods

    /// Crear un ActiveRouteViewModel con todas las dependencias
    func makeActiveRouteViewModel() -> ActiveRouteViewModel {
        return ActiveRouteViewModel(
            locationService: locationService,
            geofenceService: geofenceService,
            historyService: historyService,
            audioService: audioService,
            notificationService: notificationService,
            firebaseService: firebaseService,
            stopsState: routeStopsState
        )
    }

    // MARK: - Testing Support

    /// Crear un container para testing con mocks opcionales
    static func forTesting(
        locationService: LocationService? = nil,
        audioService: AudioService? = nil,
        firebaseService: FirebaseService? = nil
    ) -> DependencyContainer {
        let container = DependencyContainer()
        // En el futuro, permitir inyección de mocks aquí
        return container
    }

    /// Resetear todas las dependencias (útil para tests)
    func reset() {
        Log("DependencyContainer reset (solo para tests)", level: .warning, category: .app)
    }
}

// MARK: - Environment Key

/// Clave de entorno para acceder al container desde SwiftUI
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer? = nil
}

extension EnvironmentValues {
    var dependencies: DependencyContainer? {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inyectar el contenedor de dependencias en el environment
    func withDependencies(_ container: DependencyContainer) -> some View {
        self.environment(\.dependencies, container)
    }
}
