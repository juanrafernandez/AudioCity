//
//  ImageCacheService.swift
//  AudioCityPOC
//
//  Servicio de caché de imágenes en memoria y disco
//

import SwiftUI
import UIKit

// MARK: - Image Cache Service

class ImageCacheService {
    static let shared = ImageCacheService()

    // Caché en memoria (rápido)
    private let memoryCache = NSCache<NSString, UIImage>()

    // Directorio de caché en disco
    private let diskCacheURL: URL

    private init() {
        // Configurar caché en memoria
        memoryCache.countLimit = 100 // Máximo 100 imágenes en memoria
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB máximo

        // Configurar directorio de caché en disco
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache", isDirectory: true)

        // Crear directorio si no existe
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        print("📦 ImageCacheService: Inicializado en \(diskCacheURL.path)")
    }

    // MARK: - Public Methods

    /// Obtiene una imagen de la caché (memoria o disco)
    func getImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)

        // Primero buscar en memoria
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }

        // Luego buscar en disco
        if let diskImage = loadFromDisk(key: key) {
            // Guardar en memoria para acceso más rápido
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }

        return nil
    }

    /// Guarda una imagen en la caché (memoria y disco)
    func saveImage(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)

        // Guardar en memoria
        memoryCache.setObject(image, forKey: key as NSString)

        // Guardar en disco (en background)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.saveToDisk(image: image, key: key)
        }
    }

    /// Descarga una imagen con caché
    func loadImage(from url: URL) async -> UIImage? {
        // Verificar caché primero
        if let cached = getImage(for: url) {
            return cached
        }

        // Descargar
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                saveImage(image, for: url)
                return image
            }
        } catch {
            print("❌ ImageCacheService: Error descargando imagen - \(error.localizedDescription)")
        }

        return nil
    }

    /// Limpia toda la caché
    func clearCache() {
        // Limpiar memoria
        memoryCache.removeAllObjects()

        // Limpiar disco
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        print("🗑️ ImageCacheService: Caché limpiada")
    }

    /// Tamaño de la caché en disco
    func diskCacheSize() -> Int64 {
        var size: Int64 = 0
        let fileManager = FileManager.default

        if let files = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }

        return size
    }

    /// Tamaño formateado de la caché
    func formattedCacheSize() -> String {
        let bytes = diskCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Private Methods

    private func cacheKey(for url: URL) -> String {
        // Usar hash MD5 de la URL como clave
        return url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? url.lastPathComponent
    }

    private func diskPath(for key: String) -> URL {
        // Sanitizar el key para usarlo como nombre de archivo
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .prefix(100)
        return diskCacheURL.appendingPathComponent(String(safeKey) + ".jpg")
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let path = diskPath(for: key)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        return UIImage(contentsOfFile: path.path)
    }

    private func saveToDisk(image: UIImage, key: String) {
        let path = diskPath(for: key)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: path)
        }
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // Verificar caché primero (síncrono)
        if let cached = ImageCacheService.shared.getImage(for: url) {
            self.image = cached
            return
        }

        // Descargar en background
        isLoading = true
        Task {
            if let downloadedImage = await ImageCacheService.shared.loadImage(from: url) {
                await MainActor.run {
                    self.image = downloadedImage
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Convenience initializer for simple placeholder

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(url: url) {
            ProgressView()
        }
    }
}
