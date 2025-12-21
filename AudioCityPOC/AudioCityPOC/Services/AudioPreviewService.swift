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

/// Servicio para reproducir previews de audio
/// Completamente independiente del AudioService de la ruta activa
class AudioPreviewService: NSObject, ObservableObject, AudioPreviewServiceProtocol {

    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentStopId: String?

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var cachedVoice: AVSpeechSynthesisVoice?

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        selectBestVoice(for: "es-ES")
    }

    deinit {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = nil
        Log("AudioPreviewService deinit", level: .debug, category: .audio)
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

        Log("Reproduciendo preview para stop \(stopId)", level: .debug, category: .audio)
    }

    /// Pausar preview
    func pause() {
        guard isPlaying, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        Log("Preview pausado", level: .debug, category: .audio)
    }

    /// Reanudar preview
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        Log("Preview reanudado", level: .debug, category: .audio)
    }

    /// Detener preview
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentStopId = nil
        Log("Preview detenido", level: .debug, category: .audio)
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
            Log("Preview finalizado", level: .debug, category: .audio)
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
