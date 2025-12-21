//
//  NotificationService.swift
//  AudioCityPOC
//
//  Servicio para gestionar notificaciones locales al llegar a paradas
//

import Foundation
import UserNotifications
import UIKit
import Combine

class NotificationService: NSObject, ObservableObject, NotificationServiceProtocol {

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var lastActionStopId: String?
    @Published var lastAction: NotificationAction?

    // MARK: - Constants
    private let categoryIdentifier = "STOP_ARRIVAL"
    private let listenActionIdentifier = "LISTEN_ACTION"
    private let skipActionIdentifier = "SKIP_ACTION"

    // MARK: - Notification Actions
    enum NotificationAction: String {
        case listen
        case skip
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupNotificationCategories()
    }

    // MARK: - Setup
    private func setupNotificationCategories() {
        // Acción "Escuchar"
        let listenAction = UNNotificationAction(
            identifier: listenActionIdentifier,
            title: "Escuchar",
            options: [.foreground]
        )

        // Acción "Saltar"
        let skipAction = UNNotificationAction(
            identifier: skipActionIdentifier,
            title: "Saltar",
            options: [.destructive]
        )

        // Categoría con acciones
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [listenAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Public Methods

    /// Solicitar permisos de notificaciones
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    Log("Permisos de notificación concedidos", level: .success, category: .app)
                } else {
                    Log("Permisos de notificación denegados", level: .warning, category: .app)
                }
                if let error = error {
                    Log("Error de notificaciones - \(error.localizedDescription)", level: .error, category: .app)
                }
            }
        }
    }

    /// Verificar estado de autorización
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Mostrar notificación al llegar a una parada
    func showStopArrivalNotification(stop: Stop) {
        let content = UNMutableNotificationContent()
        content.title = "Has llegado a un punto de interés"
        content.subtitle = stop.name
        content.body = stop.description
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = [
            "stopId": stop.id,
            "stopName": stop.name
        ]

        // Añadir imagen si existe
        if let imageUrl = stop.imageUrl, !imageUrl.isEmpty {
            addImageAttachment(to: content, imageUrl: imageUrl, stopId: stop.id)
        }

        // Crear trigger inmediato
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        // Crear request
        let request = UNNotificationRequest(
            identifier: "stop-\(stop.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        // Programar notificación
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Log("Error programando notificación - \(error.localizedDescription)", level: .error, category: .app)
            } else {
                Log("Notificación programada para - \(stop.name)", level: .info, category: .app)
            }
        }
    }

    /// Cancelar todas las notificaciones pendientes
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        Log("Notificaciones pendientes canceladas", level: .info, category: .app)
    }

    /// Cancelar notificación de una parada específica
    func cancelNotification(for stopId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains("stop-\(stopId)") }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: identifiersToRemove
            )
        }
    }

    // MARK: - Private Methods

    private func addImageAttachment(to content: UNMutableNotificationContent, imageUrl: String, stopId: String) {
        guard let url = URL(string: imageUrl) else { return }

        // Descargar imagen en background
        // Captura explícita para evitar retención de self
        URLSession.shared.dataTask(with: url) { [stopId] data, response, error in
            guard let data = data, error == nil else { return }

            // Guardar temporalmente
            let tempDir = FileManager.default.temporaryDirectory
            let imageFile = tempDir.appendingPathComponent("\(stopId).jpg")

            do {
                try data.write(to: imageFile)
                let attachment = try UNNotificationAttachment(
                    identifier: "image-\(stopId)",
                    url: imageFile,
                    options: nil
                )
                content.attachments = [attachment]
            } catch {
                Log("Error adjuntando imagen - \(error.localizedDescription)", level: .error, category: .app)
            }
        }.resume()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {

    // Mostrar notificación incluso con la app en foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Manejar acciones de notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let stopId = userInfo["stopId"] as? String

        switch response.actionIdentifier {
        case listenActionIdentifier:
            Log("Usuario eligió ESCUCHAR - \(stopId ?? "unknown")", level: .info, category: .app)
            DispatchQueue.main.async {
                self.lastActionStopId = stopId
                self.lastAction = .listen
            }

        case skipActionIdentifier:
            Log("Usuario eligió SALTAR - \(stopId ?? "unknown")", level: .info, category: .app)
            DispatchQueue.main.async {
                self.lastActionStopId = stopId
                self.lastAction = .skip
            }

        case UNNotificationDefaultActionIdentifier:
            // Usuario tocó la notificación (sin botón específico)
            Log("Usuario tocó notificación - \(stopId ?? "unknown")", level: .info, category: .app)
            DispatchQueue.main.async {
                self.lastActionStopId = stopId
                self.lastAction = .listen
            }

        default:
            break
        }

        completionHandler()
    }
}
