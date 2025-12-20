//
//  ErrorHandling.swift
//  AudioCityPOC
//
//  Utilidades para manejo centralizado de errores
//  Incluye ErrorHandler para UI y funciones de retry
//

import Foundation
import SwiftUI
import Combine

// MARK: - Error Handler

/// Manejador centralizado de errores para la aplicación
/// Proporciona estado observable para mostrar errores en la UI
@MainActor
final class ErrorHandler: ObservableObject {

    // MARK: - Singleton
    static let shared = ErrorHandler()

    // MARK: - Published Properties

    /// Error actual para mostrar en UI
    @Published var currentError: (any AppError)?

    /// Controla la visibilidad del error en UI
    @Published var showError: Bool = false

    /// Historial de errores recientes (útil para debugging)
    @Published private(set) var recentErrors: [ErrorEntry] = []

    // MARK: - Types

    struct ErrorEntry: Identifiable {
        let id = UUID()
        let error: any AppError
        let context: String
        let timestamp: Date
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Maneja un error de tipo AppError
    /// - Parameters:
    ///   - error: El error a manejar
    ///   - context: Contexto adicional (ej: nombre de la operación)
    func handle(_ error: any AppError, context: String = "") {
        error.log(context: context)

        currentError = error
        showError = true

        // Añadir al historial (máximo 10 errores)
        let entry = ErrorEntry(error: error, context: context, timestamp: Date())
        recentErrors.insert(entry, at: 0)
        if recentErrors.count > 10 {
            recentErrors.removeLast()
        }
    }

    /// Maneja cualquier Error, convirtiéndolo a AppError si es posible
    /// - Parameters:
    ///   - error: El error a manejar
    ///   - context: Contexto adicional
    func handle(_ error: Error, context: String = "") {
        if let appError = error as? any AppError {
            handle(appError, context: context)
        } else {
            // Convertir a DataError genérico
            let wrappedError = DataError.invalidData(reason: error.localizedDescription)
            handle(wrappedError, context: context)
        }
    }

    /// Descarta el error actual
    func dismiss() {
        showError = false
        // Delay para permitir animación de cierre
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentError = nil
        }
    }

    /// Limpia el historial de errores
    func clearHistory() {
        recentErrors.removeAll()
    }
}

// MARK: - Retry Configuration

/// Configuración para reintentos automáticos
struct RetryConfiguration {
    /// Número máximo de intentos
    let maxAttempts: Int

    /// Delay inicial entre intentos (segundos)
    let initialDelay: TimeInterval

    /// Multiplicador para backoff exponencial
    let backoffMultiplier: Double

    /// Delay máximo entre intentos
    let maxDelay: TimeInterval

    /// Configuración por defecto
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 1.0,
        backoffMultiplier: 2.0,
        maxDelay: 10.0
    )

    /// Configuración agresiva (más intentos, delays cortos)
    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        initialDelay: 0.5,
        backoffMultiplier: 1.5,
        maxDelay: 5.0
    )

    /// Configuración conservadora (pocos intentos, delays largos)
    static let conservative = RetryConfiguration(
        maxAttempts: 2,
        initialDelay: 2.0,
        backoffMultiplier: 2.0,
        maxDelay: 30.0
    )
}

// MARK: - Retry Function

/// Ejecuta una operación async con reintentos automáticos
/// - Parameters:
///   - config: Configuración de reintentos
///   - shouldRetry: Closure opcional para determinar si reintentar basado en el error
///   - operation: La operación a ejecutar
/// - Returns: El resultado de la operación
/// - Throws: El último error si todos los intentos fallan
func withRetry<T>(
    config: RetryConfiguration = .default,
    shouldRetry: ((Error) -> Bool)? = nil,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    var delay = config.initialDelay

    for attempt in 1...config.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Verificar si debemos reintentar
            if let shouldRetry = shouldRetry, !shouldRetry(error) {
                throw error
            }

            // Si es el último intento, lanzar el error
            if attempt == config.maxAttempts {
                break
            }

            // Log del reintento
            Log("Reintento \(attempt)/\(config.maxAttempts) después de \(String(format: "%.1f", delay))s",
                level: .warning, category: .app)

            // Esperar antes del siguiente intento
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // Incrementar delay con backoff exponencial
            delay = min(delay * config.backoffMultiplier, config.maxDelay)
        }
    }

    throw lastError!
}

// MARK: - Result Extensions

extension Result where Failure == Error {
    /// Convierte el Result a un AppError si es posible
    var appError: (any AppError)? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error as? any AppError
        }
    }
}

// MARK: - Error View Modifier

/// Modifier para mostrar errores automáticamente desde ErrorHandler
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { error in
                Button("Aceptar") {
                    errorHandler.dismiss()
                }
                if error.isRecoverable {
                    Button("Reintentar") {
                        // El retry se maneja externamente
                        errorHandler.dismiss()
                    }
                }
            } message: { error in
                Text(error.errorDescription ?? "Ha ocurrido un error")
            }
    }
}

extension View {
    /// Añade manejo automático de errores del ErrorHandler
    func withErrorHandling() -> some View {
        modifier(ErrorAlertModifier())
    }
}
