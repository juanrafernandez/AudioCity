//
//  MapExploreView.swift
//  AudioCityPOC
//
//  Vista de mapa para explorar todos los puntos de audio
//

import SwiftUI
import MapKit

struct MapExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.3974, longitude: -3.6924), // Madrid - Arganzuela
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showStopDetail = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadAllStops()
                    }
                } else {
                    // Mapa con paradas
                    mapView

                    // Overlay con controles
                    VStack {
                        // Header con información
                        if !viewModel.allStops.isEmpty {
                            infoHeader
                                .padding()
                        }

                        Spacer()

                        // Parada seleccionada
                        if let selectedStop = viewModel.selectedStop {
                            StopDetailCard(
                                stop: selectedStop,
                                isPlaying: viewModel.audioService.isPlaying,
                                isPaused: viewModel.audioService.isPaused,
                                onPlay: { viewModel.playStop(selectedStop) },
                                onPause: { viewModel.pauseAudio() },
                                onResume: { viewModel.resumeAudio() },
                                onStop: { viewModel.stopAudio() },
                                onClose: { viewModel.selectedStop = nil }
                            )
                            .padding()
                            .transition(.move(edge: .bottom))
                        }

                        // Botón de mi ubicación
                        HStack {
                            Spacer()
                            Button(action: centerOnUserLocation) {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.blue))
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Explorar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.allStops.isEmpty {
                        Text("\(viewModel.allStops.count) puntos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAllStops()
            viewModel.locationService.requestLocationPermission()
        }
    }

    // MARK: - Map View
    private var mapView: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: viewModel.allStops) { stop in
            MapAnnotation(coordinate: stop.coordinate) {
                StopMarker(stop: stop, isSelected: viewModel.selectedStop?.id == stop.id)
                    .onTapGesture {
                        withAnimation {
                            viewModel.selectedStop = stop
                            region.center = stop.coordinate
                        }
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Info Header
    private var infoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.routes.count) rutas disponibles")
                    .font(.headline)
                Text("\(viewModel.allStops.count) puntos de audio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Actions
    private func centerOnUserLocation() {
        if let userLocation = viewModel.locationService.userLocation {
            withAnimation {
                region.center = userLocation.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            }
        } else {
            viewModel.locationService.startTracking()
        }
    }
}

// MARK: - Stop Marker
struct StopMarker: View {
    let stop: Stop
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.orange)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)

                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.white)
                    .font(isSelected ? .body : .caption)
            }
            .shadow(radius: 4)

            if isSelected {
                Text(stop.name)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .offset(y: 4)
            }
        }
        .animation(.spring(), value: isSelected)
    }
}

// MARK: - Stop Detail Card
struct StopDetailCard: View {
    let stop: Stop
    let isPlaying: Bool
    let isPaused: Bool
    let onPlay: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.name)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(stop.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }

            // Descripción
            Text(stop.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            Divider()

            // Controles de audio
            HStack(spacing: 16) {
                if !isPlaying && !isPaused {
                    Button(action: onPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Escuchar")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                } else {
                    // Pause/Resume
                    Button(action: isPaused ? onResume : onPause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.blue))
                    }

                    // Stop
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.red))
                    }

                    // Indicador de reproducción
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            AudioWaveBar(delay: Double(index) * 0.2)
                        }
                    }
                    .frame(width: 40)
                }
            }

            // Información adicional
            HStack {
                Label("\(stop.audioDurationSeconds)s", systemImage: "clock")
                Spacer()
                Label("\(Int(stop.triggerRadiusMeters))m", systemImage: "location.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    MapExploreView()
}
