//
//  MapView.swift
//  AudioCityPOC
//
//  Vista del mapa con ubicación en tiempo real y controles de audio
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: RouteViewModel
    @State private var region: MKCoordinateRegion
    @State private var showStopDetails = false

    init(viewModel: RouteViewModel) {
        self.viewModel = viewModel

        // Configurar región inicial
        let initialCenter = viewModel.currentRoute?.startLocation.coordinate ?? CLLocationCoordinate2D(latitude: 40.3974, longitude: -3.6924)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    var body: some View {
        ZStack {
            // Mapa
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: viewModel.stops) { stop in
                MapAnnotation(coordinate: stop.coordinate) {
                    StopAnnotationView(
                        stop: stop,
                        isVisited: stop.hasBeenVisited,
                        isCurrent: viewModel.currentStop?.id == stop.id
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)

            // Overlays
            VStack {
                // Banner de parada actual
                if let currentStop = viewModel.currentStop {
                    CurrentStopBanner(stop: currentStop)
                        .padding()
                        .transition(.move(edge: .top))
                }

                Spacer()

                // Progreso
                ProgressBar(
                    current: viewModel.getVisitedCount(),
                    total: viewModel.stops.count
                )
                .padding(.horizontal)

                // Controles de audio
                AudioControlsOverlay(viewModel: viewModel)
                    .padding()
            }

            // Botón de finalizar ruta
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.endRoute()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color.white)
                            )
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onChange(of: viewModel.locationService.userLocation) { newLocation in
            if let location = newLocation {
                // Centrar mapa en ubicación del usuario
                withAnimation {
                    region.center = location.coordinate
                }
            }
        }
    }
}

// MARK: - Stop Annotation View
struct StopAnnotationView: View {
    let stop: Stop
    let isVisited: Bool
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.blue : (isVisited ? Color.green : Color.orange))
                    .frame(width: 40, height: 40)

                if isVisited {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.headline)
                } else {
                    Text("\(stop.order)")
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .shadow(radius: 3)

            // Nombre de la parada
            if isCurrent {
                Text(stop.name)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(y: 4)
            }
        }
    }
}

// MARK: - Current Stop Banner
struct CurrentStopBanner: View {
    let stop: Stop

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                Text("Reproduciendo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(stop.name)
                .font(.headline)
                .fontWeight(.bold)

            Text(stop.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(current) de \(total) paradas completadas")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Audio Controls Overlay
struct AudioControlsOverlay: View {
    @ObservedObject var viewModel: RouteViewModel

    var body: some View {
        HStack(spacing: 20) {
            // Botón de pausa/resume
            Button(action: {
                if viewModel.audioService.isPaused {
                    viewModel.resumeAudio()
                } else if viewModel.audioService.isPlaying {
                    viewModel.pauseAudio()
                }
            }) {
                Image(systemName: viewModel.audioService.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 3)
            }
            .disabled(!viewModel.audioService.isPlaying && !viewModel.audioService.isPaused)
            .opacity((viewModel.audioService.isPlaying || viewModel.audioService.isPaused) ? 1.0 : 0.5)

            // Botón de detener
            Button(action: {
                viewModel.stopAudio()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.red))
                    .shadow(radius: 3)
            }
            .disabled(!viewModel.audioService.isPlaying)
            .opacity(viewModel.audioService.isPlaying ? 1.0 : 0.5)

            // Indicador de reproducción
            if viewModel.audioService.isPlaying {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        AudioWaveBar(delay: Double(index) * 0.2)
                    }
                }
                .frame(width: 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Audio Wave Bar (Animated)
struct AudioWaveBar: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.blue)
            .frame(width: 4, height: isAnimating ? 20 : 8)
            .animation(
                Animation.easeInOut(duration: 0.6)
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
    let viewModel = RouteViewModel()
    return MapView(viewModel: viewModel)
}
