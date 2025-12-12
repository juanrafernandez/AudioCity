//
//  HistoryRepository.swift
//  AudioCityPOC
//
//  Repository para persistencia del historial de rutas
//  Abstrae el almacenamiento de HistoryService
//

import Foundation

// MARK: - History Repository Protocol

protocol HistoryRepositoryProtocol {
    /// Carga todo el historial
    func loadHistory() throws -> [RouteHistory]

    /// Guarda todo el historial
    func saveHistory(_ history: [RouteHistory]) throws

    /// Añade un registro al historial
    func addRecord(_ record: RouteHistory) throws

    /// Actualiza un registro existente
    func updateRecord(_ record: RouteHistory) throws

    /// Elimina un registro por ID
    func deleteRecord(id: String) throws

    /// Obtiene un registro por ID
    func getRecord(id: String) throws -> RouteHistory?

    /// Limpia todo el historial
    func clearHistory() throws
}

// MARK: - History Repository Implementation

final class HistoryRepository: HistoryRepositoryProtocol {

    // MARK: - Dependencies
    private let storage: StorageRepositoryProtocol

    // MARK: - Initialization

    init(storage: StorageRepositoryProtocol = UserDefaultsStorageRepository()) {
        self.storage = storage
    }

    // MARK: - HistoryRepositoryProtocol

    func loadHistory() throws -> [RouteHistory] {
        let history: [RouteHistory]? = try storage.load(forKey: StorageKeys.history)
        return history ?? []
    }

    func saveHistory(_ history: [RouteHistory]) throws {
        try storage.save(history, forKey: StorageKeys.history)
    }

    func addRecord(_ record: RouteHistory) throws {
        var history = try loadHistory()
        history.insert(record, at: 0) // Añadir al principio (más reciente primero)
        try saveHistory(history)
    }

    func updateRecord(_ record: RouteHistory) throws {
        var history = try loadHistory()

        guard let index = history.firstIndex(where: { $0.id == record.id }) else {
            throw StorageError.notFound(record.id)
        }

        history[index] = record
        try saveHistory(history)
    }

    func deleteRecord(id: String) throws {
        var history = try loadHistory()
        history.removeAll { $0.id == id }
        try saveHistory(history)
    }

    func getRecord(id: String) throws -> RouteHistory? {
        let history = try loadHistory()
        return history.first { $0.id == id }
    }

    func clearHistory() throws {
        try saveHistory([])
    }
}

#if DEBUG
// MARK: - Mock History Repository for Tests

final class MockHistoryRepository: HistoryRepositoryProtocol {
    var mockHistory: [RouteHistory] = []
    var shouldFail = false

    func loadHistory() throws -> [RouteHistory] {
        if shouldFail { throw StorageError.notFound("history") }
        return mockHistory
    }

    func saveHistory(_ history: [RouteHistory]) throws {
        if shouldFail { throw StorageError.writeFailed(NSError(domain: "", code: -1)) }
        mockHistory = history
    }

    func addRecord(_ record: RouteHistory) throws {
        mockHistory.insert(record, at: 0)
    }

    func updateRecord(_ record: RouteHistory) throws {
        guard let index = mockHistory.firstIndex(where: { $0.id == record.id }) else {
            throw StorageError.notFound(record.id)
        }
        mockHistory[index] = record
    }

    func deleteRecord(id: String) throws {
        mockHistory.removeAll { $0.id == id }
    }

    func getRecord(id: String) throws -> RouteHistory? {
        return mockHistory.first { $0.id == id }
    }

    func clearHistory() throws {
        mockHistory.removeAll()
    }
}
#endif
