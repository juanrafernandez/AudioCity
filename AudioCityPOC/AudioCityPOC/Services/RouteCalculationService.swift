//
//  RouteCalculationService.swift
//  AudioCityPOC
//
//  Servicio para calcular rutas de caminata usando MapKit
//  Extraído de RouteViewModel para mejor separación de responsabilidades
//

import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Route Calculation Result

/// Resultado del cálculo de una ruta completa
struct RouteCalculationResult {
    let polylines: [MKPolyline]
    let distances: [CLLocationDistance]

    /// Distancia total de la ruta (sin el segmento usuario→primera parada)
    var totalRouteDistance: CLLocationDistance {
        guard distances.count > 1 else { return distances.first ?? 0 }
        return distances.dropFirst().reduce(0, +)
    }

    /// Distancia total incluyendo desde la posición del usuario
    var totalDistanceFromUser: CLLocationDistance {
        return distances.reduce(0, +)
    }

    /// Distancia al próximo punto
    var distanceToNext: CLLocationDistance {
        return distances.first ?? 0
    }
}

// MARK: - Route Calculation Service

/// Servicio para calcular rutas de caminata entre puntos
/// Usa MapKit Directions API para obtener rutas reales
final class RouteCalculationService: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var isCalculating = false
    @Published private(set) var lastResult: RouteCalculationResult?
    @Published private(set) var error: Error?

    // MARK: - Private Properties
    private var currentCalculationId: UUID = UUID()

    // MARK: - Public Methods

    /// Calcula la ruta completa desde la ubicación del usuario a través de todas las paradas
    /// - Parameters:
    ///   - userLocation: Ubicación actual del usuario (opcional)
    ///   - stops: Coordenadas de las paradas ordenadas
    ///   - completion: Callback con el resultado
    func calculateRoute(
        from userLocation: CLLocationCoordinate2D?,
        through stops: [CLLocationCoordinate2D],
        completion: @escaping (Result<RouteCalculationResult, Error>) -> Void
    ) {
        guard !stops.isEmpty else {
            completion(.success(RouteCalculationResult(polylines: [], distances: [])))
            return
        }

        // Construir lista de puntos
        var allPoints: [CLLocationCoordinate2D] = []
        if let userLoc = userLocation {
            allPoints.append(userLoc)
        }
        allPoints.append(contentsOf: stops)

        guard allPoints.count >= 2 else {
            completion(.success(RouteCalculationResult(polylines: [], distances: [])))
            return
        }

        isCalculating = true
        error = nil

        let calcId = UUID()
        currentCalculationId = calcId

        let totalSegments = allPoints.count - 1
        print("🗺️ RouteCalculationService: Iniciando cálculo de \(totalSegments) segmentos...")

        calculateSegmentsSequentially(
            points: allPoints,
            calcId: calcId,
            completion: completion
        )
    }

    /// Calcula la ruta de forma asíncrona
    @MainActor
    func calculateRoute(
        from userLocation: CLLocationCoordinate2D?,
        through stops: [CLLocationCoordinate2D]
    ) async throws -> RouteCalculationResult {
        return try await withCheckedThrowingContinuation { continuation in
            calculateRoute(from: userLocation, through: stops) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Calcula un único segmento (útil para actualizar la distancia usuario→próximo punto)
    func calculateSegment(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (Result<(MKPolyline, CLLocationDistance), Error>) -> Void
    ) {
        let request = MKDirections.Request()
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

        request.source = makeMapItem(from: originLocation)
        request.destination = makeMapItem(from: destLocation)
        request.transportType = .walking

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    completion(.success((route.polyline, route.distance)))
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    // Fallback: línea recta
                    var coords = [origin, destination]
                    let straightLine = MKPolyline(coordinates: &coords, count: 2)
                    let fallbackDistance = originLocation.distance(from: destLocation)
                    completion(.success((straightLine, fallbackDistance)))
                }
            }
        }
    }

    /// Cancela el cálculo actual
    func cancelCalculation() {
        currentCalculationId = UUID()
        isCalculating = false
        print("🗺️ RouteCalculationService: Cálculo cancelado")
    }

    // MARK: - Private Methods

    private func calculateSegmentsSequentially(
        points: [CLLocationCoordinate2D],
        calcId: UUID,
        completion: @escaping (Result<RouteCalculationResult, Error>) -> Void
    ) {
        var polylines: [MKPolyline] = []
        var distances: [CLLocationDistance] = []
        let totalSegments = points.count - 1

        func calculateSegment(index: Int) {
            // Verificar si el cálculo fue cancelado
            guard calcId == self.currentCalculationId else {
                print("🗺️ RouteCalculationService: Cálculo \(calcId) cancelado")
                return
            }

            // Si terminamos todos los segmentos
            guard index < totalSegments else {
                DispatchQueue.main.async {
                    self.isCalculating = false
                    let result = RouteCalculationResult(polylines: polylines, distances: distances)
                    self.lastResult = result
                    let totalKm = result.totalDistanceFromUser / 1000
                    print("🗺️ RouteCalculationService: ✅ Ruta completa - \(polylines.count) segmentos, \(String(format: "%.2f", totalKm)) km")
                    completion(.success(result))
                }
                return
            }

            let origin = points[index]
            let destination = points[index + 1]

            print("🗺️ RouteCalculationService: Calculando segmento \(index + 1)/\(totalSegments)")

            let request = MKDirections.Request()
            let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            let destLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

            request.source = MKMapItem(location: originLocation, address: nil)
            request.destination = MKMapItem(location: destLocation, address: nil)
            request.transportType = .walking

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                DispatchQueue.main.async {
                    guard calcId == self.currentCalculationId else { return }

                    if let route = response?.routes.first {
                        polylines.append(route.polyline)
                        distances.append(route.distance)
                        print("   ✅ Segmento \(index + 1) OK - \(Int(route.distance))m")
                    } else {
                        // Fallback: línea recta con distancia euclidiana
                        var coords = [origin, destination]
                        let straightLine = MKPolyline(coordinates: &coords, count: 2)
                        polylines.append(straightLine)
                        let fallbackDistance = originLocation.distance(from: destLocation)
                        distances.append(fallbackDistance)
                        print("   ⚠️ Segmento \(index + 1) fallback - ~\(Int(fallbackDistance))m")
                    }

                    // Siguiente segmento con pequeño delay para no saturar la API
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        calculateSegment(index: index + 1)
                    }
                }
            }
        }

        calculateSegment(index: 0)
    }
}

// MARK: - Protocol Conformance

extension RouteCalculationService: RouteCalculationServiceProtocol {
    func calculateWalkingRoute(
        from userLocation: CLLocationCoordinate2D?,
        through stops: [CLLocationCoordinate2D],
        completion: @escaping (Result<([MKPolyline], [CLLocationDistance]), Error>) -> Void
    ) {
        calculateRoute(from: userLocation, through: stops) { result in
            switch result {
            case .success(let calcResult):
                completion(.success((calcResult.polylines, calcResult.distances)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func calculateSegmentDistance(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (Result<(MKPolyline, CLLocationDistance), Error>) -> Void
    ) {
        calculateSegment(from: origin, to: destination, completion: completion)
    }
}

// MARK: - Helper Functions

/// Crea un MKMapItem desde una CLLocation
private func makeMapItem(from location: CLLocation) -> MKMapItem {
    let placemark = MKPlacemark(coordinate: location.coordinate)
    return MKMapItem(placemark: placemark)
}
