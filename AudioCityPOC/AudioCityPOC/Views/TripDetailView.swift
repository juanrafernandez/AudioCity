//
//  TripDetailView.swift
//  AudioCityPOC
//
//  Vista de detalle de un viaje con exploración de rutas
//

import SwiftUI

// MARK: - Sort Option

enum RouteSortOption: String, CaseIterable {
    case popular = "Populares"
    case newest = "Más nuevas"
    case rating = "Mejor valoradas"

    var icon: String {
        switch self {
        case .popular: return "flame.fill"
        case .newest: return "sparkles"
        case .rating: return "star.fill"
        }
    }
}

// MARK: - Trip Detail View

struct TripDetailView: View {
    let tripId: String
    let initialTrip: Trip
    @ObservedObject var tripService: TripService
    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss

    // Trip actualizado desde el servicio
    private var trip: Trip {
        tripService.trips.first { $0.id == tripId } ?? initialTrip
    }

    // Estados
    @State private var allCityRoutes: [Route] = []
    @State private var isLoading = true
    @State private var showingDatePicker = false
    @State private var showingDeleteConfirmation = false

    // Filtros y ordenación
    @State private var selectedTheme: RouteTheme?
    @State private var sortOption: RouteSortOption = .popular
    @State private var searchText: String = ""

    // Fechas editables
    @State private var editableStartDate: Date
    @State private var editableEndDate: Date

