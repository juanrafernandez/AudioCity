//
//  RoutesListView.swift
//  AudioCityPOC
//
//  Vista principal de rutas con secciones estilo Wikiloc
//

import SwiftUI

struct RoutesListView: View {
    @StateObject private var viewModel = RouteViewModel()
    @StateObject private var tripService = TripService()
    @StateObject private var favoritesService = FavoritesService()
    @State private var showingTripOnboarding = false
    @State private var showingAllRoutes = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.currentRoute != nil {
                    routeDetailView
                } else {
                    mainContent
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
        .sheet(isPresented: $showingTripOnboarding) {
            TripOnboardingView(tripService: tripService, onComplete: { _ in
                showingTripOnboarding = false
            })
        }
        .sheet(isPresented: $showingAllRoutes) {
            AllRoutesView(routes: viewModel.availableRoutes) { route in
                viewModel.selectRoute(route)
            }
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
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
            routesSectionsView
        }
    }

    // MARK: - Routes Sections View
    private var routesSectionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                    .padding(.horizontal)

                // Mis Viajes Section
                myTripsSection
                    .padding(.horizontal)

                // Rutas Favoritas (horizontal scroll)
                if !favoriteRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Rutas Favoritas",
                        icon: "heart.fill",
                        iconColor: .red,
                        routes: favoriteRoutes
                    )
                }

                // Top Rutas (horizontal scroll)
                if !topRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Top Rutas",
                        icon: "star.fill",
                        iconColor: .yellow,
                        routes: topRoutes
                    )
                }

                // Rutas de Moda (horizontal scroll)
                if !trendingRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Rutas de Moda",
                        icon: "flame.fill",
                        iconColor: .orange,
                        routes: trendingRoutes
                    )
                }

                // Botón Todas las Rutas
                allRoutesButton
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Descubre tu ciudad")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(viewModel.availableRoutes.count) rutas disponibles")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - My Trips Section
    private var myTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "suitcase.fill")
                    .foregroundColor(.purple)
                Text("Mis Viajes")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    showingTripOnboarding = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Planificar")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.purple))
                }
            }

            if tripService.trips.isEmpty {
                emptyTripsCard
            } else {
                ForEach(tripService.trips) { trip in
                    TripCard(trip: trip, tripService: tripService) {
                        // TODO: Navigate to trip detail
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var emptyTripsCard: some View {
        Button(action: {
            showingTripOnboarding = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.title)
                    .foregroundColor(.purple.opacity(0.6))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Planifica tu viaje")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("Selecciona destino y rutas para tenerlas offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Horizontal Section
    private func routeSectionHorizontal(
        title: String,
        icon: String,
        iconColor: Color,
        routes: [Route]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    // TODO: Ver todas
                }) {
                    Text("Ver todas")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(routes) { route in
                        RouteCardCompact(route: route) {
                            viewModel.selectRoute(route)
                        }
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - All Routes Button
    private var allRoutesButton: some View {
        Button(action: {
            showingAllRoutes = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Todas las Rutas")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("\(viewModel.availableRoutes.count) rutas con buscador y filtros")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
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

    // MARK: - Computed Properties for Route Categories
    private var favoriteRoutes: [Route] {
        favoritesService.filterFavorites(from: viewModel.availableRoutes)
    }

    private var topRoutes: [Route] {
        // Rutas con más paradas (excluyendo favoritos para evitar duplicados)
        Array(viewModel.availableRoutes
            .filter { !favoritesService.isFavorite($0.id) }
            .sorted { $0.numStops > $1.numStops }
            .prefix(5))
    }

    private var trendingRoutes: [Route] {
        // Por ahora mostrar las mismas rutas para ver la UI
        // TODO: Implementar lógica real de trending (por popularidad, recientes, etc.)
        Array(viewModel.availableRoutes.prefix(5))
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
                RouteDetailContent(route: route, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Route Card Compact
struct RouteCardCompact: View {
    let route: Route
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header con icono
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(categoryColor)
                        )

                    Spacer()

                    // Dificultad
                    Text(route.difficulty.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(difficultyColor.opacity(0.15))
                        )
                }

                // Nombre y ubicación
                Text(route.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("\(route.neighborhood), \(route.city)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Stats
                HStack(spacing: 12) {
                    Label("\(route.durationMinutes)m", systemImage: "clock")
                    Label("\(route.numStops)", systemImage: "mappin")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var categoryIcon: String {
        switch route.neighborhood.lowercased() {
        case "arganzuela": return "building.2.fill"
        case "centro": return "book.fill"
        case "chamberí": return "drop.fill"
        default: return "map.fill"
        }
    }

    private var categoryColor: Color {
        switch route.neighborhood.lowercased() {
        case "arganzuela": return .orange
        case "centro": return .purple
        case "chamberí": return .cyan
        default: return .blue
        }
    }

    private var difficultyColor: Color {
        switch route.difficulty.lowercased() {
        case "easy", "fácil": return .green
        case "medium", "media": return .orange
        case "hard", "difícil": return .red
        default: return .blue
        }
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: Trip
    let tripService: TripService
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icono de destino
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.destinationCity)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text("\(trip.routeCount) rutas")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if trip.isOfflineAvailable {
                            Label("Offline", systemImage: "arrow.down.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }

                        if let dateRange = trip.dateRangeFormatted {
                            Text(dateRange)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Route Detail Content (extracted from original)
struct RouteDetailContent: View {
    let route: Route
    @ObservedObject var viewModel: RouteViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                routeHeader
                routeStats
                stopsSection
                startButton
                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    private var routeHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding()
                .background(
                    Circle().fill(Color.blue.opacity(0.1))
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

    private var routeStats: some View {
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
