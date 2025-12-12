//
//  LocationService.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//


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
    private let geofencePrefix = "audiocity_stop_"
    private let wakeUpRadius: CLLocationDistance = 100  // Radio amplio para wake-up
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Actualizar cada 5 metros para mayor precisión
        
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
        
        print("📍 LocationService: Tracking iniciado")
    }
    
    /// Detener seguimiento de ubicación
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        print("📍 LocationService: Tracking detenido")
    }

    // MARK: - Single Location Request

    private var singleLocationCompletion: ((CLLocation?) -> Void)?

    /// Solicitar una única ubicación (útil antes de iniciar la ruta)
    func requestSingleLocation(completion: @escaping (CLLocation?) -> Void) {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else {
            print("📍 LocationService: Sin permisos para ubicación única")
            completion(nil)
            return
        }

        singleLocationCompletion = completion
        locationManager.requestLocation()
        print("📍 LocationService: Solicitando ubicación única...")
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

            print("📍 LocationService: Geofence nativo registrado - \(stop.id)")
        }

        print("📍 LocationService: \(stopsToMonitor.count) geofences nativos registrados")

        if stops.count > 20 {
            print("⚠️ LocationService: Solo se pueden monitorear 20 geofences. \(stops.count - 20) paradas sin geofence nativo.")
        }
    }

    /// Limpiar todos los geofences nativos
    func clearNativeGeofences() {
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()
        enteredRegionId = nil
        print("📍 LocationService: Geofences nativos limpiados")
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
                print("📍 LocationService: Ubicación única obtenida")
                completion(location)
                self.singleLocationCompletion = nil
            }
        }

        print("📍 LocationService: Nueva ubicación - \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription

            // Si hay un callback pendiente, llamarlo con nil
            if let completion = self.singleLocationCompletion {
                print("📍 LocationService: Error obteniendo ubicación única")
                completion(nil)
                self.singleLocationCompletion = nil
            }
        }
        print("❌ LocationService: Error - \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedAlways:
                print("✅ LocationService: Permiso 'Always' concedido")
            case .authorizedWhenInUse:
                print("⚠️ LocationService: Permiso 'When In Use' concedido (necesitamos Always)")
            case .denied, .restricted:
                self.locationError = "Permisos de ubicación denegados"
                print("❌ LocationService: Permisos denegados")
            case .notDetermined:
                print("⏳ LocationService: Permisos no determinados")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Region Monitoring Delegate Methods

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        print("📍 LocationService: Entrada en región - \(region.identifier)")

        // Extraer el stopId y notificar
        if let stopId = extractStopId(from: circularRegion.identifier) {
            DispatchQueue.main.async {
                self.enteredRegionId = stopId
            }
            print("📍 LocationService: Wake-up para parada - \(stopId)")

            // Si no estamos tracking activamente, iniciar
            if !isTracking {
                startTracking()
                print("📍 LocationService: Tracking iniciado por geofence nativo")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("📍 LocationService: Salida de región - \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let region = region {
            print("❌ LocationService: Error monitoreando región \(region.identifier) - \(error.localizedDescription)")
        } else {
            print("❌ LocationService: Error monitoreando región - \(error.localizedDescription)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("📍 LocationService: Monitoreo iniciado para - \(region.identifier)")

        // Verificar estado inicial de la región
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("📍 LocationService: Ya estamos dentro de - \(region.identifier)")
            // Si ya estamos dentro, disparar el evento
            locationManager(manager, didEnterRegion: region)
        case .outside:
            // Solo log en debug, no spam
            break
        case .unknown:
            print("📍 LocationService: Estado desconocido para - \(region.identifier)")
        }
    }
}