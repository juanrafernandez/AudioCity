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
    @ObservedObject private var pointsService = PointsService.shared
    @State private var showingPointsHistory = false

    var body: some View {
        NavigationView {
            List {
                // Sección de puntos y nivel
                pointsSection

                // Estadísticas rápidas
                statsSection

                // Información de la app
                Section {
                    HStack {
                        Label("Versión", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Información")
                }

                // Permisos
                Section {
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
                } header: {
                    Text("Permisos")
                }

                // Debug info
                Section {
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
                } header: {
                    Text("Debug")
                }
            }
            .navigationTitle("Perfil")
            .sheet(isPresented: $showingPointsHistory) {
                PointsHistoryView()
            }
        }
        .onAppear {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocationPermission()
            }
        }
        .overlay {
            // Notificación de level up
            if let newLevel = pointsService.recentLevelUp {
                LevelUpNotification(level: newLevel) {
                    pointsService.clearLevelUpNotification()
                }
            }
        }
    }

    // MARK: - Points Section
    private var pointsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Nivel y puntos
                HStack(alignment: .center, spacing: 16) {
                    // Icono de nivel
                    ZStack {
                        Circle()
                            .fill(levelColor.opacity(0.15))
                            .frame(width: 70, height: 70)

                        Image(systemName: pointsService.stats.currentLevel.icon)
                            .font(.system(size: 30))
                            .foregroundColor(levelColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pointsService.stats.currentLevel.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.subheadline)
                            Text("\(pointsService.stats.totalPoints) puntos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // Barra de progreso al siguiente nivel
                if let nextLevel = pointsService.stats.currentLevel.nextLevel {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Siguiente: \(nextLevel.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(pointsService.stats.pointsToNextLevel) pts")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(levelColor)
                                    .frame(width: geometry.size.width * pointsService.stats.progressToNextLevel, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                } else {
                    Text("¡Has alcanzado el nivel máximo!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }

                // Botón para ver historial
                Button(action: { showingPointsHistory = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Ver historial de puntos")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                StatBox(
                    value: "\(pointsService.stats.routesCreated)",
                    label: "Creadas",
                    icon: "map.fill",
                    color: .blue
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    value: "\(pointsService.stats.routesCompleted)",
                    label: "Completadas",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    value: "\(pointsService.stats.currentStreak)",
                    label: "Racha",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("Estadísticas")
        }
    }

    // MARK: - Computed Properties

    private var levelColor: Color {
        switch pointsService.stats.currentLevel {
        case .explorer: return .gray
        case .traveler: return .blue
        case .localGuide: return .green
        case .expert: return .purple
        case .master: return .orange
        }
    }

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

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Level Up Notification
struct LevelUpNotification: View {
    let level: UserLevel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: level.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)

                Text("¡Nivel alcanzado!")
                    .font(.headline)

                Text(level.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

                Button("Continuar") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .transition(.opacity)
    }
}

// MARK: - Points History View
struct PointsHistoryView: View {
    @ObservedObject private var pointsService = PointsService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if pointsService.transactions.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("Historial de Puntos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("Sin actividad")
                .font(.title3)
                .fontWeight(.medium)

            Text("Completa rutas y crea contenido para ganar puntos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var historyList: some View {
        List {
            // Resumen
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total acumulado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(pointsService.stats.totalPoints) puntos")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Nivel actual")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: pointsService.stats.currentLevel.icon)
                            Text(pointsService.stats.currentLevel.name)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 4)
            }

            // Transacciones agrupadas por fecha
            ForEach(pointsService.getTransactionsGroupedByDate(), id: \.date) { group in
                Section(group.date) {
                    ForEach(group.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: PointsTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.action.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.action.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let routeName = transaction.routeName {
                    Text(routeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("+\(transaction.points)")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ProfileView()
}
