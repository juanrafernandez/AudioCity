//
//  SignInWithAppleHelper.swift
//  AudioCityPOC
//
//  Helper para Sign in with Apple
//

import Foundation
import AuthenticationServices
import CryptoKit

/// Tokens resultantes de Sign in with Apple
struct AppleSignInTokens {
    let token: String
    let nonce: String
    let fullName: PersonNameComponents?
    let email: String?
}

/// Helper para manejar Sign in with Apple
@MainActor
final class SignInWithAppleHelper: NSObject {

    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInTokens, Error>?

    /// Iniciar flujo de Sign in with Apple
    func startSignInWithAppleFlow() async throws -> AppleSignInTokens {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let nonce = randomNonceString()
            currentNonce = nonce

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    // MARK: - Nonce Generation

    /// Generar nonce aleatorio para seguridad
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    /// SHA256 hash del nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SignInWithAppleHelper: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            continuation?.resume(throwing: SignInWithAppleError.invalidCredential)
            continuation = nil
            return
        }

        let tokens = AppleSignInTokens(
            token: idTokenString,
            nonce: nonce,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email
        )

        continuation?.resume(returning: tokens)
        continuation = nil

        Log("Sign in with Apple completado", level: .success, category: .auth)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError

        // Manejar cancelación por el usuario
        if nsError.domain == ASAuthorizationError.errorDomain {
            switch nsError.code {
            case ASAuthorizationError.canceled.rawValue:
                continuation?.resume(throwing: SignInWithAppleError.canceled)
            case ASAuthorizationError.failed.rawValue:
                continuation?.resume(throwing: SignInWithAppleError.failed)
            case ASAuthorizationError.invalidResponse.rawValue:
                continuation?.resume(throwing: SignInWithAppleError.invalidResponse)
            case ASAuthorizationError.notHandled.rawValue:
                continuation?.resume(throwing: SignInWithAppleError.notHandled)
            case ASAuthorizationError.notInteractive.rawValue:
                continuation?.resume(throwing: SignInWithAppleError.notInteractive)
            default:
                continuation?.resume(throwing: SignInWithAppleError.unknown(error))
            }
        } else {
            continuation?.resume(throwing: SignInWithAppleError.unknown(error))
        }

        continuation = nil
        Log("Error en Sign in with Apple: \(error.localizedDescription)", level: .error, category: .auth)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SignInWithAppleHelper: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Obtener la ventana principal de la app
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Sign In With Apple Errors

enum SignInWithAppleError: LocalizedError {
    case canceled
    case failed
    case invalidResponse
    case notHandled
    case notInteractive
    case invalidCredential
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Inicio de sesión cancelado"
        case .failed:
            return "Error al iniciar sesión con Apple"
        case .invalidResponse:
            return "Respuesta inválida de Apple"
        case .notHandled:
            return "La solicitud no fue manejada"
        case .notInteractive:
            return "Se requiere interacción del usuario"
        case .invalidCredential:
            return "Credenciales inválidas"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var isCanceled: Bool {
        if case .canceled = self {
            return true
        }
        return false
    }
}
