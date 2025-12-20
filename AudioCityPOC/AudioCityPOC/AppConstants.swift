//
//  AppConstants.swift
//  AudioCityPOC
//
//  Constantes centralizadas de la aplicación
//  Evita magic numbers y strings dispersos en el código
//

import Foundation
import CoreLocation

enum AppConstants {

    // MARK: - App Info
    enum App {
        static let name = "AudioCity"
        static let bundleId = "com.audiocity.poc"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Geofencing
    enum Geofencing {
        /// Prefijo para identificadores de geofence
        static let stopPrefix = "audiocity_stop_"

        /// Radio para despertar la app desde background (más amplio)
        static let wakeUpRadiusMeters: CLLocationDistance = 100

        /// Radio de proximidad preciso para activar audio
        static let proximityRadiusMeters: CLLocationDistance = 5

        /// Radio por defecto si no está definido en la parada
        static let defaultTriggerRadius: CLLocationDistance = 25

        /// Máximo de geofences nativos en iOS
        static let maxNativeGeofences = 20
    }

    // MARK: - Location
    enum Location {
        /// Filtro de distancia para actualizaciones de ubicación
        static let distanceFilterMeters: CLLocationDistance = 5

        /// Precisión deseada de ubicación
        static let desiredAccuracy = kCLLocationAccuracyBest

        /// Timeout para obtener ubicación inicial (segundos)
        static let initialLocationTimeout: TimeInterval = 10
    }

    // MARK: - Audio
    enum Audio {
        /// Velocidad de habla para TTS (0.0 - 1.0)
        static let speechRate: Float = 0.50

        /// Multiplicador de tono para TTS
        static let pitchMultiplier: Float = 1.0

        /// Volumen de audio
        static let volume: Float = 1.0

        /// Idioma por defecto para TTS
        static let defaultLanguage = "es-ES"

        /// Duración de preview de audio (segundos)
        static let previewDurationSeconds: TimeInterval = 15
    }

    // MARK: - Cache
    enum Cache {
        /// Número máximo de imágenes en memoria
        static let maxMemoryImageCount = 100

        /// Tamaño máximo de caché en memoria (MB)
        static let maxMemorySizeMB = 50

        /// Días para expiración de caché en disco
        static let diskExpirationDays = 7

        /// Nombre del directorio de caché
        static let directoryName = "ImageCache"
    }

    // MARK: - UI
    enum UI {
        /// Duración de animaciones estándar
        static let standardAnimationDuration: TimeInterval = 0.3

        /// Duración de splash screen
        static let splashScreenDuration: TimeInterval = 2.5

        /// Número máximo de viajes a mostrar en la sección principal
        static let maxTripsInSection = 2

        /// Número de items en scroll horizontal
        static let horizontalScrollItemCount = 10
    }

    // MARK: - Map
    enum Map {
        /// Zoom por defecto para el mapa
        static let defaultSpanDelta: CLLocationDegrees = 0.01

        /// Zoom amplio para vista de ciudad
        static let citySpanDelta: CLLocationDegrees = 0.05

        /// Zoom para ruta activa
        static let activeRouteSpanDelta: CLLocationDegrees = 0.005

        /// Padding del mapa para mostrar anotaciones
        static let annotationPadding: Double = 50
    }

    // MARK: - Points & Gamification
    enum Points {
        /// Puntos por crear ruta pequeña (3-4 paradas)
        static let createSmallRoute = 50

        /// Puntos por crear ruta mediana (5-9 paradas)
        static let createMediumRoute = 100

        /// Puntos por crear ruta grande (10+ paradas)
        static let createLargeRoute = 200

        /// Puntos por completar ruta al 100%
        static let completeRoute = 30

        /// Bonus por primera ruta del día
        static let firstRouteOfDay = 10

        /// Bonus por racha de 3 días
        static let streak3Days = 50

        /// Bonus por racha de 7 días
        static let streak7Days = 100

        /// Puntos por publicar ruta
        static let publishRoute = 20

        /// Puntos cuando otros usan tu ruta
        static let routeUsedByOthers = 5
    }

    // MARK: - User Levels
    enum Levels {
        static let explorerThreshold = 0
        static let travelerThreshold = 100
        static let localGuideThreshold = 300
        static let expertThreshold = 600
        static let masterThreshold = 1000
    }

    // MARK: - Storage Keys
    enum StorageKeys {
        static let favorites = "favorites_route_ids"
        static let cachedRoutes = "cached_routes"
        static let userTrips = "user_trips"
        static let userRoutes = "user_routes"
        static let routeHistory = "route_history"
        static let userPoints = "user_points"
        static let pointsStats = "points_stats"
        static let pointsTransactions = "points_transactions"
        static let activeRouteState = "active_route_state"
    }

    // MARK: - Firebase Collections
    enum Firebase {
        static let routesCollection = "routes"
        static let stopsCollection = "stops"
        static let usersCollection = "users"
    }

    // MARK: - Live Activity
    enum LiveActivity {
        /// Distancia para color verde (cerca)
        static let nearDistanceMeters: Double = 50

        /// Distancia para color naranja (medio)
        static let mediumDistanceMeters: Double = 200

        /// Intervalo de actualización de Live Activity (segundos)
        static let updateIntervalSeconds: TimeInterval = 5
    }

    // MARK: - Network
    enum Network {
        /// Timeout para requests (segundos)
        static let requestTimeout: TimeInterval = 30

        /// Número máximo de reintentos
        static let maxRetries = 3
    }
}
