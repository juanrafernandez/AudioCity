//
//  AudioPreviewService.swift
//  AudioCityPOC
//
//  Servicio de audio independiente para previsualizar paradas
//  No afecta al audio de la ruta activa
//

import Foundation
import AVFoundation
import Combine

/// Servicio singleton para reproducir previews de audio
/// Completamente independiente del AudioService de la ruta activa
class AudioPreviewService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AudioPreviewService()

    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentStopId: String?

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var cachedVoice: AVSpeechSynthesisVoice?

    // MARK: - Initialization
    private override init() {
        super.init()
        synthesizer.delegate = self
        selectBestVoice(for: "es-ES")
    }

    // MARK: - Voice Selection

    private func selectBestVoice(for language: String) {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let languagePrefix = String(language.prefix(2))
        let voicesForLanguage = allVoices.filter { $0.language.hasPrefix(languagePrefix) }

        // Buscar Premium > Enhanced > Default
        if let premiumVoice = voicesForLanguage.first(where: { $0.quality == .premium }) {
            cachedVoice = premiumVoice
            return
        }

        if let enhancedVoice = voicesForLanguage.first(where: { $0.quality == .enhanced }) {
            cachedVoice = enhancedVoice
            return
        }

        if let exactMatch = voicesForLanguage.first(where: { $0.language == language }) {
            cachedVoice = exactMatch
            return
        }

        cachedVoice = voicesForLanguage.first ?? AVSpeechSynthesisVoice(language: language)
    }

    // MARK: - Public Methods

    /// Reproducir preview de una parada
    func playPreview(stopId: String, text: String) {
        // Detener cualquier preview anterior
        stop()

        guard !text.isEmpty else { return }

        currentStopId = stopId

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = cachedVoice
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false

        print("🎧 AudioPreviewService: Reproduciendo preview para stop \(stopId)")
    }

    /// Pausar preview
    func pause() {
        guard isPlaying, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        print("⏸️ AudioPreviewService: Pausado")
    }

    /// Reanudar preview
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        print("▶️ AudioPreviewService: Reanudado")
    }

    /// Detener preview
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentStopId = nil
        print("⏹️ AudioPreviewService: Detenido")
    }

    /// Verificar si un stop específico está reproduciéndose
    func isPlayingStop(_ stopId: String) -> Bool {
        return isPlaying && currentStopId == stopId
    }

    /// Verificar si un stop específico está pausado
    func isPausedStop(_ stopId: String) -> Bool {
        return isPaused && currentStopId == stopId
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioPreviewService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentStopId = nil
            print("✅ AudioPreviewService: Preview finalizado")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentStopId = nil
        }
    }
}
