//
//  SignInWithGoogleHelper.swift
//  AudioCityPOC
//
//  Helper nativo para Google Sign In usando ASWebAuthenticationSession
//  No requiere SDK de terceros - usa OAuth 2.0 estándar
//

import Foundation
import AuthenticationServices
import CryptoKit

struct GoogleSignInResult {
    let idToken: String
    let accessToken: String
    let email: String?
    let name: String?
}

enum SignInWithGoogleError: LocalizedError {
    case missingClientID
    case missingURLScheme
    case authenticationFailed
    case tokenExchangeFailed
    case userCanceled
    case invalidResponse
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Google Sign-In no configurado. Habilita Google en Firebase Console y descarga un nuevo GoogleService-Info.plist con CLIENT_ID."
        case .missingURLScheme:
            return "Falta REVERSED_CLIENT_ID en GoogleService-Info.plist. Descarga un nuevo archivo desde Firebase Console con Google habilitado."
        case .authenticationFailed:
            return "Error en la autenticación con Google"
        case .tokenExchangeFailed:
            return "Error al obtener tokens de Google"
        case .userCanceled:
            return "Inicio de sesión cancelado"
        case .invalidResponse:
            return "Respuesta inválida de Google"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var isCanceled: Bool {
        if case .userCanceled = self { return true }
        return false
    }
}

@MainActor
class SignInWithGoogleHelper: NSObject {

    private var webAuthSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<GoogleSignInResult, Error>?

    // MARK: - Configuration

    /// Obtiene el Client ID desde GoogleService-Info.plist
    private func getClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["CLIENT_ID"] as? String else {
            return nil
        }
        return clientID
    }

    /// Obtiene el URL Scheme reverso desde GoogleService-Info.plist
    private func getReversedClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let reversedClientID = plist["REVERSED_CLIENT_ID"] as? String else {
            return nil
        }
        return reversedClientID
    }

    // MARK: - Sign In Flow

    func startSignInWithGoogleFlow() async throws -> GoogleSignInResult {
        guard let clientID = getClientID() else {
            throw SignInWithGoogleError.missingClientID
        }

        guard let reversedClientID = getReversedClientID() else {
            throw SignInWithGoogleError.missingURLScheme
        }

        // Generar state y nonce para seguridad
        let state = randomNonceString()
        let nonce = randomNonceString()

        // Construir URL de autorización de Google
        let redirectURI = "\(reversedClientID):/oauth2callback"
        let scope = "openid email profile"

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "select_account")
        ]

        guard let authURL = components.url else {
            throw SignInWithGoogleError.authenticationFailed
        }

        // Iniciar sesión de autenticación web
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: reversedClientID
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    await self?.handleCallback(
                        callbackURL: callbackURL,
                        error: error,
                        expectedState: state,
                        clientID: clientID,
                        redirectURI: redirectURI
                    )
                }
            }

            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            webAuthSession?.start()
        }
    }

    // MARK: - Callback Handler

    private func handleCallback(
        callbackURL: URL?,
        error: Error?,
        expectedState: String,
        clientID: String,
        redirectURI: String
    ) async {
        defer { webAuthSession = nil }

        if let error = error as? ASWebAuthenticationSessionError {
            if error.code == .canceledLogin {
                continuation?.resume(throwing: SignInWithGoogleError.userCanceled)
            } else {
                continuation?.resume(throwing: SignInWithGoogleError.unknown(error))
            }
            continuation = nil
            return
        }

        guard let callbackURL = callbackURL else {
            continuation?.resume(throwing: SignInWithGoogleError.authenticationFailed)
            continuation = nil
            return
        }

        // Extraer código de autorización de la URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            continuation?.resume(throwing: SignInWithGoogleError.invalidResponse)
            continuation = nil
            return
        }

        // Verificar state
        guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
              returnedState == expectedState else {
            continuation?.resume(throwing: SignInWithGoogleError.authenticationFailed)
            continuation = nil
            return
        }

        // Obtener código de autorización
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            if let error = queryItems.first(where: { $0.name == "error" })?.value {
                if error == "access_denied" {
                    continuation?.resume(throwing: SignInWithGoogleError.userCanceled)
                } else {
                    continuation?.resume(throwing: SignInWithGoogleError.authenticationFailed)
                }
            } else {
                continuation?.resume(throwing: SignInWithGoogleError.invalidResponse)
            }
            continuation = nil
            return
        }

        // Intercambiar código por tokens
        do {
            let result = try await exchangeCodeForTokens(
                code: code,
                clientID: clientID,
                redirectURI: redirectURI
            )
            continuation?.resume(returning: result)
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(
        code: String,
        clientID: String,
        redirectURI: String
    ) async throws -> GoogleSignInResult {
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SignInWithGoogleError.tokenExchangeFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idToken = json["id_token"] as? String,
              let accessToken = json["access_token"] as? String else {
            throw SignInWithGoogleError.invalidResponse
        }

        // Decodificar el ID token para obtener información del usuario
        let userInfo = decodeJWT(idToken)

        return GoogleSignInResult(
            idToken: idToken,
            accessToken: accessToken,
            email: userInfo["email"] as? String,
            name: userInfo["name"] as? String
        )
    }

    // MARK: - JWT Decoding

    private func decodeJWT(_ jwt: String) -> [String: Any] {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else { return [:] }

        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Añadir padding si es necesario
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return json
    }

    // MARK: - Helpers

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
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension SignInWithGoogleHelper: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
