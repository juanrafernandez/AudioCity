//
//  AuthContainerView.swift
//  AudioCityPOC
//
//  Contenedor principal para el flujo de autenticación
//

import SwiftUI

/// Vista contenedor que muestra el flujo de autenticación o la app principal
/// según el estado de autenticación del usuario
struct AuthContainerView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                // Pantalla de carga mientras se verifica la sesión
                LoadingAuthView()

            case .unauthenticated:
                // Flujo de autenticación
                AuthView()

            case .authenticated:
                if authService.isNewUser {
                    // Bienvenida para usuarios nuevos
                    WelcomeNewUserView {
                        authService.markOnboardingComplete()
                    }
                } else {
                    // App principal
                    ContentView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authState)
        .animation(.easeInOut(duration: 0.3), value: authService.isNewUser)
    }
}

// MARK: - Loading View

private struct LoadingAuthView: View {
    var body: some View {
        ZStack {
            ACColors.primaryLight
                .ignoresSafeArea()

            VStack(spacing: ACSpacing.lg) {
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(ACColors.primary)

                Text("AudioCity")
                    .font(ACTypography.displayLarge)
                    .foregroundStyle(ACColors.textPrimary)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ACColors.primary)
                    .padding(.top, ACSpacing.md)
            }
        }
    }
}

#Preview("Loading") {
    LoadingAuthView()
}

#Preview("Container") {
    AuthContainerView()
        .environmentObject(AuthService())
}
