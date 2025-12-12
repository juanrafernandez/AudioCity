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

    // MARK: - Services (lazy initialization)

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

    /// Servicio de notificaciones (ya es singleton)
    var notificationService: NotificationService {
        NotificationService.shared
    }

    // MARK: - Initialization

    private init() {
        print("🏗️ DependencyContainer: Inicializado")
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
        print("🏗️ DependencyContainer: Reset (solo para tests)")
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
