//
//  AudioCityPOCApp.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//

import SwiftUI
import FirebaseCore

@main
struct AudioCityPOCApp: App {

    init() {
        // Configurar Firebase
        FirebaseApp.configure()
        print("✅ Firebase configurado")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
