//
//  RoutesListView.swift
//  AudioCityPOC
//
//  Vista con lista de rutas disponibles
//

import SwiftUI

struct RoutesListView: View {
    @StateObject private var viewModel = RouteViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.currentRoute != nil {
                    // Mostrar detalle de ruta seleccionada
                    routeDetailView
                } else {
                    // Mostrar lista de rutas
                    routesListContent
                }
            }
            .navigationTitle(viewModel.currentRoute?.name ?? "Rutas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.currentRoute != nil && !viewModel.isRouteActive {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.backToRoutesList()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Rutas")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.availableRoutes.isEmpty {
                viewModel.loadAvailableRoutes()
            }
        }
    }

    // MARK: - Routes List Content
    @ViewBuilder
    private var routesListContent: some View {
        if viewModel.isLoadingRoutes {
            LoadingView()
        } else if viewModel.availableRoutes.isEmpty {
            if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    viewModel.loadAvailableRoutes()
                }
            } else {
                emptyStateView
            }
        } else {
            routesList
        }
    }

    // MARK: - Routes List
    private var routesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Descubre tu ciudad")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(viewModel.availableRoutes.count) rutas disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)

                // Lista de rutas
                ForEach(viewModel.availableRoutes) { route in
                    RouteCard(route: route) {
                        viewModel.selectRoute(route)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("No hay rutas disponibles")
                .font(.title3)
                .fontWeight(.medium)

            Text("Pronto añadiremos nuevas rutas en tu ciudad")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Reintentar") {
                viewModel.loadAvailableRoutes()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Route Detail View
    @ViewBuilder
    private var routeDetailView: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if let route = viewModel.currentRoute {
            if viewModel.isRouteActive {
                MapView(viewModel: viewModel)
            } else {
                routeContent(route)
            }
        }
    }

    // MARK: - Route Content
    private func routeContent(_ route: Route) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                routeHeader(route)

                // Stats
                routeStats(route)

                // Paradas
                stopsSection

                // Botón de inicio
                startButton

                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    // MARK: - Route Header
    private func routeHeader(_ route: Route) -> some View {
        VStack(spacing: 12) {
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

    // MARK: - Route Stats
    private func routeStats(_ route: Route) -> some View {
        VStack(spacing: 16) {
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

// MARK: - Route Card Component
struct RouteCard: View {
    let route: Route
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header con icono y nombre
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(categoryColor)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(route.neighborhood + ", " + route.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                // Descripción
                Text(route.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Stats
                HStack(spacing: 16) {
                    Label("\(route.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(String(format: "%.1f", route.distanceKm)) km", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(route.numStops) paradas", systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Dificultad badge
                    Text(route.difficulty.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(difficultyColor.opacity(0.15))
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryIcon: String {
        switch route.neighborhood.lowercased() {
        case "arganzuela":
            return "building.2.fill"
        case "centro":
            return "book.fill"
        case "chamberí":
            return "drop.fill"
        default:
            return "map.fill"
        }
    }

    private var categoryColor: Color {
        switch route.neighborhood.lowercased() {
        case "arganzuela":
            return .orange
        case "centro":
            return .purple
        case "chamberí":
            return .cyan
        default:
            return .blue
        }
    }

    private var difficultyColor: Color {
        switch route.difficulty.lowercased() {
        case "easy", "fácil":
            return .green
        case "medium", "media":
            return .orange
        case "hard", "difícil":
            return .red
        default:
            return .blue
        }
    }
}

#Preview {
    RoutesListView()
}
