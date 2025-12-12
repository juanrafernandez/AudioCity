//
//  ServiceProtocols.swift
//  AudioCityPOC
//
//  Protocolos para servicios - permite inyección de dependencias y testing
//

import Foundation
import CoreLocation
import Combine
import MapKit

// MARK: - Location Service Protocol

/// Protocolo para servicios de ubicación
/// Permite mockear el servicio de ubicación en tests
protocol LocationServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var userLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var isTracking: Bool { get }
    var locationError: String? { get }
    var enteredRegionId: String? { get }

    // MARK: - Methods
    func requestLocationPermission()
    func startTracking()
    func stopTracking()
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void)
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance?

    // MARK: - Geofence Methods
    func registerNativeGeofences(stops: [(id: String, latitude: Double, longitude: Double)])
    func clearNativeGeofences()
    func extractStopId(from regionIdentifier: String) -> String?
    func isGeofencingAvailable() -> Bool
}

// MARK: - Audio Service Protocol

/// Protocolo para servicios de audio
/// Permite mockear el servicio de audio en tests
protocol AudioServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
    var currentText: String? { get }
    var currentQueueItem: AudioQueueItem? { get }
    var queuedItems: [AudioQueueItem] { get }

    // MARK: - Methods
    func speak(text: String, language: String)
    func enqueueStop(stopId: String, stopName: String, text: String, order: Int)
    func getQueueCount() -> Int
    func clearQueue()
    func skipToNext()
    func pause()
    func resume()
    func stop()
    func stopAndClear()
    func skipForward()
    func skipBackward()
}

// Extensión para valores por defecto
extension AudioServiceProtocol {
    func speak(text: String) {
        speak(text: text, language: "es-ES")
    }
}

// MARK: - Firebase Service Protocol

/// Protocolo para servicios de datos (Firebase o cualquier backend)
/// Permite cambiar de backend sin modificar los ViewModels
protocol FirebaseServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    // MARK: - Methods
    func fetchRoute(id: String) async throws -> Route
    func fetchStops(for routeId: String) async throws -> [Stop]
    func fetchCompleteRoute(routeId: String) async throws -> (Route, [Stop])
    func fetchAllRoutes() async throws -> [Route]
}

// MARK: - Geofence Service Protocol

/// Protocolo para servicios de geofencing
/// Detecta cuando el usuario entra en el radio de una parada
protocol GeofenceServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var triggeredStop: Stop? { get }
    var triggeredStops: [Stop] { get }
    var nearbyStops: [Stop] { get }

    // MARK: - Methods
    func setupGeofences(for stops: [Stop], locationService: LocationService)
    func clearGeofences()
    func getNextStop() -> Stop?
    func getProgress() -> Double
}

// MARK: - Notification Service Protocol

/// Protocolo para servicios de notificaciones
/// Gestiona notificaciones locales al llegar a paradas
protocol NotificationServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var isAuthorized: Bool { get }
    var lastActionStopId: String? { get }
    var lastAction: NotificationService.NotificationAction? { get }

    // MARK: - Methods
    func requestAuthorization()
    func checkAuthorizationStatus()
    func showStopArrivalNotification(stop: Stop)
    func cancelAllPendingNotifications()
    func cancelNotification(for stopId: String)
}

// MARK: - Route Calculation Protocol

/// Protocolo para servicios de cálculo de rutas
/// Permite abstraer el cálculo de rutas con MapKit
protocol RouteCalculationServiceProtocol {
    func calculateWalkingRoute(
        from userLocation: CLLocationCoordinate2D?,
        through stops: [CLLocationCoordinate2D],
        completion: @escaping (Result<([MKPolyline], [CLLocationDistance]), Error>) -> Void
    )

    func calculateSegmentDistance(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (Result<(MKPolyline, CLLocationDistance), Error>) -> Void
    )
}

// MARK: - Type Erasure Wrappers

/// Type-erased wrapper for LocationServiceProtocol
/// Necesario porque Swift no permite usar protocolos con associated types directamente
final class AnyLocationService: LocationServiceProtocol {
    private let _userLocation: () -> CLLocation?
    private let _authorizationStatus: () -> CLAuthorizationStatus
    private let _isTracking: () -> Bool
    private let _locationError: () -> String?
    private let _enteredRegionId: () -> String?
    private let _requestLocationPermission: () -> Void
    private let _startTracking: () -> Void
    private let _stopTracking: () -> Void
    private let _requestSingleLocation: (@escaping (CLLocation?) -> Void) -> Void
    private let _distance: (CLLocationCoordinate2D) -> CLLocationDistance?
    private let _registerNativeGeofences: ([(id: String, latitude: Double, longitude: Double)]) -> Void
    private let _clearNativeGeofences: () -> Void
    private let _extractStopId: (String) -> String?
    private let _isGeofencingAvailable: () -> Bool

    let objectWillChange: ObservableObjectPublisher

    init<T: LocationServiceProtocol>(_ service: T) {
        _userLocation = { service.userLocation }
        _authorizationStatus = { service.authorizationStatus }
        _isTracking = { service.isTracking }
        _locationError = { service.locationError }
        _enteredRegionId = { service.enteredRegionId }
        _requestLocationPermission = { service.requestLocationPermission() }
        _startTracking = { service.startTracking() }
        _stopTracking = { service.stopTracking() }
        _requestSingleLocation = { service.requestSingleLocation(completion: $0) }
        _distance = { service.distance(to: $0) }
        _registerNativeGeofences = { service.registerNativeGeofences(stops: $0) }
        _clearNativeGeofences = { service.clearNativeGeofences() }
        _extractStopId = { service.extractStopId(from: $0) }
        _isGeofencingAvailable = { service.isGeofencingAvailable() }
        objectWillChange = ObservableObjectPublisher()
    }

    var userLocation: CLLocation? { _userLocation() }
    var authorizationStatus: CLAuthorizationStatus { _authorizationStatus() }
    var isTracking: Bool { _isTracking() }
    var locationError: String? { _locationError() }
    var enteredRegionId: String? { _enteredRegionId() }

    func requestLocationPermission() { _requestLocationPermission() }
    func startTracking() { _startTracking() }
    func stopTracking() { _stopTracking() }
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void) { _requestSingleLocation(completion) }
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? { _distance(coordinate) }
    func registerNativeGeofences(stops: [(id: String, latitude: Double, longitude: Double)]) { _registerNativeGeofences(stops) }
    func clearNativeGeofences() { _clearNativeGeofences() }
    func extractStopId(from regionIdentifier: String) -> String? { _extractStopId(regionIdentifier) }
    func isGeofencingAvailable() -> Bool { _isGeofencingAvailable() }
}
