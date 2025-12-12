//
//  LiveActivityService.swift
//  AudioCityPOC
//
//  Servicio para manejar el ciclo de vida de Live Activities
//  Inicia, actualiza y finaliza el Live Activity de la ruta activa
//

import Foundation
import ActivityKit
import Combine

@available(iOS 16.1, *)
class LiveActivityService: ObservableObject {

    // MARK: - Singleton

    static let shared = LiveActivityService()

    // MARK: - Published Properties

    @Published private(set) var currentActivity: Activity<RouteActivityAttributes>?
    @Published private(set) var isActivityActive = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Recuperar actividades existentes al iniciar
        Task {
            await recoverExistingActivities()
        }
    }

    // MARK: - Public Methods

    /// Iniciar un Live Activity para una ruta
    /// - Parameters:
    ///   - routeId: ID de la ruta
    ///   - routeName: Nombre de la ruta
    ///   - routeCity: Ciudad de la ruta
    ///   - nextStopName: Nombre de la próxima parada
    ///   - nextStopOrder: Orden de la próxima parada
    ///   - distanceToNextStop: Distancia al próximo punto en metros
    ///   - totalStops: Total de paradas
    func startActivity(
        routeId: String,
        routeName: String,
        routeCity: String,
        nextStopName: String,
        nextStopOrder: Int,
        distanceToNextStop: Double,
        totalStops: Int
    ) async {
        // Verificar si Live Activities están habilitadas
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ LiveActivityService: Live Activities no están habilitadas")
            return
        }

        // Finalizar actividad existente si hay una
        if currentActivity != nil {
            await endActivity()
        }

        // Crear atributos
        let attributes = RouteActivityAttributes(
            routeName: routeName,
            routeCity: routeCity,
            routeId: routeId
        )

        // Crear estado inicial
        let initialState = RouteActivityAttributes.ContentState(
            distanceToNextStop: distanceToNextStop,
            nextStopName: nextStopName,
            nextStopOrder: nextStopOrder,
            visitedStops: 0,
            totalStops: totalStops,
            isPlaying: false
        )

        // Configurar contenido
        let content = ActivityContent(
            state: initialState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 8, to: Date())
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil // Sin push notifications por ahora
            )

            await MainActor.run {
                self.currentActivity = activity
                self.isActivityActive = true
            }

            print("✅ LiveActivityService: Live Activity iniciado - \(activity.id)")

            // Observar cambios de estado
            observeActivityState(activity)

        } catch {
            print("❌ LiveActivityService: Error iniciando Live Activity - \(error.localizedDescription)")
        }
    }

    /// Actualizar el Live Activity con nueva información
    /// - Parameters:
    ///   - distanceToNextStop: Nueva distancia al próximo punto
    ///   - nextStopName: Nombre de la próxima parada
    ///   - nextStopOrder: Orden de la próxima parada
    ///   - visitedStops: Paradas visitadas
    ///   - totalStops: Total de paradas
    ///   - isPlaying: Si hay audio reproduciéndose
    func updateActivity(
        distanceToNextStop: Double,
        nextStopName: String,
        nextStopOrder: Int,
        visitedStops: Int,
        totalStops: Int,
        isPlaying: Bool
    ) async {
        guard let activity = currentActivity else {
            print("⚠️ LiveActivityService: No hay actividad activa para actualizar")
            return
        }

        let updatedState = RouteActivityAttributes.ContentState(
            distanceToNextStop: distanceToNextStop,
            nextStopName: nextStopName,
            nextStopOrder: nextStopOrder,
            visitedStops: visitedStops,
            totalStops: totalStops,
            isPlaying: isPlaying
        )

        let content = ActivityContent(
            state: updatedState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        )

        await activity.update(content)
        print("📍 LiveActivityService: Actualizado - \(Int(distanceToNextStop))m a \(nextStopName)")
    }

    /// Finalizar el Live Activity
    /// - Parameter showFinalState: Si mostrar estado final antes de cerrar
    func endActivity(showFinalState: Bool = false) async {
        guard let activity = currentActivity else { return }

        // Crear estado final si se requiere
        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: nil
        )

        let dismissalPolicy: ActivityUIDismissalPolicy = showFinalState ? .default : .immediate

        await activity.end(finalContent, dismissalPolicy: dismissalPolicy)

        await MainActor.run {
            self.currentActivity = nil
            self.isActivityActive = false
        }

        print("⏹️ LiveActivityService: Live Activity finalizado")
    }

    /// Verificar si Live Activities están disponibles
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Private Methods

    /// Recuperar actividades existentes (por si la app se reinició)
    private func recoverExistingActivities() async {
        for activity in Activity<RouteActivityAttributes>.activities {
            print("🔄 LiveActivityService: Recuperando actividad existente - \(activity.id)")

            await MainActor.run {
                self.currentActivity = activity
                self.isActivityActive = activity.activityState == .active
            }

            observeActivityState(activity)
        }
    }

    /// Observar cambios de estado de la actividad
    private func observeActivityState(_ activity: Activity<RouteActivityAttributes>) {
        Task {
            for await state in activity.activityStateUpdates {
                await MainActor.run {
                    switch state {
                    case .active:
                        self.isActivityActive = true
                        print("🟢 LiveActivityService: Actividad activa")
                    case .ended:
                        self.isActivityActive = false
                        self.currentActivity = nil
                        print("🔴 LiveActivityService: Actividad finalizada")
                    case .dismissed:
                        self.isActivityActive = false
                        self.currentActivity = nil
                        print("🔴 LiveActivityService: Actividad descartada")
                    case .stale:
                        print("🟡 LiveActivityService: Actividad obsoleta")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - Wrapper para versiones anteriores a iOS 16.1

/// Wrapper que permite usar LiveActivityService de forma segura en versiones anteriores
class LiveActivityServiceWrapper {

    static let shared = LiveActivityServiceWrapper()

    private init() {}

    /// Iniciar actividad (solo si está disponible)
    func startActivity(
        routeId: String,
        routeName: String,
        routeCity: String,
        nextStopName: String,
        nextStopOrder: Int,
        distanceToNextStop: Double,
        totalStops: Int
    ) {
        guard #available(iOS 16.1, *) else {
            print("⚠️ Live Activities no disponibles en esta versión de iOS")
            return
        }

        Task {
            await LiveActivityService.shared.startActivity(
                routeId: routeId,
                routeName: routeName,
                routeCity: routeCity,
                nextStopName: nextStopName,
                nextStopOrder: nextStopOrder,
                distanceToNextStop: distanceToNextStop,
                totalStops: totalStops
            )
        }
    }

    /// Actualizar actividad (solo si está disponible)
    func updateActivity(
        distanceToNextStop: Double,
        nextStopName: String,
        nextStopOrder: Int,
        visitedStops: Int,
        totalStops: Int,
        isPlaying: Bool
    ) {
        guard #available(iOS 16.1, *) else { return }

        Task {
            await LiveActivityService.shared.updateActivity(
                distanceToNextStop: distanceToNextStop,
                nextStopName: nextStopName,
                nextStopOrder: nextStopOrder,
                visitedStops: visitedStops,
                totalStops: totalStops,
                isPlaying: isPlaying
            )
        }
    }

    /// Finalizar actividad (solo si está disponible)
    func endActivity(showFinalState: Bool = false) {
        guard #available(iOS 16.1, *) else { return }

        Task {
            await LiveActivityService.shared.endActivity(showFinalState: showFinalState)
        }
    }

    /// Verificar si Live Activities están disponibles y habilitadas
    var isAvailable: Bool {
        guard #available(iOS 16.1, *) else { return false }
        return LiveActivityService.shared.areActivitiesEnabled
    }
}
