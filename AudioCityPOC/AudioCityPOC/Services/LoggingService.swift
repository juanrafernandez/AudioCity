//
//  LoggingService.swift
//  AudioCityPOC
//
//  Sistema de logging estructurado para reemplazar print() statements
//  Usa os.log para mejor integración con Console.app y debugging
//

import Foundation
import os.log

// MARK: - Log Level
enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case success = "✅"

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .success: return .info
        }
    }
}

// MARK: - Log Category
enum LogCategory: String {
    case app = "App"
    case location = "Location"
    case audio = "Audio"
    case firebase = "Firebase"
    case route = "Route"
    case cache = "Cache"
    case points = "Points"
    case history = "History"
    case trips = "Trips"
    case ui = "UI"
    case network = "Network"
    case liveActivity = "LiveActivity"
    case auth = "Auth"
}

// MARK: - Logging Service
final class LoggingService {
    static let shared = LoggingService()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.audiocity.poc"
    private var loggers: [LogCategory: Logger] = [:]

    /// Nivel mínimo de log (configurable por entorno)
    var minimumLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .warning
        #endif
    }()

    /// Flag para deshabilitar logs en tests
    var isEnabled: Bool = true

    private init() {
        // Pre-crear loggers para cada categoría
        for category in [LogCategory.app, .location, .audio, .firebase, .route, .cache, .points, .history, .trips, .ui, .network, .liveActivity, .auth] {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    // MARK: - Main Logging Method
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled else { return }
        guard shouldLog(level: level) else { return }

        let fileName = (file as NSString).lastPathComponent
        let logger = loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)

        let formattedMessage = "\(level.rawValue) [\(category.rawValue)] \(message) (\(fileName):\(line))"

        switch level {
        case .debug:
            logger.debug("\(formattedMessage)")
        case .info, .success:
            logger.info("\(formattedMessage)")
        case .warning:
            logger.warning("\(formattedMessage)")
        case .error:
            logger.error("\(formattedMessage)")
        }

        // También imprimir en consola durante desarrollo
        #if DEBUG
        print(formattedMessage)
        #endif
    }

    // MARK: - Convenience Methods

    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    func success(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, category: category, file: file, function: function, line: line)
    }

    // MARK: - Private

    private func shouldLog(level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .success, .warning, .error]
        guard let currentIndex = levels.firstIndex(of: minimumLogLevel),
              let messageIndex = levels.firstIndex(of: level) else {
            return true
        }
        return messageIndex >= currentIndex
    }
}

// MARK: - Global Convenience Functions
/// Función global para logging rápido (reemplaza print)
func Log(_ message: String, level: LogLevel = .info, category: LogCategory = .app) {
    LoggingService.shared.log(message, level: level, category: category)
}

/// Alias para debug
func LogDebug(_ message: String, category: LogCategory = .app) {
    LoggingService.shared.debug(message, category: category)
}

/// Alias para error
func LogError(_ message: String, category: LogCategory = .app) {
    LoggingService.shared.error(message, category: category)
}

/// Alias para warning
func LogWarning(_ message: String, category: LogCategory = .app) {
    LoggingService.shared.warning(message, category: category)
}
