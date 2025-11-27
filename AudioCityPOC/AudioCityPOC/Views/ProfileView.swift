//
//  ProfileView.swift
//  AudioCityPOC
//
//  Vista de perfil/configuración
//

import SwiftUI
import CoreLocation

struct ProfileView: View {
    @StateObject private var locationService = LocationService()

    var body: some View {
        NavigationView {
            List {
                // Sección de estadísticas
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AudioCity")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Explorador de audioguías")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }

                // Información de la app
                Section("Información") {
                    HStack {
                        Label("Versión", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("POC-001")
                            .foregroundColor(.secondary)
                    }
                }

                // Permisos
                Section("Permisos") {
                    HStack {
                        Label("Ubicación", systemImage: "location.fill")
                        Spacer()
                        Text(locationStatusText)
                            .foregroundColor(locationStatusColor)
                            .font(.caption)
                    }

                    if locationService.authorizationStatus != .authorizedAlways {
                        Button(action: {
                            locationService.requestLocationPermission()
                        }) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                Text("Solicitar permisos")
                            }
                        }
                    }
                }

                // Acerca de
                Section("Acerca de") {
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Label("GitHub", systemImage: "link")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Label("Desarrollado con", systemImage: "heart.fill")
                        Spacer()
                        Text("SwiftUI + Firebase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Debug info
                Section("Debug") {
                    if let userLocation = locationService.userLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ubicación actual")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Lat: \(String(format: "%.6f", userLocation.coordinate.latitude))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Lon: \(String(format: "%.6f", userLocation.coordinate.longitude))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Tracking activo")
                            .font(.caption)
                        Spacer()
                        Text(locationService.isTracking ? "Sí" : "No")
                            .font(.caption)
                            .foregroundColor(locationService.isTracking ? .green : .red)
                    }
                }
            }
            .navigationTitle("Perfil")
        }
        .onAppear {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocationPermission()
            }
        }
    }

    // MARK: - Computed Properties

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "Siempre"
        case .authorizedWhenInUse:
            return "Al usar la app"
        case .denied, .restricted:
            return "Denegado"
        case .notDetermined:
            return "No determinado"
        @unknown default:
            return "Desconocido"
        }
    }

    private var locationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    ProfileView()
}
