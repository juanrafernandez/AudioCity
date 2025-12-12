//
//  AppEvents.swift
//  AudioCityPOC
//
//  Sistema de eventos para desacoplar servicios
//  Usa Combine PassthroughSubject para publicar eventos
//

import Foundation
import Combine

// MARK: - Event Types

/// Eventos relacionados con rutas
enum RouteEvent {
    /// Ruta completada (100% paradas visitadas)
    case routeCompleted(routeId: String, routeName: String)
    /// Ruta iniciada
    case routeStarted(routeId: String, routeName: String)
    /// Ruta abandonada
    case routeAbandoned(routeId: String, routeName: String)
    /// Parada visitada
    case stopVisited(routeId: String, stopId: String, stopName: String)
}

/// Eventos relacionados con rutas de usuario (UGC)
enum UserRouteEvent {
    /// Ruta creada por usuario
    case routeCreated(routeId: String, routeName: String, stopsCount: Int)
    /// Ruta publicada
    case routePublished(routeId: String, routeName: String)
    /// Ruta usada por otro usuario
    case routeUsedByOther(routeId: String, routeName: String)
}

/// Eventos relacionados con puntos y gamificación
enum PointsEvent {
    /// Puntos otorgados
    case pointsAwarded(points: Int, reason: String)
    /// Nivel subido
    case levelUp(newLevel: Int, levelName: String)
    /// Racha conseguida
    case streakAchieved(days: Int)
}

// MARK: - Event Bus

/// Bus de eventos centralizado para comunicación entre servicios
/// Uso: EventBus.shared.routeEvents.send(.routeCompleted(...))
final class EventBus {

    // MARK: - Singleton
    static let shared = EventBus()

    // MARK: - Event Publishers

    /// Eventos de rutas
    let routeEvents = PassthroughSubject<RouteEvent, Never>()

    /// Eventos de rutas de usuario (UGC)
    let userRouteEvents = PassthroughSubject<UserRouteEvent, Never>()

    /// Eventos de puntos
    let pointsEvents = PassthroughSubject<PointsEvent, Never>()

    // MARK: - Initialization
    private init() {
        print("📡 EventBus: Inicializado")
    }

    // MARK: - Convenience Methods

    /// Publicar que una ruta fue completada
    func publishRouteCompleted(routeId: String, routeName: String) {
        routeEvents.send(.routeCompleted(routeId: routeId, routeName: routeName))
        print("📡 EventBus: Evento routeCompleted publicado - \(routeName)")
    }

    /// Publicar que se otorgaron puntos
    func publishPointsAwarded(points: Int, reason: String) {
        pointsEvents.send(.pointsAwarded(points: points, reason: reason))
        print("📡 EventBus: Evento pointsAwarded publicado - \(points) pts por \(reason)")
    }

    /// Publicar subida de nivel
    func publishLevelUp(newLevel: Int, levelName: String) {
        pointsEvents.send(.levelUp(newLevel: newLevel, levelName: levelName))
        print("📡 EventBus: Evento levelUp publicado - Nivel \(newLevel) (\(levelName))")
    }
}

// MARK: - Event Subscriber Helper

/// Helper para suscribirse a eventos de forma más sencilla
extension Publisher where Failure == Never {
    func subscribeToEvents<S: Scheduler>(
        on scheduler: S,
        handler: @escaping (Output) -> Void
    ) -> AnyCancellable {
        self
            .receive(on: scheduler)
            .sink(receiveValue: handler)
    }
}
