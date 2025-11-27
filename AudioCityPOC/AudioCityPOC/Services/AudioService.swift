//
//  AudioService.swift
//  AudioCityPOC
//
//  Created by JuanRa Fernandez on 23/11/25.
//


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

class AudioService: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentText: String?
    @Published var currentQueueItem: AudioQueueItem?
    @Published var queuedItems: [AudioQueueItem] = []

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioQueue: [AudioQueueItem] = []
    private var processedStopIds: Set<String> = []  // Evitar duplicados
    
    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
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
            print("🔊 AudioService: Audio session configurada")
        } catch {
            print("❌ AudioService: Error configurando audio session - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods

    /// Reproducir texto con TTS (método original para compatibilidad)
    func speak(text: String, language: String = "es-ES") {
        // Si ya está hablando, detener primero
        if isPlaying {
            stop()
        }

        currentText = text

        // Crear utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.50 // Velocidad natural (0.0 - 1.0)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Reproducir
        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false

        print("🔊 AudioService: Reproduciendo - '\(text.prefix(50))...'")
    }

    // MARK: - Queue Methods

    /// Encolar una parada para reproducción
    func enqueueStop(stopId: String, stopName: String, text: String, order: Int) {
        // Evitar duplicados
        guard !processedStopIds.contains(stopId) else {
            print("🔊 AudioService: Parada \(stopName) ya está en cola o procesada")
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

        print("🔊 AudioService: Encolada parada '\(stopName)' (orden: \(order), cola: \(audioQueue.count))")

        // Si no está reproduciendo, iniciar
        if !isPlaying && !isPaused {
            playNextInQueue()
        }
    }

    /// Reproducir el siguiente item en la cola
    private func playNextInQueue(language: String = "es-ES") {
        guard !audioQueue.isEmpty else {
            print("🔊 AudioService: Cola vacía")
            currentQueueItem = nil
            return
        }

        let item = audioQueue.removeFirst()
        currentQueueItem = item
        currentText = item.text
        updateQueuedItems()

        // Crear utterance
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Reproducir
        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false

        print("🔊 AudioService: Reproduciendo parada '\(item.stopName)' - '\(item.text.prefix(50))...'")
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
        print("🔊 AudioService: Cola limpiada")
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
        print("⏸️ AudioService: Pausado")
    }

    /// Reanudar reproducción
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        print("▶️ AudioService: Reanudado")
    }

    /// Detener reproducción (mantiene la cola)
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentText = nil
        currentQueueItem = nil
        print("⏹️ AudioService: Detenido")
    }

    /// Detener y limpiar todo
    func stopAndClear() {
        stop()
        clearQueue()
        print("⏹️ AudioService: Detenido y cola limpiada")
    }

    /// Saltar adelante 15 segundos (no aplicable en TTS, pero útil para UI)
    func skipForward() {
        print("⏩ AudioService: Skip forward (no aplicable en TTS)")
    }

    /// Saltar atrás 15 segundos
    func skipBackward() {
        // Reiniciar el audio actual
        if let text = currentText {
            speak(text: text)
        }
        print("⏪ AudioService: Reiniciando audio")
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                          didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
        }
        print("🔊 AudioService: Reproducción iniciada")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                          didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
            self.currentText = nil

            // Reproducir siguiente en cola si hay más
            if !self.audioQueue.isEmpty {
                print("✅ AudioService: Reproducción finalizada, continuando con siguiente en cola...")
                self.playNextInQueue()
            } else {
                self.currentQueueItem = nil
                print("✅ AudioService: Reproducción finalizada, cola vacía")
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                          didPause utterance: AVSpeechUtterance) {
        print("⏸️ AudioService: Pausado por sistema")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                          didContinue utterance: AVSpeechUtterance) {
        print("▶️ AudioService: Reanudado por sistema")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                          didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isPaused = false
        }
        print("❌ AudioService: Cancelado")
    }
}