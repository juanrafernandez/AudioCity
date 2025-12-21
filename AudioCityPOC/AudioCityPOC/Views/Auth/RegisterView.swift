//
//  RegisterView.swift
//  AudioCityPOC
//
//  Vista de registro con email y contraseña
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, email, password, confirmPassword
    }

    // MARK: - Validaciones

    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    private var isPasswordValid: Bool {
        // Mínimo 8 caracteres, 1 mayúscula, 1 número
        let hasMinLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasMinLength && hasUppercase && hasNumber
    }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var isFormValid: Bool {
        !name.isEmpty && isEmailValid && isPasswordValid && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ACSpacing.xl) {
                // Header
                VStack(spacing: ACSpacing.sm) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(ACColors.primary)

                    Text("Crear cuenta")
                        .font(ACTypography.headlineLarge)
                        .foregroundStyle(ACColors.textPrimary)

                    Text("Únete a la comunidad AudioCity")
                        .font(ACTypography.bodyMedium)
                        .foregroundStyle(ACColors.textSecondary)
                }
                .padding(.top, ACSpacing.lg)

                // Formulario
                VStack(spacing: ACSpacing.md) {
                    // Nombre
                    FormField(
                        label: "Nombre",
                        placeholder: "Tu nombre",
                        text: $name,
                        isFocused: focusedField == .name,
                        contentType: .name,
                        onFocus: { focusedField = .name }
                    )

                    // Email
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        FormField(
                            label: "Email",
                            placeholder: "tu@email.com",
                            text: $email,
                            isFocused: focusedField == .email,
                            keyboardType: .emailAddress,
                            contentType: .emailAddress,
                            autocapitalization: false,
                            onFocus: { focusedField = .email }
                        )

                        if !email.isEmpty && !isEmailValid {
                            Text("Email no válido")
                                .font(ACTypography.caption)
                                .foregroundStyle(ACColors.error)
                        }
                    }

                    // Contraseña
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        SecureFormField(
                            label: "Contraseña",
                            placeholder: "Mínimo 8 caracteres",
                            text: $password,
                            isFocused: focusedField == .password,
                            onFocus: { focusedField = .password }
                        )

                        // Requisitos de contraseña
                        VStack(alignment: .leading, spacing: 2) {
                            PasswordRequirement(
                                text: "Mínimo 8 caracteres",
                                isMet: password.count >= 8
                            )
                            PasswordRequirement(
                                text: "Una letra mayúscula",
                                isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
                            )
                            PasswordRequirement(
                                text: "Un número",
                                isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
                            )
                        }
                        .padding(.top, 4)
                    }

                    // Confirmar contraseña
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        SecureFormField(
                            label: "Confirmar contraseña",
                            placeholder: "Repite tu contraseña",
                            text: $confirmPassword,
                            isFocused: focusedField == .confirmPassword,
                            onFocus: { focusedField = .confirmPassword }
                        )

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Las contraseñas no coinciden")
                                .font(ACTypography.caption)
                                .foregroundStyle(ACColors.error)
                        }
                    }
                }
                .padding(.horizontal, ACSpacing.lg)

                // Botón de registro
                Button(action: register) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Crear cuenta")
                                .font(ACTypography.labelMedium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? ACColors.primary : ACColors.primary.opacity(0.5))
                    .foregroundStyle(.white)
                    .cornerRadius(ACRadius.md)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, ACSpacing.lg)

            }
            .padding(.bottom, ACSpacing.lg)
        }
        .background(ACColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Ha ocurrido un error")
        }
    }

    // MARK: - Actions

    private func register() {
        guard isFormValid, !isLoading else { return }

        focusedField = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signUpWithEmail(
                    email: email,
                    password: password,
                    name: name
                )
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Form Components

private struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: Bool = true
    let onFocus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.xs) {
            Text(label)
                .font(ACTypography.labelMedium)
                .foregroundStyle(ACColors.textSecondary)

            TextField(placeholder, text: $text)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization ? .words : .none)
                .autocorrectionDisabled()
                .padding()
                .background(Color.white)
                .cornerRadius(ACRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .stroke(isFocused ? ACColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    onFocus()
                }
        }
    }
}

private struct SecureFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    let onFocus: () -> Void

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.xs) {
            Text(label)
                .font(ACTypography.labelMedium)
                .foregroundStyle(ACColors.textSecondary)

            HStack {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .textContentType(.password)
                .autocapitalization(.none)
                .autocorrectionDisabled()

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(ACColors.textTertiary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(ACRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.md)
                    .stroke(isFocused ? ACColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .onTapGesture {
                onFocus()
            }
        }
    }
}

private struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(isMet ? ACColors.success : ACColors.textTertiary)

            Text(text)
                .font(ACTypography.caption)
                .foregroundStyle(isMet ? ACColors.success : ACColors.textTertiary)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthService())
    }
}
