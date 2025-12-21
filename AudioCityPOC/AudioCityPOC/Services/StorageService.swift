//
//  StorageService.swift
//  AudioCityPOC
//
//  Servicio para subir/descargar imágenes de Firebase Storage
//
//  NOTA: FirebaseStorage debe añadirse como dependencia en el proyecto.
//  En Xcode: File > Add Package Dependencies > firebase-ios-sdk
//  Luego en Build Phases > Link Binary With Libraries, añadir FirebaseStorage
//

import Foundation
import FirebaseAuth
import UIKit
import Combine

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

/// Servicio para gestionar imágenes en Firebase Storage
class StorageService: ObservableObject {

    #if canImport(FirebaseStorage)
    private let storage = Storage.storage()
    #endif

    // MARK: - Route Images

    /// Subir imagen de ruta a Storage
    /// - Parameters:
    ///   - data: Datos de la imagen (JPEG)
    ///   - routeId: ID de la ruta
    /// - Returns: URL de descarga de la imagen
    func uploadRouteImage(_ data: Data, routeId: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/routes/\(routeId)/thumbnail.jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Comprimir imagen si es muy grande
        let compressedData = compressImageIfNeeded(data)

        _ = try await ref.putDataAsync(compressedData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        Log("Imagen de ruta subida: \(routeId)", level: .success, category: .firebase)
        return downloadURL
        #else
        throw FirebaseStorageError.storageNotAvailable
        #endif
    }

    /// Descargar imagen de ruta
    /// - Parameter routeId: ID de la ruta
    /// - Returns: Datos de la imagen
    func downloadRouteImage(routeId: String) async throws -> Data? {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/routes/\(routeId)/thumbnail.jpg"
        let ref = storage.reference().child(path)

        do {
            let maxSize: Int64 = 5 * 1024 * 1024 // 5MB max
            let data = try await ref.data(maxSize: maxSize)
            Log("Imagen de ruta descargada: \(routeId)", level: .success, category: .firebase)
            return data
        } catch {
            Log("Error descargando imagen de ruta: \(error.localizedDescription)", level: .error, category: .firebase)
            return nil
        }
        #else
        return nil
        #endif
    }

    /// Eliminar imagen de ruta
    /// - Parameter routeId: ID de la ruta
    func deleteRouteImage(routeId: String) async throws {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/routes/\(routeId)/thumbnail.jpg"
        let ref = storage.reference().child(path)

        do {
            try await ref.delete()
            Log("Imagen de ruta eliminada: \(routeId)", level: .success, category: .firebase)
        } catch {
            // Si el archivo no existe, no es un error crítico
            Log("No se pudo eliminar imagen (puede no existir): \(error.localizedDescription)", level: .warning, category: .firebase)
        }
        #endif
    }

    // MARK: - Profile Images

    /// Subir foto de perfil
    /// - Parameter data: Datos de la imagen
    /// - Returns: URL de descarga
    func uploadProfileImage(_ data: Data) async throws -> URL {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/profile/avatar.jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Comprimir y redimensionar para foto de perfil
        let compressedData = compressProfileImage(data)

        _ = try await ref.putDataAsync(compressedData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        Log("Foto de perfil subida", level: .success, category: .firebase)
        return downloadURL
        #else
        throw FirebaseStorageError.storageNotAvailable
        #endif
    }

    /// Descargar foto de perfil
    func downloadProfileImage() async throws -> Data? {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/profile/avatar.jpg"
        let ref = storage.reference().child(path)

        do {
            let maxSize: Int64 = 2 * 1024 * 1024 // 2MB max
            return try await ref.data(maxSize: maxSize)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    /// Eliminar foto de perfil
    func deleteProfileImage() async throws {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let path = "users/\(uid)/profile/avatar.jpg"
        let ref = storage.reference().child(path)

        try await ref.delete()
        Log("Foto de perfil eliminada", level: .success, category: .firebase)
        #endif
    }

    // MARK: - Batch Operations

    /// Eliminar todas las imágenes de un usuario
    func deleteAllUserImages() async throws {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseStorageError.notAuthenticated
        }

        let userPath = "users/\(uid)"
        let ref = storage.reference().child(userPath)

        // Listar y eliminar todos los archivos
        do {
            let result = try await ref.listAll()

            for item in result.items {
                try await item.delete()
            }

            // Eliminar recursivamente en subdirectorios
            for prefix in result.prefixes {
                try await deleteFolder(prefix)
            }

            Log("Todas las imágenes del usuario eliminadas", level: .success, category: .firebase)
        } catch {
            Log("Error eliminando imágenes del usuario: \(error.localizedDescription)", level: .error, category: .firebase)
            throw error
        }
        #endif
    }

    #if canImport(FirebaseStorage)
    private func deleteFolder(_ ref: StorageReference) async throws {
        let result = try await ref.listAll()

        for item in result.items {
            try await item.delete()
        }

        for prefix in result.prefixes {
            try await deleteFolder(prefix)
        }
    }
    #endif

    // MARK: - Image Compression

    /// Comprimir imagen si excede el tamaño máximo
    private func compressImageIfNeeded(_ data: Data, maxSizeKB: Int = 500) -> Data {
        guard let image = UIImage(data: data) else { return data }

        let maxSize = maxSizeKB * 1024
        var compression: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compression) ?? data

        while compressedData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression) ?? data
        }

        return compressedData
    }

    /// Comprimir y redimensionar foto de perfil
    private func compressProfileImage(_ data: Data, maxSize: CGFloat = 400) -> Data {
        guard let image = UIImage(data: data) else { return data }

        // Redimensionar si es muy grande
        let size = image.size
        var newImage = image

        if size.width > maxSize || size.height > maxSize {
            let scale = min(maxSize / size.width, maxSize / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }

        return newImage.jpegData(compressionQuality: 0.7) ?? data
    }
}

// MARK: - Firebase Storage Errors

enum FirebaseStorageError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case downloadFailed
    case deleteFailed
    case storageNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuario no autenticado"
        case .uploadFailed:
            return "Error al subir el archivo"
        case .downloadFailed:
            return "Error al descargar el archivo"
        case .deleteFailed:
            return "Error al eliminar el archivo"
        case .storageNotAvailable:
            return "Firebase Storage no está configurado. Añade FirebaseStorage al proyecto."
        }
    }
}
