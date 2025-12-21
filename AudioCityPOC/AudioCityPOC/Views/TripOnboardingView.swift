//
//  TripOnboardingView.swift
//  AudioCityPOC
//
//  Onboarding para planificar un nuevo viaje
//

import SwiftUI

struct TripOnboardingView: View {
    @ObservedObject var tripService: TripService
    @StateObject private var firebaseService = FirebaseService()
    @StateObject private var offlineCacheService = OfflineCacheService()

    let onComplete: (Trip?) -> Void

    @State private var currentStep = 0
    @State private var selectedDestination: Destination?
    @State private var availableRoutes: [Route] = []
    @State private var selectedRouteIds: Set<String> = []
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 3) // +3 días
    @State private var includeDates = true // Fechas siempre obligatorias
    @State private var downloadOffline = true
    @State private var isLoadingRoutes = false
    @State private var isCreatingTrip = false
    @State private var showDuplicateAlert = false
    @State private var destinationSearchText: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(ACSpacing.md)

                // Content
                TabView(selection: $currentStep) {
                    destinationStep.tag(0)
                    routesSelectionStep.tag(1)
                    optionsStep.tag(2)
                    summaryStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(ACSpacing.md)
            }
            .background(ACColors.background)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ACColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onComplete(nil) }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ACColors.textPrimary)
                    }
                }
            }
        }
        .tint(ACColors.primary)
        .onAppear {
            // Quitar la línea separadora de la barra de navegación
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(ACColors.background)
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance

            Task {
                await tripService.loadAvailableDestinations()
            }
        }
        .alert("Viaje duplicado", isPresented: $showDuplicateAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text("Ya tienes un viaje a este destino con las mismas fechas. Modifica las fechas o elige otro destino.")
        }
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index <= currentStep ? ACColors.primary : ACColors.borderLight)
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step Title
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Destino"
        case 1: return "Rutas"
        case 2: return "Opciones"
        case 3: return "Resumen"
        default: return "Planificar Viaje"
        }
    }

    // MARK: - Filtered Destinations
    private var filteredDestinations: [Destination] {
        if destinationSearchText.isEmpty {
            return tripService.availableDestinations
        }
        return tripService.availableDestinations.filter {
            $0.city.localizedCaseInsensitiveContains(destinationSearchText) ||
            $0.country.localizedCaseInsensitiveContains(destinationSearchText)
        }
    }

    private var popularDestinations: [Destination] {
        filteredDestinations.filter { $0.isPopular }
    }

    // MARK: - Step 1: Destination Selection
    private var destinationStep: some View {
        VStack(spacing: 0) {
            // Header fijo
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("¿A dónde viajas?")
                    .font(ACTypography.headlineLarge)
                    .foregroundColor(ACColors.textPrimary)

                Text("Selecciona tu destino para ver las rutas disponibles")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)

                // Buscador
                destinationSearchField
            }
            .padding(.horizontal, ACSpacing.containerPadding)
            .padding(.vertical, ACSpacing.md)

            // Lista scrollable
            if tripService.isLoading {
                Spacer()
                ProgressView()
                    .tint(ACColors.primary)
                Spacer()
            } else if tripService.availableDestinations.isEmpty {
                emptyDestinationsView
            } else if filteredDestinations.isEmpty {
                noSearchResultsView
            } else {
                ScrollView {
                    destinationsList
                        .padding(.bottom, ACSpacing.md)
                }
            }
        }
    }

    // MARK: - Destination Search Field
    private var destinationSearchField: some View {
        HStack(spacing: ACSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(ACColors.textTertiary)

            TextField("Buscar ciudad o país...", text: $destinationSearchText)
                .font(ACTypography.bodyMedium)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !destinationSearchText.isEmpty {
                Button(action: { destinationSearchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ACColors.textTertiary)
                }
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.lg)
                .stroke(ACColors.border, lineWidth: ACBorder.thin)
        )
    }

    private var noSearchResultsView: some View {
        VStack(spacing: ACSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(ACColors.textTertiary)

            Text("No hay resultados para \"\(destinationSearchText)\"")
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyDestinationsView: some View {
        VStack(spacing: ACSpacing.md) {
            Image(systemName: "map.fill")
                .font(.system(size: 50))
                .foregroundColor(ACColors.textTertiary)

            Text("No hay destinos disponibles")
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)

            Text("Pronto añadiremos más ciudades")
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }

    private var destinationsList: some View {
        LazyVStack(spacing: ACSpacing.sm) {
            // Destinos populares (solo si no hay búsqueda activa)
            if destinationSearchText.isEmpty && !popularDestinations.isEmpty {
                Text("Populares")
                    .font(ACTypography.headlineSmall)
                    .foregroundColor(ACColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ACSpacing.containerPadding)

                ForEach(popularDestinations) { destination in
                    DestinationCard(
                        destination: destination,
                        isSelected: selectedDestination?.id == destination.id
                    ) {
                        withAnimation(ACAnimation.spring) {
                            selectedDestination = destination
                            destinationSearchText = ""
                        }
                    }
                    .padding(.horizontal, ACSpacing.containerPadding)
                }

                // Separador
                Text(destinationSearchText.isEmpty ? "Todos los destinos" : "Resultados")
                    .font(ACTypography.headlineSmall)
                    .foregroundColor(ACColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ACSpacing.containerPadding)
                    .padding(.top, ACSpacing.sm)
            }

            // Lista filtrada (excluye populares si ya se mostraron)
            let destinationsToShow = destinationSearchText.isEmpty
                ? filteredDestinations.filter { !$0.isPopular }
                : filteredDestinations

            ForEach(destinationsToShow) { destination in
                DestinationCard(
                    destination: destination,
                    isSelected: selectedDestination?.id == destination.id
                ) {
                    withAnimation(ACAnimation.spring) {
                        selectedDestination = destination
                        destinationSearchText = ""
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    // MARK: - Step 2: Routes Selection
    private var routesSelectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ACSpacing.lg) {
                if let destination = selectedDestination {
                    Text("Rutas en \(destination.city)")
                        .font(ACTypography.headlineLarge)
                        .foregroundColor(ACColors.textPrimary)
                        .padding(.horizontal, ACSpacing.containerPadding)

                    Text("Selecciona las rutas que quieres hacer")
                        .font(ACTypography.bodyMedium)
                        .foregroundColor(ACColors.textSecondary)
                        .padding(.horizontal, ACSpacing.containerPadding)

                    if isLoadingRoutes {
                        ProgressView()
                            .tint(ACColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if availableRoutes.isEmpty {
                        Text("No hay rutas disponibles para este destino")
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Select all toggle
                        HStack {
                            Button(action: toggleSelectAll) {
                                HStack {
                                    Image(systemName: selectedRouteIds.count == availableRoutes.count ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(ACColors.primary)
                                    Text(selectedRouteIds.count == availableRoutes.count ? "Deseleccionar todas" : "Seleccionar todas")
                                        .font(ACTypography.bodyMedium)
                                        .foregroundColor(ACColors.textPrimary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            Text("\(selectedRouteIds.count) seleccionadas")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.textSecondary)
                        }
                        .padding(.horizontal, ACSpacing.containerPadding)

                        routesSelectionList
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            if let destination = selectedDestination {
                loadRoutes(for: destination.city)
            }
        }
        .onChange(of: selectedDestination) { oldValue, newValue in
            if let destination = newValue {
                loadRoutes(for: destination.city)
            }
        }
    }

    private var routesSelectionList: some View {
        LazyVStack(spacing: ACSpacing.sm) {
            ForEach(availableRoutes) { route in
                RouteSelectionCard(
                    route: route,
                    isSelected: selectedRouteIds.contains(route.id)
                ) {
                    toggleRoute(route.id)
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    private func toggleSelectAll() {
        if selectedRouteIds.count == availableRoutes.count {
            selectedRouteIds.removeAll()
        } else {
            selectedRouteIds = Set(availableRoutes.map { $0.id })
        }
    }

    private func toggleRoute(_ routeId: String) {
        if selectedRouteIds.contains(routeId) {
            selectedRouteIds.remove(routeId)
        } else {
            selectedRouteIds.insert(routeId)
        }
    }

    private func loadRoutes(for city: String) {
        isLoadingRoutes = true
        Task {
            do {
                let routes = try await firebaseService.fetchAllRoutes()
                await MainActor.run {
                    availableRoutes = routes.filter { $0.city.lowercased() == city.lowercased() }
                    isLoadingRoutes = false
                }
            } catch {
                await MainActor.run {
                    isLoadingRoutes = false
                }
            }
        }
    }

    // MARK: - Step 3: Options
    private var optionsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ACSpacing.xl) {
                Text("Opciones del viaje")
                    .font(ACTypography.headlineLarge)
                    .foregroundColor(ACColors.textPrimary)
                    .padding(.horizontal, ACSpacing.containerPadding)

                // Fechas (obligatorias)
                VStack(alignment: .leading, spacing: ACSpacing.md) {
                    HStack(spacing: ACSpacing.sm) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(ACColors.primary)

                        Text("Fechas del viaje")
                            .font(ACTypography.headlineSmall)
                            .foregroundColor(ACColors.textPrimary)
                    }
                    .padding(.horizontal, ACSpacing.containerPadding)

                    VStack(spacing: ACSpacing.sm) {
                        DatePicker("Fecha inicio", selection: $startDate, displayedComponents: .date)
                        DatePicker("Fecha fin", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    .tint(ACColors.primary)
                    .padding(ACSpacing.md)
                    .background(ACColors.surface)
                    .cornerRadius(ACRadius.lg)
                    .padding(.horizontal, ACSpacing.containerPadding)
                }

                // Offline
                VStack(alignment: .leading, spacing: ACSpacing.sm) {
                    Toggle(isOn: $downloadOffline) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(ACColors.success)
                            VStack(alignment: .leading) {
                                Text("Descargar para uso offline")
                                    .font(ACTypography.bodyMedium)
                                    .foregroundColor(ACColors.textPrimary)
                                Text("Guarda mapas y datos para usar sin conexión")
                                    .font(ACTypography.caption)
                                    .foregroundColor(ACColors.textSecondary)
                            }
                        }
                    }
                    .tint(ACColors.primary)
                    .padding(.horizontal, ACSpacing.containerPadding)

                    if downloadOffline {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(ACColors.info)
                            Text("Se descargarán aproximadamente \(estimatedDownloadSize) de datos")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.textSecondary)
                        }
                        .padding(.horizontal, ACSpacing.containerPadding)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var estimatedDownloadSize: String {
        // Estimación: ~60KB por ruta
        let sizePerRoute: Int64 = 60_000
        let totalSize = Int64(selectedRouteIds.count) * sizePerRoute
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    // MARK: - Step 4: Summary
    private var summaryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ACSpacing.xl) {
                Text("Resumen del viaje")
                    .font(ACTypography.headlineLarge)
                    .foregroundColor(ACColors.textPrimary)
                    .padding(.horizontal, ACSpacing.containerPadding)

                // Destino
                if let destination = selectedDestination {
                    SummaryCard(
                        icon: "mappin.circle.fill",
                        iconColor: ACColors.primary,
                        title: "Destino",
                        value: "\(destination.city), \(destination.country)"
                    )
                    .padding(.horizontal, ACSpacing.containerPadding)
                }

                // Rutas
                SummaryCard(
                    icon: "map.fill",
                    iconColor: ACColors.info,
                    title: "Rutas seleccionadas",
                    value: "\(selectedRouteIds.count) rutas"
                )
                .padding(.horizontal, ACSpacing.containerPadding)

                // Lista de rutas
                VStack(alignment: .leading, spacing: ACSpacing.sm) {
                    ForEach(availableRoutes.filter { selectedRouteIds.contains($0.id) }) { route in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ACColors.success)
                            Text(route.name)
                                .font(ACTypography.bodyMedium)
                                .foregroundColor(ACColors.textPrimary)
                            Spacer()
                            Text("\(route.durationMinutes) min")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.textSecondary)
                        }
                    }
                }
                .padding(ACSpacing.md)
                .background(ACColors.borderLight)
                .cornerRadius(ACRadius.lg)
                .padding(.horizontal, ACSpacing.containerPadding)

                // Fechas
                SummaryCard(
                    icon: "calendar",
                    iconColor: ACColors.primary,
                    title: "Fechas",
                    value: formatDateRange()
                )
                .padding(.horizontal, ACSpacing.containerPadding)

                // Offline
                SummaryCard(
                    icon: downloadOffline ? "arrow.down.circle.fill" : "wifi.slash",
                    iconColor: downloadOffline ? ACColors.success : ACColors.textTertiary,
                    title: "Modo offline",
                    value: downloadOffline ? "Activado (\(estimatedDownloadSize))" : "Desactivado"
                )
                .padding(.horizontal, ACSpacing.containerPadding)

                if isCreatingTrip {
                    ProgressView("Creando viaje...")
                        .tint(ACColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.vertical)
        }
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: ACSpacing.md) {
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Anterior")
                    }
                    .font(ACTypography.labelMedium)
                    .frame(maxWidth: .infinity)
                    .padding(ACSpacing.md)
                    .foregroundColor(ACColors.primary)
                    .background(
                        RoundedRectangle(cornerRadius: ACRadius.lg)
                            .stroke(ACColors.primary, lineWidth: ACBorder.thick)
                    )
                }
            }

            Button(action: handleNextAction) {
                HStack {
                    Text(currentStep == 3 ? "Crear Viaje" : "Siguiente")
                    if currentStep < 3 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(ACTypography.labelMedium)
                .frame(maxWidth: .infinity)
                .padding(ACSpacing.md)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: ACRadius.lg)
                        .fill(canProceed ? ACColors.primary : ACColors.textTertiary)
                )
            }
            .disabled(!canProceed || isCreatingTrip)
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return selectedDestination != nil
        case 1: return !selectedRouteIds.isEmpty
        case 2: return true
        case 3: return !isCreatingTrip
        default: return false
        }
    }

    private func handleNextAction() {
        if currentStep < 3 {
            currentStep += 1
        } else {
            createTrip()
        }
    }

    private func createTrip() {
        guard let destination = selectedDestination else { return }

        isCreatingTrip = true

        // Crear el viaje (devuelve nil si ya existe duplicado)
        guard var trip = tripService.createTrip(
            destinationCity: destination.city,
            destinationCountry: destination.country,
            startDate: startDate,
            endDate: endDate
        ) else {
            // Ya existe un viaje duplicado
            isCreatingTrip = false
            showDuplicateAlert = true
            return
        }

        // Añadir rutas seleccionadas
        for routeId in selectedRouteIds {
            tripService.addRoute(routeId, to: trip.id)
        }

        // Descargar para offline si está activado
        if downloadOffline {
            Task {
                let selectedRoutes = availableRoutes.filter { selectedRouteIds.contains($0.id) }

                // Cargar paradas de cada ruta
                var allStops: [[Stop]] = []
                for route in selectedRoutes {
                    if let stops = try? await firebaseService.fetchStops(for: route.id) {
                        allStops.append(stops)
                    } else {
                        allStops.append([])
                    }
                }

                // Actualizar trip con info
                if let index = tripService.trips.firstIndex(where: { $0.id == trip.id }) {
                    trip = tripService.trips[index]
                }

                try? await offlineCacheService.downloadTrip(trip, routes: selectedRoutes, stops: allStops)

                await MainActor.run {
                    tripService.markAsOfflineAvailable(trip.id, available: true)
                    isCreatingTrip = false
                    onComplete(trip)
                }
            }
        } else {
            isCreatingTrip = false
            onComplete(trip)
        }
    }
}

// MARK: - Destination Card
struct DestinationCard: View {
    let destination: Destination
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Icono
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(isSelected ? .white : ACColors.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? ACColors.primary : ACColors.primaryLight)
                    )

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    HStack {
                        Text(destination.city)
                            .font(ACTypography.headlineSmall)
                            .foregroundColor(ACColors.textPrimary)

                        if destination.isPopular {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(ACColors.warning)
                        }
                    }

                    Text("\(destination.routeCount) rutas disponibles")
                        .font(ACTypography.bodyMedium)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ACColors.primary)
                        .font(.title2)
                }
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.lg)
                    .stroke(isSelected ? ACColors.primary : Color.clear, lineWidth: ACBorder.thick)
            )
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Route Selection Card
struct RouteSelectionCard: View {
    let route: Route
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.sm) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ACColors.primary : ACColors.textTertiary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text(route.name)
                        .font(ACTypography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(ACColors.textPrimary)

                    HStack(spacing: ACSpacing.sm) {
                        Label("\(route.durationMinutes) min", systemImage: "clock")
                        Label("\(route.numStops) paradas", systemImage: "mappin")
                    }
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Text(route.difficulty.capitalized)
                    .font(ACTypography.captionSmall)
                    .foregroundColor(difficultyColor)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xxs)
                    .background(
                        Capsule().fill(difficultyColor.opacity(0.15))
                    )
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.lg)
                    .stroke(isSelected ? ACColors.primary : Color.clear, lineWidth: ACBorder.thick)
            )
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var difficultyColor: Color {
        switch route.difficulty.lowercased() {
        case "easy", "fácil": return ACColors.success
        case "medium", "media": return ACColors.warning
        case "hard", "difícil": return ACColors.error
        default: return ACColors.info
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)
                Text(value)
                    .font(ACTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(ACColors.textPrimary)
            }

            Spacer()
        }
        .padding(ACSpacing.md)
        .background(ACColors.borderLight)
        .cornerRadius(ACRadius.lg)
    }
}

#Preview {
    TripOnboardingView(tripService: TripService()) { _ in }
}
