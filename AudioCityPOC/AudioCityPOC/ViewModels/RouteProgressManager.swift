//
//  RouteProgressManager.swift
//  AudioCityPOC
//
//  Gestor de progreso de ruta y audio
//  Encapsula la lógica de seguimiento de progreso y reproducción de audio
//

import Foundation
import Combine

/// Gestor de progreso de ruta y audio
/// Responsabilidad única: gestionar el progreso y reproducción de audio
final class RouteProgressManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var currentStop: Stop?
    @Published private(set) var visitedStopsCount = 0
    @Published private(set) var isAudioPlaying = false
    @Published private(set) var isPaused = false

    // MARK: - Computed Properties

    var progress: Double {
        stopsState.progress
    }

    var nextStop: Stop? {
        stopsState.nextStop
    }

    // MARK: - Dependencies

    private let stopsState: RouteStopsState
    private let audioService: AudioServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        stopsState: RouteStopsState,
        audioService: AudioServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.stopsState = stopsState
        self.audioService = audioService
        self.notificationService = notificationService
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observar estado de audio
        audioService.isPlaying
            .sink { [weak self] isPlaying in
                self?.isAudioPlaying = isPlaying
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Manejar cuando se activa una parada por geofencing
    func handleStopTriggered(_ stop: Stop, stops: [Stop]) {
        // Actualizar parada actual (si no hay ninguna reproduciéndose)
        if currentStop == nil || !isAudioPlaying {
            currentStop = stop
        }

        // Actualizar contador de visitadas
        visitedStopsCount = stopsState.visitedCount

        // Mostrar notificación local
        notificationService.showStopArrivalNotification(stop: stop)

        // Encolar audio para reproducción
        audioService.enqueueStop(
            stopId: stop.id,
            stopName: stop.name,
            text: stop.scriptEs,
            order: stop.order
        )

        Log("Parada activada y encolada - \(stop.name)", level: .info, category: .route)
        Log("Progreso: \(visitedStopsCount)/\(stops.count) paradas completadas", level: .info, category: .route)
        Log("Cola de audio: \(audioService.getQueueCount()) pendientes", level: .debug, category: .audio)
    }

    /// Actualizar currentStop cuando cambia el item de audio
    func updateCurrentStop(from queueItem: AudioQueueItem?, stops: [Stop]) {
        guard let queueItem = queueItem,
              let stop = stops.first(where: { $0.id == queueItem.stopId }) else { return }

        currentStop = stop
        Log("Reproduciendo ahora: \(stop.name)", level: .info, category: .audio)
    }

    /// Reproducir una parada manualmente
    func playStop(_ stop: Stop) {
        currentStop = stop
        audioService.speak(text: stop.scriptEs, language: "es-ES")
    }

    /// Pausar audio
    func pauseAudio() {
        audioService.pause()
        isPaused = true
    }

    /// Reanudar audio
    func resumeAudio() {
        audioService.resume()
        isPaused = false
    }

    /// Detener audio
    func stopAudio() {
        audioService.stop()
    }

    /// Manejar acción de notificación
    func handleNotificationAction(_ action: NotificationService.NotificationAction, stopId: String) {
        switch action {
        case .listen:
            Log("Usuario confirmó escuchar - \(stopId)", level: .info, category: .route)

        case .skip:
            Log("Usuario saltó parada - \(stopId)", level: .info, category: .route)
            audioService.stop()
        }
    }

    /// Verificar si la ruta está completada
    func isRouteCompleted(totalStops: Int) -> Bool {
        return visitedStopsCount == totalStops && totalStops > 0
    }

    // MARK: - Cleanup

    /// Limpiar estado
    func reset() {
        currentStop = nil
        visitedStopsCount = 0
        audioService.stopAndClear()
        notificationService.cancelAllPendingNotifications()
    }
}

// MARK: - AudioServiceProtocol Extension for Publisher

private extension AudioServiceProtocol {
    var isPlaying: AnyPublisher<Bool, Never> {
        // Note: This needs to be implemented based on the actual AudioService implementation
        // For now, return a simple publisher
        Just(self.isPlaying).eraseToAnyPublisher()
    }
}
