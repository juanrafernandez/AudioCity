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
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Actualizar cada 10 metros
        
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
    
    /// Obtener distancia a una coordenada
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, 
                                       longitude: coordinate.longitude)
        return userLocation.distance(from: targetLocation)
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
        }
        
        print("📍 LocationService: Nueva ubicación - \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, 
                        didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
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
}