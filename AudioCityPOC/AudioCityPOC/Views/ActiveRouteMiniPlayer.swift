//
//  ActiveRouteMiniPlayer.swift
//  AudioCityPOC
//
//  Mini player flotante que aparece en todas las tabs cuando hay una ruta activa
//  Diseño estilo Transit: compacto, informativo, con números destacados
//

import SwiftUI

struct ActiveRouteMiniPlayer: View {
    @ObservedObject var viewModel: RouteViewModel
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Indicador animado de ruta activa
                routeIndicator

                // Info principal
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text(viewModel.currentRoute?.name ?? "Ruta activa")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)

                    // Progreso y parada actual
                    HStack(spacing: ACSpacing.sm) {
                        // Progreso estilo Transit
                        HStack(spacing: 2) {
                            Text("\(viewModel.getVisitedCount())")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(ACColors.primary)
                            Text("/\(viewModel.stops.count)")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.textSecondary)
                        }

                        if let currentStop = viewModel.currentStop {
                            Text("•")
                                .foregroundColor(ACColors.textTertiary)
                            Text(currentStop.name)
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Play/Pause button
                if viewModel.audioService.isPlaying || viewModel.audioService.isPaused {
                    Button(action: {
                        if viewModel.audioService.isPaused {
                            viewModel.resumeAudio()
                        } else if viewModel.audioService.isPlaying {
                            viewModel.pauseAudio()
                        }
                    }) {
                        Image(systemName: viewModel.audioService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(ACColors.primary)
                            .cornerRadius(18)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Route Indicator

    private var routeIndicator: some View {
        ZStack {
            Circle()
                .fill(ACColors.primary)
                .frame(width: 44, height: 44)

            if viewModel.audioService.isPlaying {
                // Barras de audio animadas
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        MiniWaveBar(delay: Double(index) * 0.15)
                    }
                }
            } else if viewModel.audioService.isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "headphones")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Mini Wave Bar

private struct MiniWaveBar: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.white)
            .frame(width: 3, height: isAnimating ? 16 : 6)
            .animation(
                Animation.easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack {
        Spacer()
        ActiveRouteMiniPlayer(viewModel: RouteViewModel(), onTap: {})
            .padding()
    }
    .background(ACColors.background)
}
