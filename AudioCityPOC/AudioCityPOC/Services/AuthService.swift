//
//  AuthService.swift
//  AudioCityPOC
//
//  Servicio de autenticación con Firebase
//  Usa solo integraciones nativas: Apple Sign In, Google Sign In y Email/Password
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Combine
import UIKit

/// Estado de autenticación
enum AuthState {
    case loading
    case authenticated
    case unauthenticated
}

/// Servicio de autenticación
@MainActor
class AuthService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var currentUser: ACUser?
    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var isNewUser: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Private Properties

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    do {
                        // Cargar perfil del usuario
                        self?.currentUser = try await self?.fetchUserProfile(uid: user.uid)
                        self?.authState = .authenticated
                        Log("Usuario autenticado: \(user.email ?? user.uid)", level: .success, category: .auth)
                    } catch {
                        // Si no existe el perfil, es un usuario nuevo
                        Log("Perfil no encontrado, puede ser usuario nuevo", level: .warning, category: .auth)
                        self?.authState = .authenticated
                    }
                } else {
                    self?.currentUser = nil
                    self?.authState = .unauthenticated
                    Log("Usuario no autenticado", level: .info, category: .auth)
                }
            }
        }
    }

    // MARK: - Apple Sign In

    /// Iniciar sesión con Apple
    func signInWithApple() async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let helper = SignInWithAppleHelper()
        let tokens = try await helper.startSignInWithAppleFlow()

        let credential = OAuthProvider.appleCredential(
            withIDToken: tokens.token,
            rawNonce: tokens.nonce,
            fullName: tokens.fullName
        )

        let result = try await Auth.auth().signIn(with: credential)

        // Construir nombre completo si está disponible
        var displayName: String?
        if let fullName = tokens.fullName {
            let formatter = PersonNameComponentsFormatter()
            displayName = formatter.string(from: fullName)
        }

        try await createOrUpdateUserProfile(
            from: result.user,
            provider: .apple,
            displayName: displayName,
            email: tokens.email ?? result.user.email
        )

        Log("Sign in with Apple exitoso", level: .success, category: .auth)
    }

    // MARK: - Google Sign In

    /// Iniciar sesión con Google (nativo usando ASWebAuthenticationSession)
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let helper = SignInWithGoogleHelper()
        let googleResult = try await helper.startSignInWithGoogleFlow()

        // Crear credencial de Google para Firebase
        let credential = GoogleAuthProvider.credential(
            withIDToken: googleResult.idToken,
            accessToken: googleResult.accessToken
        )

        let result = try await Auth.auth().signIn(with: credential)

        try await createOrUpdateUserProfile(
            from: result.user,
            provider: .google,
            displayName: googleResult.name ?? result.user.displayName,
            email: googleResult.email ?? result.user.email
        )

        Log("Sign in with Google exitoso", level: .success, category: .auth)
    }

    // MARK: - Email/Password Auth

    /// Registrar con email y contraseña
    func signUpWithEmail(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Validar contraseña
        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Actualizar displayName en Firebase Auth
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()

        // Enviar email de verificación
        try await result.user.sendEmailVerification()

        // Crear perfil en Firestore
        try await createOrUpdateUserProfile(
            from: result.user,
            provider: .email,
            displayName: name,
            email: email
        )

        Log("Registro con email exitoso: \(email)", level: .success, category: .auth)
    }

    /// Iniciar sesión con email y contraseña
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let result = try await Auth.auth().signIn(withEmail: email, password: password)

        // Actualizar último login
        try await updateLastLogin(uid: result.user.uid)

        Log("Sign in con email exitoso: \(email)", level: .success, category: .auth)
    }

    /// Enviar email para restablecer contraseña
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        try await Auth.auth().sendPasswordReset(withEmail: email)

        Log("Email de recuperación enviado a: \(email)", level: .success, category: .auth)
    }

    // MARK: - Sign Out

    /// Cerrar sesión
    func signOut() throws {
        // Cerrar sesión de Firebase
        try Auth.auth().signOut()

        currentUser = nil
        authState = .unauthenticated

        Log("Sesión cerrada", level: .success, category: .auth)
    }

    // MARK: - Account Management

    /// Eliminar cuenta
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let uid = user.uid

        // 1. Eliminar imágenes en Storage
        let storageService = StorageService()
        try? await storageService.deleteAllUserImages()

        // 2. Eliminar datos en Firestore
        try await deleteUserData(uid: uid)

        // 3. Eliminar cuenta de Firebase Auth
        try await user.delete()

        currentUser = nil
        authState = .unauthenticated

        Log("Cuenta eliminada", level: .success, category: .auth)
    }

    // MARK: - User Profile

    /// Obtener perfil del usuario
    func fetchUserProfile(uid: String) async throws -> ACUser {
        let docRef = db.collection("users").document(uid)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists, let data = snapshot.data(),
              let user = ACUser.fromFirestore(data, id: uid) else {
            throw AuthError.profileNotFound
        }

        return user
    }

    /// Actualizar perfil del usuario
    func updateUserProfile(_ user: ACUser) async throws {
        let docRef = db.collection("users").document(user.id)
        try await docRef.setData(user.toFirestore(), merge: true)
        self.currentUser = user
        Log("Perfil actualizado", level: .success, category: .auth)
    }

    // MARK: - Data Migration

    /// Migrar datos locales a Firebase (al primer login)
    func migrateLocalDataToFirebase() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        // Verificar si ya tiene datos en Firebase (no es primera vez)
        let profileRef = db.collection("users").document(uid)
        let profileDoc = try await profileRef.getDocument()

        // Si ya existe perfil con datos migrados, no migrar de nuevo
        if profileDoc.exists,
           let data = profileDoc.data(),
           data["migrationCompleted"] as? Bool == true {
            Log("Datos ya migrados previamente", level: .info, category: .firebase)
            return
        }

        Log("Iniciando migración de datos locales...", level: .info, category: .firebase)

        let batch = db.batch()
        let storageService = StorageService()

        // 1. Migrar Trips
        try await migrateTrips(uid: uid, batch: batch)

        // 2. Migrar UserRoutes (con imágenes)
        try await migrateUserRoutes(uid: uid, batch: batch, storageService: storageService)

        // 3. Migrar History
        try await migrateHistory(uid: uid, batch: batch)

        // 4. Migrar Points y Transactions
        try await migratePoints(uid: uid, batch: batch)

        // 5. Migrar Favorites
        try await migrateFavorites(uid: uid, batch: batch)

        // Marcar migración completada
        batch.updateData(["migrationCompleted": true], forDocument: profileRef)

        // Ejecutar batch
        try await batch.commit()

        // Limpiar datos locales
        clearLocalUserData()

        Log("Migración completada exitosamente", level: .success, category: .firebase)
    }

    // MARK: - Private Methods

    private func createOrUpdateUserProfile(from firebaseUser: User, provider: AuthProvider, displayName: String?, email: String?) async throws {
        let uid = firebaseUser.uid
        let docRef = db.collection("users").document(uid)

        let snapshot = try await docRef.getDocument()

        if snapshot.exists {
            // Usuario existente - actualizar último login
            self.isNewUser = false
            try await docRef.updateData([
                "lastLoginAt": Date(),
                "email": email ?? firebaseUser.email as Any,
                "displayName": displayName ?? firebaseUser.displayName as Any,
                "photoURL": firebaseUser.photoURL?.absoluteString as Any
            ])

            // Cargar perfil actualizado
            self.currentUser = try await fetchUserProfile(uid: uid)
        } else {
            // Usuario nuevo - crear perfil
            self.isNewUser = true
            let newUser = ACUser(
                id: uid,
                email: email ?? firebaseUser.email,
                displayName: displayName ?? firebaseUser.displayName,
                photoURL: firebaseUser.photoURL?.absoluteString,
                authProvider: provider,
                createdAt: Date(),
                lastLoginAt: Date(),
                stats: nil,
                favoriteRouteIds: []
            )

            try await docRef.setData(newUser.toFirestore())
            self.currentUser = newUser

            // Migrar datos locales para usuarios nuevos
            try await migrateLocalDataToFirebase()
        }
    }

    /// Marcar que el usuario ya vio la pantalla de bienvenida
    func markOnboardingComplete() {
        isNewUser = false
    }

    private func updateLastLogin(uid: String) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData(["lastLoginAt": Date()])
    }

    private func deleteUserData(uid: String) async throws {
        let userRef = db.collection("users").document(uid)

        // Eliminar subcolecciones
        let subcollections = ["trips", "userRoutes", "history", "pointsTransactions"]

        for subcollection in subcollections {
            let collectionRef = userRef.collection(subcollection)
            let documents = try await collectionRef.getDocuments()

            for doc in documents.documents {
                try await doc.reference.delete()
            }
        }

        // Eliminar documento principal
        try await userRef.delete()
    }

    // MARK: - Migration Helpers

    private func migrateTrips(uid: String, batch: WriteBatch) async throws {
        guard let data = UserDefaults.standard.data(forKey: "audiocity_trips") else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let trips = try? decoder.decode([Trip].self, from: data) else { return }

        for trip in trips {
            let ref = db.collection("users").document(uid).collection("trips").document(trip.id)
            batch.setData(try Firestore.Encoder().encode(trip), forDocument: ref)
        }

        Log("Migrados \(trips.count) viajes", level: .info, category: .firebase)
    }

    private func migrateUserRoutes(uid: String, batch: WriteBatch, storageService: StorageService) async throws {
        guard let data = UserDefaults.standard.data(forKey: "userCreatedRoutes") else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let routes = try? decoder.decode([UserRoute].self, from: data) else { return }

        for route in routes {
            var routeData = try Firestore.Encoder().encode(route)

            // Subir imagen si existe
            if let imageData = route.thumbnailData {
                do {
                    let imageURL = try await storageService.uploadRouteImage(imageData, routeId: route.id)
                    routeData["thumbnailURL"] = imageURL.absoluteString
                    routeData["thumbnailData"] = nil // No guardar binario en Firestore
                } catch {
                    Log("Error subiendo imagen de ruta \(route.id): \(error)", level: .warning, category: .firebase)
                }
            }

            let ref = db.collection("users").document(uid).collection("userRoutes").document(route.id)
            batch.setData(routeData, forDocument: ref)
        }

        Log("Migradas \(routes.count) rutas de usuario", level: .info, category: .firebase)
    }

    private func migrateHistory(uid: String, batch: WriteBatch) async throws {
        guard let data = UserDefaults.standard.data(forKey: "audiocity_history") else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let history = try? decoder.decode([RouteHistory].self, from: data) else { return }

        for record in history {
            let ref = db.collection("users").document(uid).collection("history").document(record.id)
            batch.setData(try Firestore.Encoder().encode(record), forDocument: ref)
        }

        Log("Migrados \(history.count) registros de historial", level: .info, category: .firebase)
    }

    private func migratePoints(uid: String, batch: WriteBatch) async throws {
        let userRef = db.collection("users").document(uid)

        // Migrar stats
        if let statsData = UserDefaults.standard.data(forKey: "audiocity_points"),
           let stats = try? JSONDecoder().decode(UserPointsStats.self, from: statsData) {
            batch.updateData([
                "stats": [
                    "totalPoints": stats.totalPoints,
                    "currentLevel": stats.currentLevel.rawValue,
                    "routesCreated": stats.routesCreated,
                    "routesCompleted": stats.routesCompleted,
                    "currentStreak": stats.currentStreak,
                    "longestStreak": stats.longestStreak
                ]
            ], forDocument: userRef)
        }

        // Migrar transacciones
        if let transData = UserDefaults.standard.data(forKey: "audiocity_points_transactions") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let transactions = try? decoder.decode([PointsTransaction].self, from: transData) {
                for transaction in transactions {
                    let ref = userRef.collection("pointsTransactions").document(transaction.id)
                    batch.setData(try Firestore.Encoder().encode(transaction), forDocument: ref)
                }
                Log("Migradas \(transactions.count) transacciones de puntos", level: .info, category: .firebase)
            }
        }
    }

    private func migrateFavorites(uid: String, batch: WriteBatch) async throws {
        guard let data = UserDefaults.standard.data(forKey: "audiocity_favorites"),
              let favoriteIds = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }

        let userRef = db.collection("users").document(uid)
        batch.updateData(["favoriteRouteIds": Array(favoriteIds)], forDocument: userRef)

        Log("Migrados \(favoriteIds.count) favoritos", level: .info, category: .firebase)
    }

    private func clearLocalUserData() {
        let keysToRemove = [
            "audiocity_trips",
            "userCreatedRoutes",
            "audiocity_history",
            "audiocity_points",
            "audiocity_points_transactions",
            "audiocity_favorites"
        ]

        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        Log("Datos locales limpiados", level: .info, category: .firebase)
    }

    // MARK: - Validation

    private func isValidPassword(_ password: String) -> Bool {
        // Mínimo 8 caracteres, al menos una mayúscula y un número
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9]).{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case noRootViewController
    case missingToken
    case weakPassword
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No hay sesión activa"
        case .profileNotFound:
            return "Perfil de usuario no encontrado"
        case .noRootViewController:
            return "No se pudo obtener la ventana principal"
        case .missingToken:
            return "Token de autenticación no válido"
        case .weakPassword:
            return "La contraseña debe tener mínimo 8 caracteres, una mayúscula y un número"
        case .networkError:
            return "Error de conexión"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

