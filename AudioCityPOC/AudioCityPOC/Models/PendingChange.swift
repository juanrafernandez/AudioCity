//
//  PendingChange.swift
//  AudioCityPOC
//
//  Modelo para cambios pendientes de sincronización (offline queue)
//

import Foundation

/// Tipo de cambio pendiente
enum ChangeType: String, Codable {
    case create
    case update
    case delete
}

/// Colección de Firebase afectada
enum FirebaseCollection: String, Codable {
    case trips
    case userRoutes
    case history
    case pointsTransactions
    case profile
}

/// Cambio pendiente de sincronización
struct PendingChange: Identifiable, Codable {
    let id: String
    let type: ChangeType
    let collection: FirebaseCollection
    let documentId: String
    let data: Data?  // JSON encoded data for create/update
    let timestamp: Date
    var retryCount: Int

    init(
        id: String = UUID().uuidString,
        type: ChangeType,
        collection: FirebaseCollection,
        documentId: String,
        data: Data? = nil,
        timestamp: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.type = type
        self.collection = collection
        self.documentId = documentId
        self.data = data
        self.timestamp = timestamp
        self.retryCount = retryCount
    }

    /// Número máximo de reintentos
    static let maxRetries = 3
}

// MARK: - Pending Changes Manager

class PendingChangesManager {
    static let shared = PendingChangesManager()

    private let storageKey = "audiocity_pending_changes"
    private let userDefaults = UserDefaults.standard

    private init() {}

    /// Obtener todos los cambios pendientes
    func getPendingChanges() -> [PendingChange] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([PendingChange].self, from: data)
        } catch {
            Log("Error cargando cambios pendientes: \(error)", level: .error, category: .firebase)
            return []
        }
    }

    /// Añadir un cambio pendiente
    func addPendingChange(_ change: PendingChange) {
        var changes = getPendingChanges()
        changes.append(change)
        savePendingChanges(changes)
        Log("Cambio pendiente añadido: \(change.type.rawValue) en \(change.collection.rawValue)", level: .info, category: .firebase)
    }

    /// Eliminar un cambio procesado
    func removePendingChange(_ changeId: String) {
        var changes = getPendingChanges()
        changes.removeAll { $0.id == changeId }
        savePendingChanges(changes)
    }

    /// Incrementar contador de reintentos
    func incrementRetryCount(for changeId: String) {
        var changes = getPendingChanges()
        if let index = changes.firstIndex(where: { $0.id == changeId }) {
            changes[index].retryCount += 1
            savePendingChanges(changes)
        }
    }

    /// Limpiar cambios que exceden el máximo de reintentos
    func cleanupFailedChanges() {
        var changes = getPendingChanges()
        let initialCount = changes.count
        changes.removeAll { $0.retryCount >= PendingChange.maxRetries }

        if changes.count < initialCount {
            savePendingChanges(changes)
            Log("Eliminados \(initialCount - changes.count) cambios fallidos", level: .warning, category: .firebase)
        }
    }

    /// Limpiar todos los cambios pendientes
    func clearAllPendingChanges() {
        userDefaults.removeObject(forKey: storageKey)
        Log("Todos los cambios pendientes eliminados", level: .info, category: .firebase)
    }

    /// Número de cambios pendientes
    var pendingCount: Int {
        getPendingChanges().count
    }

    /// Hay cambios pendientes
    var hasPendingChanges: Bool {
        pendingCount > 0
    }

    // MARK: - Private

    private func savePendingChanges(_ changes: [PendingChange]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(changes)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            Log("Error guardando cambios pendientes: \(error)", level: .error, category: .firebase)
        }
    }
}
