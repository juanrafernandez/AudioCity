//
//  ExploreViewModel.swift
//  AudioCityPOC
//
//  ViewModel para explorar todas las paradas disponibles
//

import Foundation
import Combine
import CoreLocation

class ExploreViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var allStops: [Stop] = []
    @Published var routes: [Route] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStop: Stop?

    // MARK: - Services
    let firebaseService = FirebaseService()
    let locationService = LocationService()
    let audioService = AudioService()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupObservers()
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

                    print("✅ ExploreViewModel: \(fetchedRoutes.count) rutas cargadas")
                    print("✅ ExploreViewModel: \(allFetchedStops.count) paradas totales cargadas")
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Error cargando paradas: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ ExploreViewModel: Error - \(error.localizedDescription)")
                }
            }
        }
    }

    /// Reproducir audio de una parada
    func playStop(_ stop: Stop) {
        selectedStop = stop
        audioService.speak(text: stop.scriptEs, language: "es-ES")
        print("🔊 Reproduciendo: \(stop.name)")
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
}
