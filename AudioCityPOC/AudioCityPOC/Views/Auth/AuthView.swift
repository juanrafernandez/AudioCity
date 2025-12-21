//
//  AuthView.swift
//  AudioCityPOC
//
//  Pantalla principal de autenticación
//  Login con email/contraseña + opciones sociales
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingRegister = false
    @State private var showingForgotPassword = false
    @State private var showPassword = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: ACSpacing.xl) {
                    // Logo
                    VStack(spacing: ACSpacing.sm) {
                        Image(systemName: "headphones.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(ACColors.primary)

                        Text("AudioCity")
                            .font(ACTypography.displayLarge)
                            .foregroundStyle(ACColors.textPrimary)
                    }

                    // Formulario Email/Password
                    VStack(spacing: ACSpacing.md) {
                        // Email
                        VStack(alignment: .leading, spacing: ACSpacing.xs) {
                            Text("Email")
                                .font(ACTypography.labelMedium)
                                .foregroundStyle(ACColors.textSecondary)

                            TextField("tu@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(ACRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ACRadius.md)
                                        .stroke(focusedField == .email ? ACColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: ACSpacing.xs) {
                            Text("Contraseña")
                                .font(ACTypography.labelMedium)
                                .foregroundStyle(ACColors.textSecondary)

                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Contraseña", text: $password)
                                    } else {
                                        SecureField("Contraseña", text: $password)
                                    }
                                }
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .password)

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
                                    .stroke(focusedField == .password ? ACColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }

                        // Olvidé contraseña
                        HStack {
                            Spacer()
                            Button("¿Olvidaste tu contraseña?") {
                                showingForgotPassword = true
                            }
                            .font(ACTypography.bodySmall)
                            .foregroundStyle(ACColors.primary)
                        }
                    }
                    .padding(.horizontal, ACSpacing.lg)

                    // Botón Iniciar Sesión
                    Button(action: login) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Iniciar sesión")
                                    .font(.system(size: 17, weight: .medium))
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

                    // Separador
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        Text("o")
                            .font(ACTypography.bodySmall)
                            .foregroundStyle(ACColors.textTertiary)
                            .padding(.horizontal, ACSpacing.md)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Botones Sociales (iconos circulares)
                    HStack(spacing: 25) {
                        // Google
                        SocialIconButton(
                            icon: {
                                Image("icon_google")
                                    .resizable()
                                    .scaledToFit()
                            },
                            isLoading: isLoading,
                            action: signInWithGoogle
                        )

                        // Apple
                        SocialIconButton(
                            icon: {
                                Image("icon_apple")
                                    .resizable()
                                    .scaledToFit()
                            },
                            isLoading: isLoading,
                            action: signInWithApple
                        )
                    }

                    // Link a registro
                    HStack(spacing: ACSpacing.xs) {
                        Text("¿No tienes cuenta?")
                            .font(ACTypography.bodyMedium)
                            .foregroundStyle(ACColors.textSecondary)

                        Button("Crear cuenta") {
                            showingRegister = true
                        }
                        .font(ACTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(ACColors.primary)
                    }
                    .padding(.bottom, ACSpacing.xl)
                }
                .padding(.horizontal, ACSpacing.lg)
            }
            .background(ACColors.background)
            .ignoresSafeArea(.keyboard)
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Ha ocurrido un error")
            }
            .onSubmit {
                switch focusedField {
                case .email:
                    focusedField = .password
                case .password:
                    if isFormValid {
                        login()
                    }
                case .none:
                    break
                }
            }
        }
    }

    // MARK: - Actions

    private func login() {
        guard isFormValid, !isLoading else { return }

        focusedField = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signInWithEmail(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }

    private func signInWithApple() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signInWithApple()
            } catch let error as SignInWithAppleError where error.isCanceled {
                // Usuario canceló
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }

    private func signInWithGoogle() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signInWithGoogle()
            } catch let error as SignInWithGoogleError where error.isCanceled {
                // Usuario canceló
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
}

// MARK: - Social Icon Button

private struct SocialIconButton<Icon: View>: View {
    let icon: () -> Icon
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    icon()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: 54, height: 54)
        }
        .disabled(isLoading)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}
