//
//  AllRoutesView.swift
//  AudioCityPOC
//
//  Pantalla con todas las rutas, buscador y filtros
//

import SwiftUI

struct AllRoutesView: View {
    let routes: [Route]
    let onSelectRoute: (Route) -> Void

    @StateObject private var favoritesService = FavoritesService()
    @State private var searchText = ""
    @State private var selectedDifficulty: DifficultyFilter = .all
    @State private var selectedCity: String = "Todas"
    @State private var sortOption: SortOption = .name

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Buscador
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Filtros
                filtersSection
                    .padding(.vertical, 12)

                // Resultados
                if filteredRoutes.isEmpty {
                    emptyResultsView
                } else {
                    routesList
                }
            }
            .navigationTitle("Todas las Rutas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Text(option.displayName)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Buscar rutas...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    // MARK: - Filters Section
    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Filtro de dificultad
                Menu {
                    ForEach(DifficultyFilter.allCases, id: \.self) { difficulty in
                        Button(action: { selectedDifficulty = difficulty }) {
                            HStack {
                                Text(difficulty.displayName)
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedDifficulty == .all ? "Dificultad" : selectedDifficulty.displayName,
                        isActive: selectedDifficulty != .all,
                        icon: "chart.bar.fill"
                    )
                }

                // Filtro de ciudad
                Menu {
                    Button(action: { selectedCity = "Todas" }) {
                        HStack {
                            Text("Todas")
                            if selectedCity == "Todas" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    ForEach(availableCities, id: \.self) { city in
                        Button(action: { selectedCity = city }) {
                            HStack {
                                Text(city)
                                if selectedCity == city {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedCity == "Todas" ? "Ciudad" : selectedCity,
                        isActive: selectedCity != "Todas",
                        icon: "mappin.circle.fill"
                    )
                }

                // Filtro de favoritos
                Button(action: {
                    // Toggle favoritos filter - implementar si se necesita
                }) {
                    FilterChip(
                        title: "Favoritos",
                        isActive: false,
                        icon: "heart.fill"
                    )
                }

                // Limpiar filtros
                if hasActiveFilters {
                    Button(action: clearFilters) {
                        Text("Limpiar")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Routes List
    private var routesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Header con contador
                HStack {
                    Text("\(filteredRoutes.count) rutas encontradas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                ForEach(filteredRoutes) { route in
                    RouteSearchCard(
                        route: route,
                        isFavorite: favoritesService.isFavorite(route.id),
                        onTap: { onSelectRoute(route); dismiss() },
                        onFavoriteTap: { favoritesService.toggleFavorite(route.id) }
                    )
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Empty Results
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No se encontraron rutas")
                .font(.headline)

            Text("Prueba con otros términos de búsqueda o filtros")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if hasActiveFilters {
                Button("Limpiar filtros") {
                    clearFilters()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Computed Properties
    private var filteredRoutes: [Route] {
        var result = routes

        // Filtrar por búsqueda
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { route in
                route.name.lowercased().contains(searchLower) ||
                route.description.lowercased().contains(searchLower) ||
                route.city.lowercased().contains(searchLower) ||
                route.neighborhood.lowercased().contains(searchLower)
            }
        }

        // Filtrar por dificultad
        if selectedDifficulty != .all {
            result = result.filter { route in
                route.difficulty.lowercased() == selectedDifficulty.rawValue.lowercased()
            }
        }

        // Filtrar por ciudad
        if selectedCity != "Todas" {
            result = result.filter { $0.city == selectedCity }
        }

        // Ordenar
        switch sortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .duration:
            result.sort { $0.durationMinutes < $1.durationMinutes }
        case .distance:
            result.sort { $0.distanceKm < $1.distanceKm }
        case .stops:
            result.sort { $0.numStops > $1.numStops }
        }

        return result
    }

    private var availableCities: [String] {
        Array(Set(routes.map { $0.city })).sorted()
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedDifficulty != .all || selectedCity != "Todas"
    }

    private func clearFilters() {
        searchText = ""
        selectedDifficulty = .all
        selectedCity = "Todas"
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isActive: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.subheadline)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundColor(isActive ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? Color.blue : Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Route Search Card
struct RouteSearchCard: View {
    let route: Route
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icono de categoría
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(categoryColor)
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(route.neighborhood), \(route.city)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Label("\(route.durationMinutes)m", systemImage: "clock")
                        Label("\(route.numStops)", systemImage: "mappin")
                        Text(route.difficulty.capitalized)
                            .foregroundColor(difficultyColor)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Botón favorito
                Button(action: onFavoriteTap) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
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

// MARK: - Enums
enum DifficultyFilter: String, CaseIterable {
    case all = "all"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .all: return "Todas"
        case .easy: return "Fácil"
        case .medium: return "Media"
        case .hard: return "Difícil"
        }
    }
}

enum SortOption: String, CaseIterable {
    case name
    case duration
    case distance
    case stops

    var displayName: String {
        switch self {
        case .name: return "Nombre"
        case .duration: return "Duración"
        case .distance: return "Distancia"
        case .stops: return "Nº paradas"
        }
    }
}

#Preview {
    AllRoutesView(routes: []) { _ in }
}
