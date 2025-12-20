//
//  RouteActivityAttributes.swift
//  AudioCityPOC
//
//  Define los atributos estáticos y dinámicos para el Live Activity de ruta
//  Este archivo debe estar disponible tanto en el target principal como en el Widget Extension
//

import Foundation
import ActivityKit

/// Atributos para el Live Activity de una ruta activa
/// Muestra la distancia al próximo punto en la Dynamic Island
struct RouteActivityAttributes: ActivityAttributes {

    // MARK: - Content State (Datos dinámicos que cambian)

    public struct ContentState: Codable, Hashable {
        /// Distancia en metros al próximo punto
        var distanceToNextStop: Double

        /// Nombre de la próxima parada
        var nextStopName: String

        /// Número de orden de la próxima parada
        var nextStopOrder: Int

        /// Paradas visitadas
        var visitedStops: Int

        /// Total de paradas
        var totalStops: Int

        /// Si el audio está reproduciéndose
        var isPlaying: Bool

        /// Distancia formateada
        var formattedDistance: String {
            if distanceToNextStop < 1000 {
                return "\(Int(distanceToNextStop))m"
            } else {
                return String(format: "%.1fkm", distanceToNextStop / 1000)
            }
        }

        /// Progreso como texto
        var progressText: String {
            "\(visitedStops)/\(totalStops)"
        }

        /// Porcentaje de progreso (0-1)
        var progressPercentage: Double {
            guard totalStops > 0 else { return 0 }
            return Double(visitedStops) / Double(totalStops)
        }
    }

    // MARK: - Atributos estáticos (no cambian durante el Live Activity)

    /// Nombre de la ruta
    var routeName: String

    /// Ciudad de la ruta
    var routeCity: String

    /// ID de la ruta (para deep linking)
    var routeId: String
}
