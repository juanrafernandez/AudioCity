//
//  LocationService.swift
//  AudioCityPOC
//
//  Servicio de geolocalización con soporte para background
//  Incluye geofences nativos para despertar la app cuando está suspendida
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, LocationServiceProtocol {

    // MARK: - Published Properties
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var locationError: String?
    @Published var enteredRegionId: String?  // ID de la región en la que entramos

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var monitoredRegions: [CLCircularRegion] = []

    // MARK: - Constants
    private let geofencePrefix = AppConstants.Geofencing.stopPrefix
    private let wakeUpRadius: CLLocationDistance = AppConstants.Geofencing.wakeUpRadiusMeters
    
    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    deinit {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        cancellables.removeAll()
        Log("LocationService deinit", level: .debug, category: .location)
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = AppConstants.Location.desiredAccuracy
        locationManager.distanceFilter = AppConstants.Location.distanceFilterMeters
        
        // CRÍTICO: Configuración para background
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        // Verificar estado inicial
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Solicitar permisos de ubicación
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Iniciar seguimiento de ubicación
    func startTracking() {
        guard authorizationStatus == .authorizedAlways || 
              authorizationStatus == .authorizedWhenInUse else {
            locationError = "Se necesitan permisos de ubicación"
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isTracking = true
        locationError = nil

        Log("Tracking iniciado", level: .info, category: .location)
    }

    /// Detener seguimiento de ubicación
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        Log("Tracking detenido", level: .info, category: .location)
    }

    // MARK: - Single Location Request

    private var singleLocationCompletion: ((CLLocation?) -> Void)?

    /// Solicitar una única ubicación (útil antes de iniciar la ruta)
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void) {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else {
            Log("Sin permisos para ubicación única", level: .warning, category: .location)
            completion(nil)
            return
        }

        singleLocationCompletion = completion
        locationManager.requestLocation()
        Log("Solicitando ubicación única...", level: .debug, category: .location)
    }

    /// Obtener distancia a una coordenada
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude,
                                       longitude: coordinate.longitude)
        return userLocation.distance(from: targetLocation)
    }

    // MARK: - Native Geofence Methods (Wake-up)

    /// Registrar geofences nativos para las paradas (máximo 20)
    /// Estos sirven para despertar la app cuando está suspendida
    func registerNativeGeofences(stops: [(id: String, latitude: Double, longitude: Double)]) {
        // Limpiar geofences existentes primero
        clearNativeGeofences()

        // iOS limita a 20 regiones monitoreadas
        let stopsToMonitor = Array(stops.prefix(20))

        for stop in stopsToMonitor {
            let coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
            let region = CLCircularRegion(
                center: coordinate,
                radius: wakeUpRadius,
                identifier: "\(geofencePrefix)\(stop.id)"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false  // Solo nos interesa la entrada

            locationManager.startMonitoring(for: region)
            monitoredRegions.append(region)

            Log("Geofence nativo registrado - \(stop.id)", level: .debug, category: .location)
        }

        Log("\(stopsToMonitor.count) geofences nativos registrados", level: .info, category: .location)

        if stops.count > AppConstants.Geofencing.maxNativeGeofences {
            Log("Solo se pueden monitorear \(AppConstants.Geofencing.maxNativeGeofences) geofences. \(stops.count - AppConstants.Geofencing.maxNativeGeofences) paradas sin geofence nativo.", level: .warning, category: .location)
        }
    }

    /// Limpiar todos los geofences nativos
    func clearNativeGeofences() {
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        enteredRegionId = nil
        Log("Geofences nativos limpiados", level: .info, category: .location)
    }

    /// Obtener el stopId desde el identifier de la región
    func extractStopId(from regionIdentifier: String) -> String? {
        guard regionIdentifier.hasPrefix(geofencePrefix) else { return nil }
        return String(regionIdentifier.dropFirst(geofencePrefix.count))
    }

    /// Verificar si el dispositivo soporta geofencing
    func isGeofencingAvailable() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Actualizar ubicación del usuario
        DispatchQueue.main.async {
            self.userLocation = location

            // Si hay un callback pendiente de ubicación única, llamarlo
            if let completion = self.singleLocationCompletion {
                Log("Ubicación única obtenida", level: .debug, category: .location)
                completion(location)
                self.singleLocationCompletion = nil
            }
        }

        Log("Nueva ubicación - \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))", level: .debug, category: .location)
    }

    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription

            // Si hay un callback pendiente, llamarlo con nil
            if let completion = self.singleLocationCompletion {
                Log("Error obteniendo ubicación única", level: .warning, category: .location)
                completion(nil)
                self.singleLocationCompletion = nil
            }
        }
        Log("Error - \(error.localizedDescription)", level: .error, category: .location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedAlways:
                Log("Permiso 'Always' concedido", level: .success, category: .location)
            case .authorizedWhenInUse:
                Log("Permiso 'When In Use' concedido (necesitamos Always)", level: .warning, category: .location)
            case .denied, .restricted:
                self.locationError = "Permisos de ubicación denegados"
                Log("Permisos denegados", level: .error, category: .location)
            case .notDetermined:
                Log("Permisos no determinados", level: .info, category: .location)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Region Monitoring Delegate Methods

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        Log("Entrada en región - \(region.identifier)", level: .info, category: .location)

        // Extraer el stopId y notificar
        if let stopId = extractStopId(from: circularRegion.identifier) {
            DispatchQueue.main.async {
                self.enteredRegionId = stopId
            }
            Log("Wake-up para parada - \(stopId)", level: .info, category: .location)

            // Si no estamos tracking activamente, iniciar
            if !isTracking {
                startTracking()
                Log("Tracking iniciado por geofence nativo", level: .info, category: .location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log("Salida de región - \(region.identifier)", level: .debug, category: .location)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let region = region {
            Log("Error monitoreando región \(region.identifier) - \(error.localizedDescription)", level: .error, category: .location)
        } else {
            Log("Error monitoreando región - \(error.localizedDescription)", level: .error, category: .location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Log("Monitoreo iniciado para - \(region.identifier)", level: .debug, category: .location)

        // Verificar estado inicial de la región
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            Log("Ya estamos dentro de - \(region.identifier)", level: .debug, category: .location)
            // Si ya estamos dentro, disparar el evento
            locationManager(manager, didEnterRegion: region)
        case .outside:
            // Solo log en debug, no spam
            break
        case .unknown:
            Log("Estado desconocido para - \(region.identifier)", level: .debug, category: .location)
        }
    }
}