    init(trip: Trip, tripService: TripService) {
        self.tripId = trip.id
        self.initialTrip = trip
        self.tripService = tripService
        _editableStartDate = State(initialValue: trip.startDate ?? Date())
        _editableEndDate = State(initialValue: trip.endDate ?? Date().addingTimeInterval(86400 * 7))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ACSpacing.sectionSpacing) {
                // Acciones rápidas (fechas, offline)
                quickActionsSection
                    .padding(.horizontal, ACSpacing.containerPadding)
                    .padding(.top, ACSpacing.md)

                // Rutas añadidas al viaje
                if !addedRoutes.isEmpty {
                    addedRoutesSection
                }

                // Explorar rutas de la ciudad
                exploreRoutesSection
            }
            .padding(.bottom, ACSpacing.mega)
        }
        .background(ACColors.background)
        .navigationTitle("\(trip.destinationCity) - \(trip.destinationCountry)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ACColors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ACColors.textPrimary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Eliminar viaje", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(ACColors.primary)
                }
            }
        }
        .onAppear {
            loadCityRoutes()
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .alert("Eliminar viaje", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                tripService.deleteTrip(trip.id)
                dismiss()
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar este viaje? Esta acción no se puede deshacer.")
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(spacing: ACSpacing.md) {
            // Fechas
            Button(action: { showingDatePicker = true }) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(ACColors.secondary)
                        .frame(width: 44)

                    VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                        Text("Fechas del viaje")
                            .font(ACTypography.labelSmall)
                            .foregroundColor(ACColors.textSecondary)
                        Text(trip.dateRangeFormatted ?? "Sin fechas definidas")
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(ACColors.textTertiary)
                }
                .padding(ACSpacing.md)
                .background(ACColors.surface)
                .cornerRadius(ACRadius.lg)
            }
            .buttonStyle(PlainButtonStyle())

            // Offline toggle
            HStack {
                Image(systemName: trip.isOfflineAvailable ? "arrow.down.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(trip.isOfflineAvailable ? ACColors.success : ACColors.textTertiary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Modo offline")
                        .font(ACTypography.labelSmall)
                        .foregroundColor(ACColors.textSecondary)
                    Text(trip.isOfflineAvailable ? "Rutas descargadas" : "Requiere conexión")
                        .font(ACTypography.bodyMedium)
                        .foregroundColor(ACColors.textPrimary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { trip.isOfflineAvailable },
                    set: { newValue in
                        tripService.markAsOfflineAvailable(trip.id, available: newValue)
                    }
                ))
                .tint(ACColors.success)
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
        }
    }

    // MARK: - Added Routes Section

    private var addedRoutesSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ACColors.primary)

                Text("Mis rutas del viaje")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("\(addedRoutes.count)")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textTertiary)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xxs)
                    .background(ACColors.borderLight)
                    .cornerRadius(ACRadius.full)
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Horizontal scroll de rutas añadidas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.md) {
                    ForEach(addedRoutes) { route in
                        AddedRouteCard(route: route) {
                            tripService.removeRoute(route.id, from: trip.id)
                        }
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    // MARK: - Explore Routes Section

    private var exploreRoutesSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ACColors.secondary)

                Text("¿Quieres añadir más rutas?")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Barra de búsqueda
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ACColors.textTertiary)

                TextField("Buscar rutas...", text: $searchText)
                    .font(ACTypography.bodyMedium)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ACColors.textTertiary)
                    }
                }
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .padding(.horizontal, ACSpacing.containerPadding)

            // Filtros de categoría
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.sm) {
                    // Chip "Todas"
                    filterChip(title: "Todas", icon: "square.grid.2x2", isSelected: selectedTheme == nil) {
                        selectedTheme = nil
                    }

                    // Chips de categorías
                    ForEach(availableThemes, id: \.self) { theme in
                        filterChip(title: theme.displayName, icon: theme.icon, isSelected: selectedTheme == theme) {
                            selectedTheme = theme
                        }
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }

            // Ordenación
            HStack {
                Text("Ordenar por:")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)

                ForEach(RouteSortOption.allCases, id: \.self) { option in
                    Button(action: { sortOption = option }) {
                        HStack(spacing: ACSpacing.xxs) {
                            Image(systemName: option.icon)
                                .font(.system(size: 10))
                            Text(option.rawValue)
                                .font(ACTypography.captionSmall)
                        }
                        .foregroundColor(sortOption == option ? ACColors.primary : ACColors.textTertiary)
                        .padding(.horizontal, ACSpacing.sm)
                        .padding(.vertical, ACSpacing.xs)
                        .background(sortOption == option ? ACColors.primaryLight : Color.clear)
                        .cornerRadius(ACRadius.full)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Lista de rutas
            if isLoading {
                ACLoadingState(message: "Cargando rutas...")
                    .frame(height: 200)
            } else if filteredRoutes.isEmpty {
                emptyRoutesView
                    .padding(.horizontal, ACSpacing.containerPadding)
            } else {
                LazyVStack(spacing: ACSpacing.md) {
                    ForEach(filteredRoutes) { route in
                        ExploreRouteCard(
                            route: route,
                            isAdded: trip.selectedRouteIds.contains(route.id)
                        ) {
                            if trip.selectedRouteIds.contains(route.id) {
                                tripService.removeRoute(route.id, from: trip.id)
                            } else {
                                tripService.addRoute(route.id, to: trip.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    private func filterChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ACSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(ACTypography.labelSmall)
            }
            .foregroundColor(isSelected ? .white : ACColors.textSecondary)
            .padding(.horizontal, ACSpacing.md)
            .padding(.vertical, ACSpacing.sm)
            .background(isSelected ? ACColors.primary : ACColors.surface)
            .cornerRadius(ACRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.full)
                    .stroke(isSelected ? Color.clear : ACColors.border, lineWidth: 1)
            )
        }
    }

    private var emptyRoutesView: some View {
        VStack(spacing: ACSpacing.md) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundColor(ACColors.textTertiary)

            Text("No se encontraron rutas")
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)

            if selectedTheme != nil || !searchText.isEmpty {
                Button("Limpiar filtros") {
                    selectedTheme = nil
                    searchText = ""
                }
                .font(ACTypography.labelSmall)
                .foregroundColor(ACColors.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ACSpacing.xxl)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: ACSpacing.xl) {
                VStack(alignment: .leading, spacing: ACSpacing.sm) {
                    Text("Fecha de inicio")
                        .font(ACTypography.labelSmall)
                        .foregroundColor(ACColors.textSecondary)

                    DatePicker("", selection: $editableStartDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(ACColors.primary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.sm) {
                    Text("Fecha de fin")
                        .font(ACTypography.labelSmall)
                        .foregroundColor(ACColors.textSecondary)

                    DatePicker("", selection: $editableEndDate, in: editableStartDate..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(ACColors.primary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Fechas del viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        tripService.updateTripDates(trip.id, startDate: editableStartDate, endDate: editableEndDate)
                        showingDatePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var addedRoutes: [Route] {
        allCityRoutes.filter { trip.selectedRouteIds.contains($0.id) }
    }

    private var availableThemes: [RouteTheme] {
        let themes = Set(allCityRoutes.map { $0.theme })
        return RouteTheme.allCases.filter { themes.contains($0) }
    }

    private var filteredRoutes: [Route] {
        var routes = allCityRoutes

        // Filtrar por búsqueda
        if !searchText.isEmpty {
            routes = routes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.neighborhood.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filtrar por tema
        if let theme = selectedTheme {
            routes = routes.filter { $0.theme == theme }
        }

        // Ordenar
        switch sortOption {
        case .popular:
            routes.sort { $0.usageCount > $1.usageCount }
        case .newest:
            routes.sort { $0.createdAt > $1.createdAt }
        case .rating:
            routes.sort { $0.rating > $1.rating }
        }

        return routes
    }

    // MARK: - Actions

    private func loadCityRoutes() {
        isLoading = true
        Task {
            do {
                let allRoutes = try await firebaseService.fetchAllRoutes()
                await MainActor.run {
                    allCityRoutes = allRoutes.filter {
                        $0.city.lowercased() == trip.destinationCity.lowercased()
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Added Route Card

struct AddedRouteCard: View {
    let route: Route
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.sm) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                if let url = URL(string: route.thumbnailUrl), !route.thumbnailUrl.isEmpty {
                    CachedAsyncImage(url: url) {
                        routePlaceholder
                    }
                    .frame(width: 140, height: 90)
                    .cornerRadius(ACRadius.md)
                } else {
                    routePlaceholder
                        .frame(width: 140, height: 90)
                        .cornerRadius(ACRadius.md)
                }

                // Botón quitar
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding(ACSpacing.xs)
            }

            // Info
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(route.name)
                    .font(ACTypography.labelSmall)
                    .foregroundColor(ACColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: ACSpacing.sm) {
                    ACMetaBadge(icon: "clock", text: route.durationFormatted)
                    ACMetaBadge(icon: "mappin", text: "\(route.numStops)")
                }
            }
        }
        .frame(width: 140)
    }

    private var routePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [ACColors.primary.opacity(0.8), ACColors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "headphones")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Explore Route Card

struct ExploreRouteCard: View {
    let route: Route
    let isAdded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Thumbnail
            if let url = URL(string: route.thumbnailUrl), !route.thumbnailUrl.isEmpty {
                CachedAsyncImage(url: url) {
                    routePlaceholder
                }
                .frame(width: 80, height: 80)
                .cornerRadius(ACRadius.md)
            } else {
                routePlaceholder
                    .frame(width: 80, height: 80)
                    .cornerRadius(ACRadius.md)
            }

            // Info
            VStack(alignment: .leading, spacing: ACSpacing.xs) {
                HStack {
                    Text(route.name)
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Rating
                    if route.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ACColors.gold)
                            Text(String(format: "%.1f", route.rating))
                                .font(ACTypography.captionSmall)
                                .foregroundColor(ACColors.textSecondary)
                        }
                    }
                }

                Text(route.neighborhood)
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)

                HStack(spacing: ACSpacing.md) {
                    ACMetaBadge(icon: "clock", text: route.durationFormatted)
                    ACMetaBadge(icon: "mappin", text: "\(route.numStops) paradas")
                    ACMetaBadge(icon: route.theme.icon, text: route.theme.displayName, color: route.theme.color)
                }

                // Popularidad
                if route.usageCount > 0 {
                    HStack(spacing: ACSpacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(route.usageCount) personas han hecho esta ruta")
                            .font(ACTypography.captionSmall)
                    }
                    .foregroundColor(ACColors.textTertiary)
                }
            }

            // Botón añadir/quitar
            Button(action: onToggle) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 28))
                    .foregroundColor(isAdded ? ACColors.success : ACColors.primary)
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.lg)
                .stroke(isAdded ? ACColors.success.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var routePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [ACColors.primary.opacity(0.8), ACColors.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "headphones")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(
                destinationCity: "Madrid",
                destinationCountry: "España",
                selectedRouteIds: ["route-1", "route-2"],
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3)
            ),
            tripService: TripService()
        )
    }
}
