//
//  RoutesListView.swift
//  AudioCityPOC
//
//  Vista con lista de rutas disponibles
//

import SwiftUI

struct RoutesListView: View {
    @StateObject private var viewModel = RouteViewModel()
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let route = viewModel.currentRoute {
                    // Vista de la ruta cargada
                    routeContent(route)
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.loadRoute()
                    }
                } else {
                    ErrorView(message: "No se pudo cargar la ruta") {
                        viewModel.loadRoute()
                    }
                }
            }
            .navigationTitle("Mi Ruta")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel.currentRoute == nil {
                viewModel.loadRoute()
            }
        }
    }

    // MARK: - Route Content
    @ViewBuilder
    private func routeContent(_ route: Route) -> some View {
        if viewModel.isRouteActive {
            // Mostrar mapa cuando la ruta está activa
            MapView(viewModel: viewModel)
        } else {
            // Mostrar detalles de la ruta
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

#Preview {
    RoutesListView()
}
