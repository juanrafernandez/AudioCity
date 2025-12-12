//
//  SplashView.swift
//  AudioCityPOC
//
//  Pantalla de carga animada con branding de AudioCity
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    @State private var audioWaveAmplitudes: [CGFloat] = [0.3, 0.5, 0.7, 0.5, 0.3]
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Fondo con gradiente usando colores del design system
            LinearGradient(
                gradient: Gradient(colors: [
                    ACColors.primary,
                    ACColors.primaryDark
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: ACSpacing.xxl) {
                Spacer()

                // Logo de la app con animaciones
                ZStack {
                    // Ondas de audio alrededor del logo
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.white.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: CGFloat(180 + index * 40), height: CGFloat(180 + index * 40))
                            .scaleEffect(isAnimating ? 1.3 : 1.0)
                            .opacity(isAnimating ? 0 : 0.8)
                            .animation(
                                Animation.easeOut(duration: 2.0)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.4),
                                value: isAnimating
                            )
                    }

                    // Círculo de fondo del logo
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    // Logo de la app
                    Image("AppLogo_transp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // Nombre de la app y tagline
                VStack(spacing: ACSpacing.sm) {
                    Text("AudioCity")
                        .font(ACTypography.displayLarge)
                        .foregroundColor(.white)
                        .opacity(logoOpacity)

                    // Tagline con animación de aparición
                    Text("Descubre tu ciudad escuchando")
                        .font(ACTypography.bodyLarge)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                }

                Spacer()

                // Indicador de carga con ondas de audio estilo AudioCity
                VStack(spacing: ACSpacing.lg) {
                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: ACRadius.xs)
                                .fill(Color.white)
                                .frame(width: 5, height: 24 * audioWaveAmplitudes[index])
                        }
                    }

                    // Texto de carga
                    Text("Preparando tu experiencia...")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
                    .frame(height: ACSpacing.mega)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Animación de entrada del logo
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Activar ondas después de que aparezca el logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }

        // Mostrar tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                showTagline = true
            }
        }

        // Animar ondas de audio
        animateAudioWaves()
    }

    private func animateAudioWaves() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                audioWaveAmplitudes = audioWaveAmplitudes.map { _ in
                    CGFloat.random(in: 0.3...1.0)
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
