//
//  ExploreViewModel.swift
//  AudioCityPOC
//
//  ViewModel para explorar todas las paradas disponibles
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine

class ExploreViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = ExploreViewModel()

    // MARK: - Published Properties
    @Published var allStops: [Stop] = []
    @Published var routes: [Route] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStop: Stop?

    // MARK: - Map State (persiste entre cambios de tab)
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.3974, longitude: -3.6924),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @Published var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.3974, longitude: -3.6924),
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    ))
    @Published var activeRouteCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    var hasCenteredOnUser = false
    var hasPositionedActiveRoute = false

    // MARK: - Services
    let firebaseService = FirebaseService()
    let locationService = LocationService()
    let audioService = AudioService()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupObservers()
    }

    deinit {
        cancellables.removeAll()
        audioService.stop()
        Log("ExploreViewModel deinit", level: .debug, category: .app)
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observar ubicación del usuario
        locationService.$userLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                // Aquí podrías ordenar las paradas por distancia
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Cargar todas las paradas de todas las rutas activas
    func loadAllStops() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Cargar todas las rutas activas
                let fetchedRoutes = try await firebaseService.fetchAllRoutes()

                // Cargar paradas de todas las rutas
                var allFetchedStops: [Stop] = []

                for route in fetchedRoutes {
                    let stops = try await firebaseService.fetchStops(for: route.id)
                    allFetchedStops.append(contentsOf: stops)
                }

                await MainActor.run {
                    self.routes = fetchedRoutes
                    self.allStops = allFetchedStops
                    self.isLoading = false

                    Log("\(fetchedRoutes.count) rutas cargadas", level: .success, category: .route)
                    Log("\(allFetchedStops.count) paradas totales cargadas", level: .success, category: .route)
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando paradas: \(error.localizedDescription)"
                    self.isLoading = false
                    Log("Error - \(error.localizedDescription)", level: .error, category: .route)
                }
            }
        }
    }

    /// Reproducir audio de una parada
    func playStop(_ stop: Stop) {
        selectedStop = stop
        audioService.speak(text: stop.scriptEs, language: "es-ES")
        Log("Reproduciendo: \(stop.name)", level: .info, category: .audio)
    }

    /// Detener audio
    func stopAudio() {
        audioService.stop()
        selectedStop = nil
    }

    /// Pausar audio
    func pauseAudio() {
        audioService.pause()
    }

    /// Reanudar audio
    func resumeAudio() {
        audioService.resume()
    }

    /// Obtener paradas cercanas (dentro de 500m)
    func getNearbyStops(limit: Int = 10) -> [Stop] {
        guard let userLocation = locationService.userLocation else { return [] }

        let stopsWithDistance = allStops.map { stop -> (stop: Stop, distance: CLLocationDistance) in
            let distance = userLocation.distance(from: stop.location)
            return (stop, distance)
        }

        return stopsWithDistance
            .filter { $0.distance <= 500 } // Dentro de 500 metros
            .sorted { $0.distance < $1.distance }
            .prefix(limit)
            .map { $0.stop }
    }

    /// Centrar mapa en ubicación del usuario (solicita ubicación única)
    func centerOnUserLocation() {
        // Si ya tenemos ubicación, usar esa
        if let userLocation = locationService.userLocation {
            mapRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: mapRegion.span // Mantener el zoom actual
            )
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
            return
        }

        // Si no, solicitar ubicación única
        locationService.requestSingleLocation { [weak self] location in
            guard let self = self, let location = location else { return }

            DispatchQueue.main.async {
                self.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: self.mapRegion.span
                )
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
            }
        }
    }

    /// Centrar en usuario solo la primera vez
    func centerOnUserIfNeeded() {
        guard !hasCenteredOnUser else {
            Log("Ya centrado previamente", level: .debug, category: .location)
            return
        }

        guard let userLocation = locationService.userLocation else {
            Log("Ubicación no disponible aún", level: .debug, category: .location)
            return
        }

        Log("Centrando en usuario \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)", level: .info, category: .location)

        mapRegion = MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        cameraPosition = .region(MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        ))
        hasCenteredOnUser = true
    }

    /// Solicitar ubicación actual una sola vez (sin tracking continuo)
    func requestCurrentLocation() {
        guard !hasCenteredOnUser else {
            Log("Ya centrado, no solicitar de nuevo", level: .debug, category: .location)
            return
        }

        Log("Solicitando ubicación única...", level: .debug, category: .location)
        locationService.requestSingleLocation { [weak self] location in
            guard let self = self, let location = location else {
                Log("No se pudo obtener ubicación", level: .warning, category: .location)
                return
            }

            DispatchQueue.main.async {
                Log("Ubicación obtenida \(location.coordinate.latitude), \(location.coordinate.longitude)", level: .info, category: .location)
                self.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
                self.hasCenteredOnUser = true
            }
        }
    }
}
