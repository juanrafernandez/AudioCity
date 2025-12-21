//
//  AudioCityPOCApp.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//

import SwiftUI
import FirebaseCore
import UIKit

@main
struct AudioCityPOCApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // Container principal de dependencias - única fuente de instancias
    @StateObject private var container = DependencyContainer()

    init() {
        // Configurar Firebase
        FirebaseApp.configure()
        Log("Firebase configurado", level: .success, category: .firebase)

        // Configurar apariencia de navegación para asegurar contraste correcto
        configureNavigationBarAppearance()
    }

    private func configureNavigationBarAppearance() {
        // Configurar colores del navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) // ACColors.background
        appearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)] // ACColors.textPrimary
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 1.0, green: 0.34, blue: 0.34, alpha: 1.0) // ACColors.primary
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)  // Forzar modo claro - el sistema de diseño está optimizado para light mode
                // Inyectar todas las dependencias en el environment
                .environmentObject(container)
                .environmentObject(container.tripService)
                .environmentObject(container.pointsService)
                .environmentObject(container.historyService)
                .environmentObject(container.userRoutesService)
                .environmentObject(container.audioPreviewService)
                .environmentObject(container.notificationService)
                .environmentObject(container.favoritesService)
                .environmentObject(container.exploreViewModel)
                .environmentObject(container.routeStopsState)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background {
                        // La app pasa a background - terminar Live Activity
                        Log("App en background - cerrando Live Activity", level: .info, category: .app)
                        LiveActivityServiceWrapper.shared.endActivity()
                    }
                }
        }
    }
}
