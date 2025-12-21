//
//  WelcomeNewUserView.swift
//  AudioCityPOC
//
//  Pantalla de bienvenida para usuarios nuevos (primer login con Apple/Google)
//

import SwiftUI

struct WelcomeNewUserView: View {
    @EnvironmentObject private var authService: AuthService
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.xl) {
            Spacer()

            // Icono de bienvenida
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(ACColors.primary)

            // Título
            VStack(spacing: ACSpacing.sm) {
                Text("¡Bienvenido a AudioCity!")
                    .font(ACTypography.headlineLarge)
                    .foregroundStyle(ACColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let name = authService.currentUser?.displayName, !name.isEmpty {
                    Text("Hola, \(name)")
                        .font(ACTypography.bodyLarge)
                        .foregroundStyle(ACColors.textSecondary)
                }
            }

            // Descripción
            VStack(spacing: ACSpacing.md) {
                FeatureRow(
                    icon: "headphones",
                    title: "Audioguías únicas",
                    description: "Descubre ciudades con narraciones inmersivas"
                )

                FeatureRow(
                    icon: "map",
                    title: "Rutas personalizadas",
                    description: "Crea y comparte tus propias rutas"
                )

                FeatureRow(
                    icon: "star.fill",
                    title: "Gana puntos",
                    description: "Sube de nivel completando rutas"
                )
            }
            .padding(.horizontal, ACSpacing.lg)
            .padding(.vertical, ACSpacing.xl)

            Spacer()

            // Botón continuar
            Button(action: onContinue) {
                Text("Comenzar a explorar")
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ACColors.primary)
                    .foregroundStyle(.white)
                    .cornerRadius(ACRadius.md)
            }
            .padding(.horizontal, ACSpacing.lg)
            .padding(.bottom, ACSpacing.xl)
        }
        .background(ACColors.background)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(ACColors.primary)
                .frame(width: 44, height: 44)
                .background(ACColors.primaryLight)
                .cornerRadius(ACRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ACTypography.labelMedium)
                    .foregroundStyle(ACColors.textPrimary)

                Text(description)
                    .font(ACTypography.bodySmall)
                    .foregroundStyle(ACColors.textSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeNewUserView(onContinue: {})
        .environmentObject(AuthService())
}
