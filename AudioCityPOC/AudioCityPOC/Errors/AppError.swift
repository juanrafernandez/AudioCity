//
//  AppError.swift
//  AudioCityPOC
//
//  Sistema unificado de errores para la aplicación
//  Proporciona tipos de error específicos por dominio
//

import Foundation

// MARK: - Base App Error Protocol

/// Protocolo base para todos los errores de la aplicación
/// Proporciona información estructurada para logging y UI
protocol AppError: LocalizedError {
    /// Código único del error para tracking
    var code: String { get }

    /// Indica si el error es recuperable (retry posible)
    var isRecoverable: Bool { get }
}

// MARK: - Network Errors

/// Errores relacionados con operaciones de red
enum NetworkError: AppError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    case requestFailed(Error)

    var code: String {
        switch self {
        case .noConnection: return "NET001"
        case .timeout: return "NET002"
        case .serverError(let code): return "NET003-\(code)"
        case .invalidResponse: return "NET004"
        case .requestFailed: return "NET005"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        case .invalidResponse, .requestFailed:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Sin conexión a internet. Verifica tu conexión y vuelve a intentarlo."
        case .timeout:
            return "La conexión ha tardado demasiado. Inténtalo de nuevo."
        case .serverError(let code):
            return "Error del servidor (\(code)). Inténtalo más tarde."
        case .invalidResponse:
            return "Respuesta inválida del servidor."
        case .requestFailed(let error):
            return "Error de conexión: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Errors

/// Errores relacionados con datos y almacenamiento
enum DataError: AppError {
    case notFound(resource: String)
    case decodingFailed(Error)
    case encodingFailed(Error)
    case invalidData(reason: String)
    case corruptedCache

    var code: String {
        switch self {
        case .notFound: return "DAT001"
        case .decodingFailed: return "DAT002"
        case .encodingFailed: return "DAT003"
        case .invalidData: return "DAT004"
        case .corruptedCache: return "DAT005"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .corruptedCache:
            return true // Se puede limpiar la caché
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .notFound(let resource):
            return "No se encontró: \(resource)"
        case .decodingFailed(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Error al guardar datos: \(error.localizedDescription)"
        case .invalidData(let reason):
            return "Datos inválidos: \(reason)"
        case .corruptedCache:
            return "La caché está corrupta. Limpiando datos..."
        }
    }
}

// MARK: - Permission Errors

/// Errores relacionados con permisos del sistema
enum PermissionError: AppError {
    case locationDenied
    case locationRestricted
    case locationNotDetermined
    case notificationsDenied

    var code: String {
        switch self {
        case .locationDenied: return "PER001"
        case .locationRestricted: return "PER002"
        case .locationNotDetermined: return "PER003"
        case .notificationsDenied: return "PER004"
        }
    }

    var isRecoverable: Bool {
        // Todos son recuperables abriendo Ajustes
        return true
    }

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Acceso a ubicación denegado. Habilítalo en Ajustes para usar las rutas."
        case .locationRestricted:
            return "El acceso a ubicación está restringido en este dispositivo."
        case .locationNotDetermined:
            return "Se necesita acceso a tu ubicación para guiarte por la ruta."
        case .notificationsDenied:
            return "Las notificaciones están desactivadas. Habilítalas para recibir alertas de paradas."
        }
    }
}

// MARK: - Business Logic Errors

/// Errores de lógica de negocio de la aplicación
enum BusinessError: AppError {
    case routeNotActive
    case routeAlreadyActive
    case tripAlreadyExists(city: String)
    case invalidRouteConfiguration
    case insufficientStops(minimum: Int, current: Int)
    case routeNotInTrip

    var code: String {
        switch self {
        case .routeNotActive: return "BIZ001"
        case .routeAlreadyActive: return "BIZ002"
        case .tripAlreadyExists: return "BIZ003"
        case .invalidRouteConfiguration: return "BIZ004"
        case .insufficientStops: return "BIZ005"
        case .routeNotInTrip: return "BIZ006"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .insufficientStops:
            return true // Usuario puede añadir más paradas
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .routeNotActive:
            return "No hay ninguna ruta activa."
        case .routeAlreadyActive:
            return "Ya hay una ruta en progreso. Finalízala antes de iniciar otra."
        case .tripAlreadyExists(let city):
            return "Ya tienes un viaje planificado a \(city)."
        case .invalidRouteConfiguration:
            return "La configuración de la ruta es inválida."
        case .insufficientStops(let minimum, let current):
            return "Se necesitan al menos \(minimum) paradas. Actualmente hay \(current)."
        case .routeNotInTrip:
            return "Esta ruta no pertenece al viaje seleccionado."
        }
    }
}

// MARK: - Error Logging Extension

extension AppError {
    /// Registra el error en el sistema de logging
    func log(context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let message = "[\(code)] \(context.isEmpty ? "" : "\(context): ")\(errorDescription ?? "Error desconocido")"
        Log(message, level: .error, category: .app)
    }
}
