//
//  RouteDetailView.swift
//  AudioCityPOC
//
//  Vista de detalles de la ruta con lista de paradas
//

import SwiftUI

struct RouteDetailView: View {
    @ObservedObject var viewModel: RouteViewModel
    let route: Route

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isRouteActive {
                    // Mostrar mapa cuando la ruta está activa
                    RouteMapView(viewModel: viewModel)
                } else {
                    // Mostrar detalles de la ruta
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header con imagen
                            headerSection

                            // Información de la ruta
                            routeInfoSection

                            // Lista de paradas
                            stopsSection

                            // Botón de inicio
                            startButton

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(route.name)
                        .font(.headline)
                }
            }
            .alert("Permisos necesarios", isPresented: .constant(viewModel.errorMessage?.contains("permisos") == true)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icono de la ruta
            Image(systemName: "map.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding()
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )

            Text(route.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(route.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Route Info Section
    private var routeInfoSection: some View {
        VStack(spacing: 16) {
            // Card con detalles
            VStack(spacing: 12) {
                HStack {
                    InfoItem(icon: "clock.fill", text: "\(route.durationMinutes) min", color: .orange)
                    Spacer()
                    InfoItem(icon: "figure.walk", text: "\(String(format: "%.1f", route.distanceKm)) km", color: .green)
                    Spacer()
                    InfoItem(icon: "chart.bar.fill", text: route.difficulty, color: .blue)
                }

                Divider()

                HStack {
                    InfoItem(icon: "mappin.circle.fill", text: route.neighborhood, color: .purple)
                    Spacer()
                    InfoItem(icon: "checkmark.circle.fill", text: "\(viewModel.stops.count) paradas", color: .teal)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }

    // MARK: - Stops Section
    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paradas")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                ForEach(viewModel.stops) { stop in
                    StopRow(stop: stop, isVisited: stop.hasBeenVisited)
                }
            }
        }
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            viewModel.startRoute()
        }) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title3)
                Text("Iniciar Ruta")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
        }
        .padding(.vertical)
    }
}

// MARK: - Info Item Component
struct InfoItem: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Stop Row Component
struct StopRow: View {
    let stop: Stop
    let isVisited: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Número de orden
            ZStack {
                Circle()
                    .fill(isVisited ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)

                if isVisited {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                } else {
                    Text("\(stop.order)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }

            // Información de la parada
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isVisited ? .secondary : .primary)

                Text(stop.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Icono de categoría
            Image(systemName: categoryIcon(for: stop.category))
                .foregroundColor(.blue)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isVisited ? Color.green.opacity(0.05) : Color(UIColor.secondarySystemBackground))
        )
    }

    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "historia":
            return "book.fill"
        case "arquitectura":
            return "building.columns.fill"
        case "arte":
            return "paintpalette.fill"
        case "naturaleza":
            return "leaf.fill"
        default:
            return "mappin"
        }
    }
}

#Preview {
    let viewModel = RouteViewModel()
    let mockRoute = Route(
        id: "test",
        name: "Ruta de prueba",
        description: "Una ruta de ejemplo",
        city: "Madrid",
        neighborhood: "Centro",
        durationMinutes: 60,
        distanceKm: 3.5,
        difficulty: "Fácil",
        numStops: 6,
        language: "es",
        isActive: true,
        createdAt: "",
        updatedAt: "",
        thumbnailUrl: "",
        startLocation: Route.Location(latitude: 40.4168, longitude: -3.7038, name: "Inicio"),
        endLocation: Route.Location(latitude: 40.4168, longitude: -3.7038, name: "Fin")
    )
    return RouteDetailView(viewModel: viewModel, route: mockRoute)
}
