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
    @State private var includeDates = false
    @State private var downloadOffline = true
    @State private var isLoadingRoutes = false
    @State private var isCreatingTrip = false
    @State private var showDuplicateAlert = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding()

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
                    .padding()
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        onComplete(nil)
                    }
                }
            }
        }
        .onAppear {
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
                    .fill(index <= currentStep ? Color.purple : Color.gray.opacity(0.3))
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

    // MARK: - Step 1: Destination Selection
    private var destinationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("¿A dónde viajas?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                Text("Selecciona tu destino para ver las rutas disponibles")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                if tripService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if tripService.availableDestinations.isEmpty {
                    emptyDestinationsView
                } else {
                    destinationsList
                }
            }
            .padding(.vertical)
        }
    }

    private var emptyDestinationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No hay destinos disponibles")
                .font(.headline)

            Text("Pronto añadiremos más ciudades")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }

    private var destinationsList: some View {
        LazyVStack(spacing: 12) {
            // Destinos populares
            if tripService.availableDestinations.contains(where: { $0.isPopular }) {
                Text("Populares")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ForEach(tripService.availableDestinations.filter { $0.isPopular }) { destination in
                    DestinationCard(
                        destination: destination,
                        isSelected: selectedDestination?.id == destination.id
                    ) {
                        selectedDestination = destination
                    }
                    .padding(.horizontal)
                }
            }

            // Todos los destinos
            Text("Todos los destinos")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            ForEach(tripService.availableDestinations) { destination in
                DestinationCard(
                    destination: destination,
                    isSelected: selectedDestination?.id == destination.id
                ) {
                    selectedDestination = destination
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Step 2: Routes Selection
    private var routesSelectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let destination = selectedDestination {
                    Text("Rutas en \(destination.city)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("Selecciona las rutas que quieres hacer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if isLoadingRoutes {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if availableRoutes.isEmpty {
                        Text("No hay rutas disponibles para este destino")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Select all toggle
                        HStack {
                            Button(action: toggleSelectAll) {
                                HStack {
                                    Image(systemName: selectedRouteIds.count == availableRoutes.count ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.purple)
                                    Text(selectedRouteIds.count == availableRoutes.count ? "Deseleccionar todas" : "Seleccionar todas")
                                        .font(.subheadline)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Spacer()

                            Text("\(selectedRouteIds.count) seleccionadas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

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
        LazyVStack(spacing: 12) {
            ForEach(availableRoutes) { route in
                RouteSelectionCard(
                    route: route,
                    isSelected: selectedRouteIds.contains(route.id)
                ) {
                    toggleRoute(route.id)
                }
                .padding(.horizontal)
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Opciones del viaje")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                // Fechas
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: { includeDates.toggle() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(includeDates ? Color.purple : Color.gray)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fechas del viaje")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text(includeDates ? "Toca para quitar fechas" : "Toca para añadir fechas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if includeDates {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    if includeDates {
                        VStack(spacing: 12) {
                            DatePicker("Fecha inicio", selection: $startDate, displayedComponents: .date)
                            DatePicker("Fecha fin", selection: $endDate, in: startDate..., displayedComponents: .date)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Offline
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $downloadOffline) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Descargar para uso offline")
                                Text("Guarda mapas y datos para usar sin conexión")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if downloadOffline {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Se descargarán aproximadamente \(estimatedDownloadSize) de datos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Resumen del viaje")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                // Destino
                if let destination = selectedDestination {
                    SummaryCard(
                        icon: "mappin.circle.fill",
                        iconColor: .purple,
                        title: "Destino",
                        value: "\(destination.city), \(destination.country)"
                    )
                    .padding(.horizontal)
                }

                // Rutas
                SummaryCard(
                    icon: "map.fill",
                    iconColor: .blue,
                    title: "Rutas seleccionadas",
                    value: "\(selectedRouteIds.count) rutas"
                )
                .padding(.horizontal)

                // Lista de rutas
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(availableRoutes.filter { selectedRouteIds.contains($0.id) }) { route in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(route.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(route.durationMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)

                // Fechas
                if includeDates {
                    SummaryCard(
                        icon: "calendar",
                        iconColor: .orange,
                        title: "Fechas",
                        value: formatDateRange()
                    )
                    .padding(.horizontal)
                }

                // Offline
                SummaryCard(
                    icon: downloadOffline ? "arrow.down.circle.fill" : "wifi.slash",
                    iconColor: downloadOffline ? .green : .gray,
                    title: "Modo offline",
                    value: downloadOffline ? "Activado (\(estimatedDownloadSize))" : "Desactivado"
                )
                .padding(.horizontal)

                if isCreatingTrip {
                    ProgressView("Creando viaje...")
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
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Anterior")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
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
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canProceed ? Color.purple : Color.gray)
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
            startDate: includeDates ? startDate : nil,
            endDate: includeDates ? endDate : nil
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
            HStack(spacing: 16) {
                // Icono
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.purple : Color.purple.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(destination.city)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if destination.isPopular {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Text("\(destination.routeCount) rutas disponibles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
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
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label("\(route.durationMinutes) min", systemImage: "clock")
                        Label("\(route.numStops) paradas", systemImage: "mappin")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Text(route.difficulty.capitalized)
                    .font(.caption2)
                    .foregroundColor(difficultyColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(difficultyColor.opacity(0.15))
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Summary Card
struct SummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    TripOnboardingView(tripService: TripService()) { _ in }
}
