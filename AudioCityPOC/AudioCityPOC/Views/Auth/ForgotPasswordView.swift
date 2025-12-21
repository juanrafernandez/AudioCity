//
//  ForgotPasswordView.swift
//  AudioCityPOC
//
//  Vista para recuperar contraseña
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var emailSent = false

    @FocusState private var isEmailFocused: Bool

    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    var body: some View {
        VStack(spacing: ACSpacing.xl) {
            Spacer()

            if emailSent {
                // Estado de éxito
                successView
            } else {
                // Formulario
                formView
            }

            Spacer()
        }
        .padding(.horizontal, ACSpacing.lg)
        .background(ACColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(ACColors.textSecondary)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Ha ocurrido un error")
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: ACSpacing.xl) {
            // Header
            VStack(spacing: ACSpacing.md) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundStyle(ACColors.primary)

                Text("¿Olvidaste tu contraseña?")
                    .font(ACTypography.headlineLarge)
                    .foregroundStyle(ACColors.textPrimary)

                Text("Introduce tu email y te enviaremos\nun enlace para restablecerla")
                    .font(ACTypography.bodyMedium)
                    .foregroundStyle(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Campo email
            VStack(alignment: .leading, spacing: ACSpacing.xs) {
                Text("Email")
                    .font(ACTypography.labelMedium)
                    .foregroundStyle(ACColors.textSecondary)

                TextField("tu@email.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isEmailFocused)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(ACRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: ACRadius.md)
                            .stroke(isEmailFocused ? ACColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                    )

                if !email.isEmpty && !isEmailValid {
                    Text("Email no válido")
                        .font(ACTypography.caption)
                        .foregroundStyle(ACColors.error)
                }
            }

            // Botón enviar
            Button(action: sendResetEmail) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Enviar enlace")
                            .font(ACTypography.labelMedium)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEmailValid ? ACColors.primary : ACColors.primary.opacity(0.5))
                .foregroundStyle(.white)
                .cornerRadius(ACRadius.md)
            }
            .disabled(!isEmailValid || isLoading)

            // Volver a login
            Button("Volver a iniciar sesión") {
                dismiss()
            }
            .font(ACTypography.bodyMedium)
            .foregroundStyle(ACColors.primary)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: ACSpacing.xl) {
            // Icono de éxito
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(ACColors.success)

            VStack(spacing: ACSpacing.sm) {
                Text("Email enviado")
                    .font(ACTypography.headlineLarge)
                    .foregroundStyle(ACColors.textPrimary)

                Text("Hemos enviado un enlace de recuperación a:")
                    .font(ACTypography.bodyMedium)
                    .foregroundStyle(ACColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(email)
                    .font(ACTypography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(ACColors.primary)
            }

            Text("Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.")
                .font(ACTypography.bodySmall)
                .foregroundStyle(ACColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ACSpacing.lg)

            // Botones
            VStack(spacing: ACSpacing.md) {
                Button(action: { dismiss() }) {
                    Text("Volver a iniciar sesión")
                        .font(ACTypography.labelMedium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ACColors.primary)
                        .foregroundStyle(.white)
                        .cornerRadius(ACRadius.md)
                }

                Button(action: {
                    emailSent = false
                    email = ""
                }) {
                    Text("Usar otro email")
                        .font(ACTypography.bodyMedium)
                        .foregroundStyle(ACColors.primary)
                }
            }
        }
    }

    // MARK: - Actions

    private func sendResetEmail() {
        guard isEmailValid, !isLoading else { return }

        isEmailFocused = false
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                withAnimation {
                    emailSent = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthService())
    }
}
