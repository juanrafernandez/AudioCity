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
//

import Foundation
import AVFoundation
import Combine

class AudioService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentText: String?
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    
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
    
    /// Reproducir texto con TTS
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
    
    /// Detener reproducción
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentText = nil
        print("⏹️ AudioService: Detenido")
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
        }
        print("✅ AudioService: Reproducción finalizada")
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