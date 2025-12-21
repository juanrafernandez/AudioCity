//
//  NetworkMonitor.swift
//  AudioCityPOC
//
//  Monitor de conectividad de red
//

import Foundation
import Network
import Combine

/// Monitor de conectividad de red
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    /// Iniciar monitoreo de red
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown

                if path.status == .satisfied {
                    Log("Conexión de red restaurada (\(self?.connectionType ?? .unknown))", level: .success, category: .app)
                    // Procesar cambios pendientes cuando hay conexión
                    self?.processPendingChangesIfNeeded()
                } else {
                    Log("Sin conexión de red", level: .warning, category: .app)
                }
            }
        }

        monitor.start(queue: queue)
        Log("NetworkMonitor iniciado", level: .info, category: .app)
    }

    /// Detener monitoreo de red
    func stopMonitoring() {
        monitor.cancel()
        Log("NetworkMonitor detenido", level: .info, category: .app)
    }

    /// Obtener tipo de conexión
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }

    /// Procesar cambios pendientes cuando hay conexión
    private func processPendingChangesIfNeeded() {
        guard isConnected else { return }

        let pendingManager = PendingChangesManager.shared
        if pendingManager.hasPendingChanges {
            Log("Hay \(pendingManager.pendingCount) cambios pendientes para sincronizar", level: .info, category: .firebase)
            // El AuthService o los servicios individuales procesarán los cambios
            NotificationCenter.default.post(name: .networkDidBecomeAvailable, object: nil)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkDidBecomeAvailable = Notification.Name("networkDidBecomeAvailable")
}

// MARK: - Connection Type Description

extension NetworkMonitor.ConnectionType: CustomStringConvertible {
    var description: String {
        switch self {
        case .wifi: return "WiFi"
        case .cellular: return "Datos móviles"
        case .ethernet: return "Ethernet"
        case .unknown: return "Desconocido"
        }
    }
}
