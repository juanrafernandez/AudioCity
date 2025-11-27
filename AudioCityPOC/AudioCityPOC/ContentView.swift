//
//  ContentView.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    @State private var showMainContent = false

    var body: some View {
        ZStack {
            // Contenido principal
            if showMainContent {
                MainTabView()
                    .transition(.opacity)
            }

            // Splash screen
            if isLoading {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Simular tiempo de carga mínimo para mostrar animación
            // En producción, esto esperaría a que se carguen los datos reales
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showMainContent = true
                }
                // Pequeño delay antes de ocultar el splash para suavizar transición
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
