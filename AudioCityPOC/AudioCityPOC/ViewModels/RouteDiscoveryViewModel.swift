//
//  RouteDiscoveryViewModel.swift
//  AudioCityPOC
//
//  ViewModel para descubrimiento y selección de rutas
//  Encapsula la lógica de carga de rutas desde Firebase
//

import Foundation
import Combine

/// ViewModel para descubrimiento de rutas
/// Responsabilidad única: cargar y seleccionar rutas del catálogo
final class RouteDiscoveryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var availableRoutes: [Route] = []
    @Published private(set) var selectedRoute: Route?
    @Published private(set) var routeStops: [Stop] = []
    @Published private(set) var isLoadingRoutes = false
    @Published private(set) var isLoadingStops = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var isLoading: Bool {
        isLoadingRoutes || isLoadingStops
    }

    // MARK: - Dependencies

    private let firebaseService: FirebaseServiceProtocol

    // MARK: - Initialization

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    // MARK: - Public Methods

    /// Cargar todas las rutas disponibles desde Firebase
    func loadAvailableRoutes() {
        isLoadingRoutes = true
        errorMessage = nil

        Task {
            do {
                let routes = try await firebaseService.fetchAllRoutes()

                await MainActor.run {
                    self.availableRoutes = routes
                    self.isLoadingRoutes = false
                    Log("\(routes.count) rutas disponibles", level: .success, category: .route)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando rutas: \(error.localizedDescription)"
                    self.isLoadingRoutes = false
                    Log("Error cargando rutas - \(error.localizedDescription)", level: .error, category: .route)
                }
            }
        }
    }

    /// Seleccionar y cargar una ruta específica
    func selectRoute(_ route: Route) {
        isLoadingStops = true
        errorMessage = nil
        selectedRoute = route

        Task {
            do {
                let fetchedStops = try await firebaseService.fetchStops(for: route.id)

                await MainActor.run {
                    self.routeStops = fetchedStops
                    self.isLoadingStops = false

                    Log("Ruta seleccionada - \(route.name)", level: .success, category: .route)
                    Log("\(fetchedStops.count) paradas cargadas", level: .success, category: .route)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando paradas: \(error.localizedDescription)"
                    self.isLoadingStops = false
                    Log("Error - \(error.localizedDescription)", level: .error, category: .route)
                }
            }
        }
    }

    /// Seleccionar una ruta por su ID
    func selectRouteById(_ routeId: String) {
        // Buscar la ruta en las rutas disponibles
        if let route = availableRoutes.first(where: { $0.id == routeId }) {
            selectRoute(route)
        } else {
            // Si no está en availableRoutes, cargar desde Firebase
            isLoadingStops = true
            errorMessage = nil

            Task {
                do {
                    let routes = try await firebaseService.fetchAllRoutes()
                    if let route = routes.first(where: { $0.id == routeId }) {
                        await MainActor.run {
                            self.availableRoutes = routes
                            self.selectRoute(route)
                        }
                    } else {
                        await MainActor.run {
                            self.errorMessage = "Ruta no encontrada"
                            self.isLoadingStops = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Error cargando ruta: \(error.localizedDescription)"
                        self.isLoadingStops = false
                    }
                }
            }
        }
    }

    /// Limpiar selección y volver a la lista
    func clearSelection() {
        selectedRoute = nil
        routeStops = []
        errorMessage = nil
    }

    /// Obtener una ruta por ID (sin seleccionar)
    func getRoute(byId routeId: String) -> Route? {
        return availableRoutes.first(where: { $0.id == routeId })
    }
}
