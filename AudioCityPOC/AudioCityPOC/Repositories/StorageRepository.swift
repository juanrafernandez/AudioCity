//
//  StorageRepository.swift
//  AudioCityPOC
//
//  Abstracción de almacenamiento local
//  Permite cambiar la implementación (UserDefaults, CoreData, etc.) sin afectar servicios
//

import Foundation

// MARK: - Storage Repository Protocol

/// Protocolo para almacenamiento local de datos
/// Abstrae la fuente de almacenamiento (UserDefaults, CoreData, archivos, etc.)
protocol StorageRepositoryProtocol {
    /// Guarda un valor Codable para una clave
    func save<T: Codable>(_ value: T, forKey key: String) throws

    /// Carga un valor Codable para una clave
    func load<T: Codable>(forKey key: String) throws -> T?

    /// Elimina el valor para una clave
    func delete(forKey key: String)

    /// Verifica si existe un valor para una clave
    func exists(forKey key: String) -> Bool

    /// Limpia todo el almacenamiento
    func clearAll()
}

// MARK: - Storage Errors

enum StorageError: Error, LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case notFound(String)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Error codificando datos: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Error decodificando datos: \(error.localizedDescription)"
        case .notFound(let key):
            return "No se encontró valor para la clave: \(key)"
        case .writeFailed(let error):
            return "Error escribiendo datos: \(error.localizedDescription)"
        }
    }
}

// MARK: - UserDefaults Storage Repository

/// Implementación de StorageRepository usando UserDefaults
final class UserDefaultsStorageRepository: StorageRepositoryProtocol {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Prefijo para las claves (útil para tests o múltiples usuarios)
    private let keyPrefix: String

    // MARK: - Initialization

    init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "audiocity_"
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - StorageRepositoryProtocol

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let prefixedKey = prefixedKey(for: key)

        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: prefixedKey)
            Log("Guardado '\(key)'", level: .debug, category: .app)
        } catch {
            Log("Error guardando '\(key)' - \(error.localizedDescription)", level: .error, category: .app)
            throw StorageError.encodingFailed(error)
        }
    }

    func load<T: Codable>(forKey key: String) throws -> T? {
        let prefixedKey = prefixedKey(for: key)

        guard let data = userDefaults.data(forKey: prefixedKey) else {
            return nil
        }

        do {
            let value = try decoder.decode(T.self, from: data)
            Log("Cargado '\(key)'", level: .debug, category: .app)
            return value
        } catch {
            Log("Error cargando '\(key)' - \(error.localizedDescription)", level: .error, category: .app)
            throw StorageError.decodingFailed(error)
        }
    }

    func delete(forKey key: String) {
        let prefixedKey = prefixedKey(for: key)
        userDefaults.removeObject(forKey: prefixedKey)
        Log("Eliminado '\(key)'", level: .debug, category: .app)
    }

    func exists(forKey key: String) -> Bool {
        let prefixedKey = prefixedKey(for: key)
        return userDefaults.object(forKey: prefixedKey) != nil
    }

    func clearAll() {
        // Obtener todas las claves con el prefijo
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let prefixedKeys = allKeys.filter { $0.hasPrefix(keyPrefix) }

        for key in prefixedKeys {
            userDefaults.removeObject(forKey: key)
        }

        Log("Limpiado todo el almacenamiento (\(prefixedKeys.count) claves)", level: .info, category: .app)
    }

    // MARK: - Private Methods

    private func prefixedKey(for key: String) -> String {
        return "\(keyPrefix)\(key)"
    }
}

// MARK: - In-Memory Storage Repository (para tests)

#if DEBUG
/// Implementación en memoria para tests
final class InMemoryStorageRepository: StorageRepositoryProtocol {

    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try encoder.encode(value)
        storage[key] = data
    }

    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let data = storage[key] else { return nil }
        return try decoder.decode(T.self, from: data)
    }

    func delete(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        return storage[key] != nil
    }

    func clearAll() {
        storage.removeAll()
    }
}
#endif

// MARK: - Storage Keys

/// Claves centralizadas para el almacenamiento
enum StorageKeys {
    static let trips = "trips"
    static let favorites = "favorites"
    static let history = "history"
    static let points = "points"
    static let pointsTransactions = "points_transactions"
    static let userRoutes = "user_routes"
    static let offlineCache = "offline_cache"
    static let lastRouteCompletionDate = "last_route_completion_date"
}
