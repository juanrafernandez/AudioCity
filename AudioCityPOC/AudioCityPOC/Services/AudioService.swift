//
//  AudioService.swift
//  AudioCityPOC
//
//  Servicio de Text-to-Speech usando AVSpeechSynthesizer
//  Incluye cola de reproducción para puntos cercanos
//

import Foundation
import AVFoundation
import Combine

/// Representa un item en la cola de reproducción
struct AudioQueueItem: Identifiable, Equatable {
    let id: String
    let stopId: String
    let stopName: String
    let text: String
    let order: Int

    static func == (lhs: AudioQueueItem, rhs: AudioQueueItem) -> Bool {
        lhs.id == rhs.id
    }
}

class AudioService: NSObject, ObservableObject, AudioServiceProtocol {

    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentText: String?
    @Published var currentQueueItem: AudioQueueItem?
    @Published var queuedItems: [AudioQueueItem] = []
    @Published var currentVoiceQuality: String = "default"

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioQueue: [AudioQueueItem] = []
    private var processedStopIds: Set<String> = []  // Evitar duplicados
    private var cachedVoice: AVSpeechSynthesisVoice?

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
        selectBestVoice(for: "es-ES")
    }

    deinit {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = nil
        Log("AudioService deinit", level: .debug, category: .audio)
    }

    // MARK: - Setup

    /// Configurar sesión de audio para background
    private func setupAudioSession() {
        do {
            // CRÍTICO: Configuración para funcionar en background
            try audioSession.setCategory(.playback,
                                        mode: .spokenAudio,
                                        options: [.duckOthers])
            try audioSession.setActive(true)
            Log("Audio session configurada", level: .info, category: .audio)
        } catch {
            Log("Error configurando audio session - \(error.localizedDescription)", level: .error, category: .audio)
        }
    }

    // MARK: - Voice Selection

    /// Selecciona la mejor voz disponible para el idioma especificado
    /// Prioriza: Premium > Enhanced > Default
    private func selectBestVoice(for language: String) {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // Filtrar voces para el idioma (ej: "es-ES", "es-MX", etc.)
        let languagePrefix = String(language.prefix(2)) // "es"
        let voicesForLanguage = allVoices.filter { $0.language.hasPrefix(languagePrefix) }

        // Log todas las voces disponibles para el idioma
        Log("Voces disponibles para '\(language)': \(voicesForLanguage.count)", level: .debug, category: .audio)
        for voice in voicesForLanguage {
            let qualityName = voiceQualityName(voice.quality)
            Log("   - \(voice.name) (\(voice.language)) - Quality: \(qualityName)", level: .debug, category: .audio)
        }

        // Buscar la mejor voz en orden de prioridad
        // 1. Premium (quality == .premium) - Solo iOS 16+
        if let premiumVoice = voicesForLanguage.first(where: { $0.quality == .premium }) {
            cachedVoice = premiumVoice
            currentVoiceQuality = "Premium"
            Log("Usando voz PREMIUM: \(premiumVoice.name)", level: .success, category: .audio)
            return
        }

        // 2. Enhanced (quality == .enhanced)
        if let enhancedVoice = voicesForLanguage.first(where: { $0.quality == .enhanced }) {
            cachedVoice = enhancedVoice
            currentVoiceQuality = "Enhanced"
            Log("Usando voz ENHANCED: \(enhancedVoice.name)", level: .success, category: .audio)
            return
        }

        // 3. Preferir voces del idioma exacto (es-ES sobre es-MX)
        if let exactMatch = voicesForLanguage.first(where: { $0.language == language }) {
            cachedVoice = exactMatch
            currentVoiceQuality = "Default"
            Log("Usando voz DEFAULT (coincidencia exacta): \(exactMatch.name)", level: .info, category: .audio)
            return
        }

        // 4. Cualquier voz del idioma
        if let anyVoice = voicesForLanguage.first {
            cachedVoice = anyVoice
            currentVoiceQuality = "Default"
            Log("Usando voz DEFAULT: \(anyVoice.name)", level: .info, category: .audio)
            return
        }

        // 5. Fallback al sistema
        cachedVoice = AVSpeechSynthesisVoice(language: language)
        currentVoiceQuality = "System"
        Log("Usando voz del SISTEMA para '\(language)'", level: .warning, category: .audio)
    }

    private func voiceQualityName(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .default:
            return "Default"
        case .enhanced:
            return "Enhanced"
        case .premium:
            return "Premium"
        @unknown default:
            return "Unknown"
        }
    }

    /// Obtiene la mejor voz para un idioma (con caché)
    private func getBestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        // Si el idioma cambia, recalcular
        if let cached = cachedVoice, cached.language.hasPrefix(String(language.prefix(2))) {
            return cached
        }
        selectBestVoice(for: language)
        return cachedVoice
    }

    /// Lista las voces premium/enhanced disponibles (útil para debug o UI)
    func getAvailableHighQualityVoices() -> [(name: String, language: String, quality: String)] {
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.quality == .premium || $0.quality == .enhanced }
            .map { (name: $0.name, language: $0.language, quality: voiceQualityName($0.quality)) }
    }
    
    // MARK: - Public Methods

    /// Reproducir texto con TTS (método original para compatibilidad)
    func speak(text: String, language: String = "es-ES") {
        // Si ya está hablando, detener primero
        if isPlaying {
            stop()
        }

        currentText = text

        // Crear utterance con la mejor voz disponible
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = getBestVoice(for: language)
        utterance.rate = 0.52 // Velocidad ligeramente más natural
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1 // Pequeña pausa antes de empezar
        utterance.postUtteranceDelay = 0.2 // Pequeña pausa después

        // Reproducir
        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false

        Log("Reproduciendo (\(currentVoiceQuality)) - '\(text.prefix(50))...'", level: .info, category: .audio)
    }

    // MARK: - Queue Methods

    /// Encolar una parada para reproducción
    func enqueueStop(stopId: String, stopName: String, text: String, order: Int) {
        // Evitar duplicados
        guard !processedStopIds.contains(stopId) else {
            Log("Parada \(stopName) ya está en cola o procesada", level: .debug, category: .audio)
            return
        }

        let item = AudioQueueItem(
            id: UUID().uuidString,
            stopId: stopId,
            stopName: stopName,
            text: text,
            order: order
        )

        // Insertar en orden
        let insertIndex = audioQueue.firstIndex { $0.order > order } ?? audioQueue.count
        audioQueue.insert(item, at: insertIndex)
        processedStopIds.insert(stopId)

        // Actualizar la lista publicada
        updateQueuedItems()

        Log("Encolada parada '\(stopName)' (orden: \(order), cola: \(audioQueue.count))", level: .info, category: .audio)

        // Si no está reproduciendo, iniciar
        if !isPlaying && !isPaused {
            playNextInQueue()
        }
    }

    /// Reproducir el siguiente item en la cola
    private func playNextInQueue(language: String = "es-ES") {
        guard !audioQueue.isEmpty else {
            Log("Cola vacía", level: .debug, category: .audio)
            currentQueueItem = nil
            return
        }

        let item = audioQueue.removeFirst()
        currentQueueItem = item
        currentText = item.text
        updateQueuedItems()

        // Crear utterance con la mejor voz disponible
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = getBestVoice(for: language)
        utterance.rate = 0.52 // Velocidad ligeramente más natural
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.3 // Pausa entre paradas

        // Reproducir
        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false

        Log("Reproduciendo parada '\(item.stopName)' (\(currentVoiceQuality))", level: .info, category: .audio)
    }

    /// Actualizar la lista de items en cola (para UI)
    private func updateQueuedItems() {
        DispatchQueue.main.async {
            self.queuedItems = self.audioQueue
        }
    }

    /// Obtener número de items en cola
    func getQueueCount() -> Int {
        return audioQueue.count
    }

    /// Limpiar la cola y resetear estado
    func clearQueue() {
        audioQueue.removeAll()
        processedStopIds.removeAll()
        currentQueueItem = nil
        updateQueuedItems()
        Log("Cola limpiada", level: .info, category: .audio)
    }

    /// Saltar al siguiente item en la cola
    func skipToNext() {
        if isPlaying || isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        playNextInQueue()
    }

    /// Pausar reproducción
    func pause() {
        guard isPlaying, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        Log("Pausado", level: .debug, category: .audio)
    }

    /// Reanudar reproducción
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        Log("Reanudado", level: .debug, category: .audio)
    }

    /// Detener reproducción (mantiene la cola)
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentText = nil
        currentQueueItem = nil
        Log("Detenido", level: .debug, category: .audio)
    }

    /// Detener y limpiar todo
    func stopAndClear() {
        stop()
        clearQueue()
        Log("Detenido y cola limpiada", level: .info, category: .audio)
    }

    /// Saltar adelante 15 segundos (no aplicable en TTS, pero útil para UI)
    func skipForward() {
        Log("Skip forward (no aplicable en TTS)", level: .debug, category: .audio)
    }

    /// Saltar atrás 15 segundos
    func skipBackward() {
        // Reiniciar el audio actual
        if let text = currentText {
            speak(text: text)
        }
        Log("Reiniciando audio", level: .debug, category: .audio)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
        }
        Log("Reproducción iniciada", level: .debug, category: .audio)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentText = nil

            // Reproducir siguiente en cola si hay más
            if !self.audioQueue.isEmpty {
                Log("Reproducción finalizada, continuando con siguiente en cola...", level: .debug, category: .audio)
                self.playNextInQueue()
            } else {
                self.currentQueueItem = nil
                Log("Reproducción finalizada, cola vacía", level: .success, category: .audio)
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didPause utterance: AVSpeechUtterance) {
        Log("Pausado por sistema", level: .debug, category: .audio)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didContinue utterance: AVSpeechUtterance) {
        Log("Reanudado por sistema", level: .debug, category: .audio)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
        }
        Log("Cancelado", level: .warning, category: .audio)
    }
}