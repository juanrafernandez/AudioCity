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

    let brandColor = Color(red: 0.2, green: 0.38, blue: 0.98)

    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    brandColor,
                    brandColor.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo con icono
                ZStack {
                    // Círculo de fondo animado
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    // Icono principal
                    VStack(spacing: 8) {
                        // Icono de ubicación con ondas de audio
                        ZStack {
                            // Pin de ubicación
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .foregroundColor(.white)

                            // Ondas de audio alrededor
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.white.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                                    .frame(width: CGFloat(90 + index * 20), height: CGFloat(90 + index * 20))
                                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(
                                        Animation.easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }

                // Nombre de la app
                VStack(spacing: 8) {
                    Text("AudioCity")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Tagline con animación de aparición
                    Text("Descubre tu ciudad escuchando")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showTagline)
                }

                Spacer()

                // Indicador de carga con ondas de audio
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 4, height: 20 * audioWaveAmplitudes[index])
                            .animation(
                                Animation.easeInOut(duration: 0.4)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: audioWaveAmplitudes[index]
                            )
                    }
                }
                .padding(.bottom, 20)

                // Texto de carga
                Text("Preparando tu experiencia...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            isAnimating = true
            showTagline = true
            animateAudioWaves()
        }
    }

    private func animateAudioWaves() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation {
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
