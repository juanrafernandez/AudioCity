//
//  RoutesListView.swift
//  AudioCityPOC
//
//  Vista principal de rutas con secciones estilo moderno
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct RoutesListView: View {
    // Support for both standalone and shared viewModel modes
    @ObservedObject private var viewModel: RouteViewModel
    @ObservedObject private var exploreViewModel = ExploreViewModel.shared
    @ObservedObject private var tripService = TripService.shared
    @StateObject private var favoritesService = FavoritesService()
    @State private var selectedCity: String = ""
    @State private var userLocation: CLLocation?
    @State private var selectedTrip: Trip?

    // Callbacks para manejar la optimización a nivel global (MainTabView)
    var onRouteStarted: (() -> Void)?
    var onShowOptimizeSheet: (((name: String, distance: Int, originalOrder: Int)?) -> Void)?
    var onStartRouteDirectly: (() -> Void)?

    // Inicializador por defecto (standalone)
    init() {
        self._viewModel = ObservedObject(wrappedValue: RouteViewModel())
        self.onRouteStarted = nil
        self.onShowOptimizeSheet = nil
        self.onStartRouteDirectly = nil
    }

    // Inicializador con viewModel compartido
    init(sharedViewModel: RouteViewModel,
         onRouteStarted: (() -> Void)? = nil,
         onShowOptimizeSheet: (((name: String, distance: Int, originalOrder: Int)?) -> Void)? = nil,
         onStartRouteDirectly: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: sharedViewModel)
        self.onRouteStarted = onRouteStarted
        self.onShowOptimizeSheet = onShowOptimizeSheet
        self.onStartRouteDirectly = onStartRouteDirectly
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.currentRoute != nil && !viewModel.isRouteActive {
                    routeDetailView
                } else {
                    mainContent
                }
            }
            .navigationTitle(viewModel.currentRoute?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.currentRoute != nil && !viewModel.isRouteActive {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.backToRoutesList()
                        }) {
                            HStack(spacing: ACSpacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Rutas")
                            }
                            .foregroundColor(ACColors.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.availableRoutes.isEmpty {
                viewModel.loadAvailableRoutes()
            }
            // Obtener ubicación única para ordenar rutas por proximidad
            // NO iniciamos tracking continuo aquí - solo cuando se inicia una ruta
            if let location = exploreViewModel.locationService.userLocation {
                userLocation = location
            } else {
                exploreViewModel.locationService.requestSingleLocation { location in
                    userLocation = location
                }
            }
        }
        .onReceive(exploreViewModel.locationService.$userLocation) { location in
            if let location = location, userLocation == nil {
                userLocation = location
            }
        }
        .fullScreenCover(item: $selectedTrip) { trip in
            NavigationStack {
                TripDetailView(trip: trip, tripService: tripService)
            }
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoadingRoutes {
            ACLoadingState(message: "Cargando rutas...")
        } else if viewModel.availableRoutes.isEmpty {
            if let error = viewModel.errorMessage {
                ACErrorState(
                    title: "Error de conexión",
                    description: error,
                    retryAction: { viewModel.loadAvailableRoutes() }
                )
            } else {
                ACEmptyState(
                    icon: "map",
                    title: "No hay rutas disponibles",
                    description: "Pronto añadiremos nuevas rutas en tu ciudad",
                    actionTitle: "Reintentar",
                    action: { viewModel.loadAvailableRoutes() }
                )
            }
        } else {
            routesSectionsView
        }
    }

    // MARK: - Routes Sections View
    private var routesSectionsView: some View {
        ScrollView {
            VStack(spacing: ACSpacing.sectionSpacing) {
                // Próximo viaje (si hay)
                if let nextTrip = nextUpcomingTrip {
                    nextTripSection(nextTrip)
                        .padding(.horizontal, ACSpacing.containerPadding)
                }

                // Buscador de ciudad
                ACCitySearchField(
                    selectedCity: $selectedCity,
                    availableCities: availableCities,
                    nearestCity: nearestCity
                ) { city in
                    selectedCity = city
                }
                .padding(.horizontal, ACSpacing.containerPadding)

                // Rutas Favoritas (si hay para esta ciudad)
                if !favoriteRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Tus Favoritas",
                        icon: "heart.fill",
                        iconColor: ACColors.primary,
                        routes: favoriteRoutes
                    )
                }

                // Top Rutas (por usageCount)
                if !topRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Top Rutas",
                        icon: "star.fill",
                        iconColor: ACColors.gold,
                        routes: topRoutes
                    )
                }

                // Secciones por temática
                ForEach(routesByTheme, id: \.0) { theme, routes in
                    ACThemeSection(
                        theme: theme,
                        routes: routes
                    ) { route in
                        viewModel.selectRoute(route)
                    }
                }

                // Empty state si no hay rutas en esta ciudad
                if cityFilteredRoutes.isEmpty && !effectiveCity.isEmpty {
                    VStack(spacing: ACSpacing.md) {
                        Image(systemName: "map")
                            .font(.system(size: 48))
                            .foregroundColor(ACColors.textTertiary)
                        Text("No hay rutas en \(effectiveCity)")
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textSecondary)
                        Text("Prueba a seleccionar otra ciudad")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ACSpacing.xxl)
                }

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.base)
        }
        .background(ACColors.background)
    }

    // MARK: - Horizontal Section
    private func routeSectionHorizontal(
        title: String,
        icon: String,
        iconColor: Color,
        routes: [Route]
    ) -> some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)
                Text("\(routes.count)")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textTertiary)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xxs)
                    .background(ACColors.borderLight)
                    .cornerRadius(ACRadius.full)
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.md) {
                    ForEach(routes) { route in
                        ACCompactRouteCard(
                            title: route.name,
                            subtitle: route.neighborhood,
                            duration: route.durationFormatted,
                            stopsCount: route.numStops,
                            thumbnailUrl: route.thumbnailUrl.isEmpty ? nil : route.thumbnailUrl,
                            onTap: { viewModel.selectRoute(route) }
                        )
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    // MARK: - Computed Properties

    /// Ciudades disponibles (de las rutas cargadas)
    private var availableCities: [String] {
        Array(Set(viewModel.availableRoutes.map { $0.city })).sorted()
    }

    /// Ciudad más cercana según ubicación del usuario
    private var nearestCity: String? {
        guard let location = userLocation else { return nil }
        return viewModel.availableRoutes
            .min { route1, route2 in
                let d1 = location.distance(from: route1.startLocation.clLocation)
                let d2 = location.distance(from: route2.startLocation.clLocation)
                return d1 < d2
            }?.city
    }

    /// Ciudad efectiva (seleccionada o más cercana)
    private var effectiveCity: String {
        if !selectedCity.isEmpty {
            return selectedCity
        }
        return nearestCity ?? availableCities.first ?? ""
    }

    /// Rutas filtradas por ciudad
    private var cityFilteredRoutes: [Route] {
        guard !effectiveCity.isEmpty else { return viewModel.availableRoutes }
        return viewModel.availableRoutes.filter { $0.city == effectiveCity }
    }

    /// Favoritas para la ciudad, ordenadas por rating
    private var favoriteRoutes: [Route] {
        favoritesService.filterFavorites(from: cityFilteredRoutes)
            .sorted { $0.rating > $1.rating }
    }

    /// Top rutas por número de usos
    private var topRoutes: [Route] {
        cityFilteredRoutes
            .filter { !favoritesService.isFavorite($0.id) }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(5)
            .map { $0 }
    }

    /// Rutas agrupadas por temática (excluyendo favoritas y top)
    private var routesByTheme: [(RouteTheme, [Route])] {
        let remaining = cityFilteredRoutes.filter { route in
            !favoritesService.isFavorite(route.id) &&
            !topRoutes.contains { $0.id == route.id }
        }

        let grouped = Dictionary(grouping: remaining) { $0.theme }

        return RouteTheme.allCases.compactMap { theme in
            guard let routes = grouped[theme], !routes.isEmpty else { return nil }
            return (theme, routes.sorted { $0.rating > $1.rating })
        }
    }

    /// Próximo viaje (actual si existe, o el siguiente en el calendario)
    private var nextUpcomingTrip: Trip? {
        // Primero buscar viaje activo/actual
        if let currentTrip = tripService.trips.first(where: { $0.isCurrent }) {
            return currentTrip
        }
        // Si no hay actual, buscar el próximo en el futuro
        return tripService.trips
            .filter { !$0.isPast && !$0.isCurrent }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
            .first
    }

    // MARK: - Next Trip Section

    private func nextTripSection(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: trip.isCurrent ? "location.fill" : "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(trip.isCurrent ? ACColors.success : ACColors.secondary)

                Text(trip.isCurrent ? "Viaje activo" : "Próximo viaje")
                    .font(ACTypography.headlineSmall)
                    .foregroundColor(ACColors.textPrimary)
            }

            // Card con borde destacado
            Button(action: { selectedTrip = trip }) {
                HStack(spacing: ACSpacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: ACRadius.md)
                            .fill(trip.isCurrent ? ACColors.successLight : ACColors.secondaryLight)
                            .frame(width: 56, height: 56)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(trip.isCurrent ? ACColors.success : ACColors.secondary)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        HStack {
                            Text(trip.destinationCity)
                                .font(ACTypography.titleMedium)
                                .foregroundColor(ACColors.textPrimary)

                            if trip.isCurrent {
                                ACStatusBadge(text: "Ahora", status: .active)
                            }
                        }

                        HStack(spacing: ACSpacing.md) {
                            ACMetaBadge(icon: "map", text: "\(trip.routeCount) rutas")

                            if trip.isOfflineAvailable {
                                ACMetaBadge(icon: "arrow.down.circle.fill", text: "Offline", color: ACColors.success)
                            }

                            if let dateRange = trip.dateRangeFormatted {
                                ACMetaBadge(icon: "calendar", text: dateRange)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(ACColors.textTertiary)
                }
                .padding(ACSpacing.md)
                .background(ACColors.surface)
                .cornerRadius(ACRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ACRadius.lg)
                        .stroke(trip.isCurrent ? ACColors.success : ACColors.secondary, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }

    // MARK: - Route Detail View
    @ViewBuilder
    private var routeDetailView: some View {
        if viewModel.isLoading {
            ACLoadingState(message: "Cargando detalles...")
        } else if let route = viewModel.currentRoute {
            RouteDetailContentV2(
                route: route,
                viewModel: viewModel,
                onShowOptimizeSheet: onShowOptimizeSheet,
                onStartRouteDirectly: onStartRouteDirectly
            )
        }
    }
}

// MARK: - Route Detail Content V2
struct RouteDetailContentV2: View {
    let route: Route
    @ObservedObject var viewModel: RouteViewModel
    var onShowOptimizeSheet: (((name: String, distance: Int, originalOrder: Int)?) -> Void)?
    var onStartRouteDirectly: (() -> Void)?
    @State private var isCheckingLocation = false
    @State private var showActiveRouteAlert = false
    @StateObject private var distanceCalculator = RouteDistanceCalculator()
    @ObservedObject private var audioPreviewService = AudioPreviewService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: ACSpacing.xl) {
                // Hero
                routeHero

                // Stats
                routeStats

                // Stops
                stopsSection

                // Start Button
                ACButton(
                    isCheckingLocation ? "Obteniendo ubicación..." : "Iniciar Ruta",
                    icon: isCheckingLocation ? nil : "play.fill",
                    style: .primary,
                    size: .large,
                    isLoading: isCheckingLocation,
                    isFullWidth: true
                ) {
                    // Verificar si hay una ruta activa
                    if viewModel.isRouteActive {
                        showActiveRouteAlert = true
                    } else {
                        handleStartRoute()
                    }
                }
                .disabled(isCheckingLocation)
                .padding(.horizontal, ACSpacing.containerPadding)
                .alert("Ruta en curso", isPresented: $showActiveRouteAlert) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Parar e iniciar nueva", role: .destructive) {
                        // Detener la ruta actual
                        viewModel.endRoute()
                        // Detener audio de preview
                        audioPreviewService.stop()
                        // Iniciar la nueva ruta
                        handleStartRoute()
                    }
                } message: {
                    Text("Ya tienes una ruta en marcha. ¿Quieres pararla e iniciar esta nueva ruta?")
                }

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.lg)
        }
        .background(ACColors.background)
        .onAppear {
            // Calcular distancias reales cuando carguen las paradas
            if !viewModel.stops.isEmpty {
                let coords = viewModel.stops.sorted { $0.order < $1.order }.map { $0.coordinate }
                distanceCalculator.calculateTotalDistance(through: coords)
            }
        }
        .onDisappear {
            // Detener audio de preview cuando se sale de la pantalla
            audioPreviewService.stop()
        }
        .onChange(of: viewModel.stops.count) { _, count in
            if count > 0 {
                let coords = viewModel.stops.sorted { $0.order < $1.order }.map { $0.coordinate }
                distanceCalculator.calculateTotalDistance(through: coords)
            }
        }
    }

    private func handleStartRoute() {
        isCheckingLocation = true

        // Solicitar ubicación actual antes de verificar optimización
        viewModel.requestCurrentLocation { location in
            isCheckingLocation = false

            guard let userLocation = location else {
                // Sin ubicación, iniciar directamente sin optimizar
                Log("No se pudo obtener ubicación, iniciando sin optimización", level: .warning, category: .location)
                onStartRouteDirectly?()
                viewModel.startRoute(optimized: false)
                return
            }

            // Verificar si conviene sugerir optimización
            if viewModel.shouldSuggestRouteOptimization(userLocation: userLocation) {
                let stopInfo = viewModel.getNearestStopInfo(userLocation: userLocation)
                onShowOptimizeSheet?(stopInfo)
            } else {
                // El punto más cercano ya es el primero, iniciar directamente
                onStartRouteDirectly?()
                viewModel.startRoute(optimized: false)
            }
        }
    }

    private var routeHero: some View {
        VStack(spacing: ACSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "headphones")
                    .font(.system(size: 40))
                    .foregroundColor(ACColors.primary)
            }

            // Title
            Text(route.name)
                .font(ACTypography.displaySmall)
                .foregroundColor(ACColors.textPrimary)
                .multilineTextAlignment(.center)

            // Location
            HStack(spacing: ACSpacing.xs) {
                Image(systemName: "mappin")
                    .font(.system(size: 12))
                Text("\(route.neighborhood), \(route.city)")
                    .font(ACTypography.bodyMedium)
            }
            .foregroundColor(ACColors.textSecondary)

            // Description
            Text(route.description)
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ACSpacing.xl)
        }
        .padding(.horizontal, ACSpacing.containerPadding)
    }

    private var routeStats: some View {
        HStack(spacing: ACSpacing.md) {
            ACETACard(
                value: distanceCalculator.isCalculating ? "--" : "\(distanceCalculator.estimatedMinutes)",
                unit: "min",
                label: "Duración",
                icon: "clock.fill",
                color: ACColors.primary
            )
            ACETACard(
                value: distanceCalculator.isCalculating ? "--" : distanceCalculator.formattedDistance,
                unit: distanceCalculator.isCalculating ? "" : distanceCalculator.distanceUnit,
                label: "Distancia",
                icon: "figure.walk",
                color: ACColors.secondary
            )
            ACETACard(
                value: "\(viewModel.stops.count)",
                unit: "",
                label: "Paradas",
                icon: "mappin.circle.fill",
                color: ACColors.info
            )
        }
        .padding(.horizontal, ACSpacing.containerPadding)
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            ACSectionHeader(title: "Paradas de la ruta")
                .padding(.horizontal, ACSpacing.containerPadding)

            VStack(spacing: 0) {
                let sortedStops = viewModel.stops.sorted { $0.order < $1.order }
                ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                    let isLast = index == sortedStops.count - 1
                    StopRowV2(
                        stop: stop,
                        number: index + 1,
                        isVisited: stop.hasBeenVisited,
                        distanceToNext: isLast ? nil : distanceCalculator.formattedSegmentDistance(at: index)
                    )
                }
            }
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }
}

// MARK: - Stop Row V2
struct StopRowV2: View {
    let stop: Stop
    let number: Int
    let isVisited: Bool
    var distanceToNext: String? = nil
    @ObservedObject private var audioPreviewService = AudioPreviewService.shared

    /// Indica si este stop es el que se está reproduciendo actualmente
    private var isCurrentlyPlaying: Bool {
        audioPreviewService.isPlayingStop(stop.id)
    }

    /// Indica si este stop está pausado
    private var isCurrentlyPaused: Bool {
        audioPreviewService.isPausedStop(stop.id)
    }

    /// Indica si este stop tiene audio activo (reproduciendo o pausado)
    private var hasActiveAudio: Bool {
        isCurrentlyPlaying || isCurrentlyPaused
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: handleAudioTap) {
                HStack(spacing: ACSpacing.md) {
                    // Number badge
                    ZStack {
                        Circle()
                            .fill(isVisited ? ACColors.success : ACColors.primary)
                            .frame(width: 32, height: 32)

                        if isVisited {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(number)")
                                .font(ACTypography.labelSmall)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                        Text(stop.name)
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textPrimary)

                        if !stop.description.isEmpty {
                            Text(stop.description)
                                .font(ACTypography.bodySmall)
                                .foregroundColor(ACColors.textSecondary)
                                .lineLimit(2)
                        }

                        // Indicador de estado de reproducción
                        if hasActiveAudio {
                            HStack(spacing: ACSpacing.xs) {
                                if isCurrentlyPlaying {
                                    // Barras de audio animadas
                                    HStack(spacing: 2) {
                                        ForEach(0..<3, id: \.self) { index in
                                            AudioWaveBar(delay: Double(index) * 0.15)
                                        }
                                    }
                                    .frame(width: 20)

                                    Text("Reproduciendo...")
                                        .font(ACTypography.captionSmall)
                                        .foregroundColor(ACColors.primary)
                                } else {
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(ACColors.warning)

                                    Text("En pausa")
                                        .font(ACTypography.captionSmall)
                                        .foregroundColor(ACColors.warning)
                                }
                            }
                            .padding(.top, ACSpacing.xxs)
                        }
                    }

                    Spacer()

                    // Audio button
                    audioButton
                }
                .padding(ACSpacing.md)
                .background(hasActiveAudio ? ACColors.primaryLight : ACColors.surface)
                .cornerRadius(ACRadius.md)
                .acShadow(ACShadow.sm)
            }
            .buttonStyle(PlainButtonStyle())

            // Distance to next stop
            if let distance = distanceToNext {
                HStack(spacing: ACSpacing.xs) {
                    Rectangle()
                        .fill(ACColors.border)
                        .frame(width: 2, height: 20)
                        .padding(.leading, 15)

                    HStack(spacing: ACSpacing.xxs) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                        Text(distance)
                            .font(ACTypography.captionSmall)
                    }
                    .foregroundColor(ACColors.textTertiary)

                    Spacer()
                }
                .padding(.vertical, ACSpacing.xs)
            }
        }
    }

    // MARK: - Audio Button

    @ViewBuilder
    private var audioButton: some View {
        ZStack {
            Circle()
                .fill(audioButtonBackground)
                .frame(width: 44, height: 44)

            if isCurrentlyPlaying {
                // Botón de pausa cuando está reproduciendo
                Image(systemName: "pause.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            } else if isCurrentlyPaused {
                // Botón de play cuando está pausado
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            } else {
                // Icono de cascos cuando no hay audio activo
                Image(systemName: "headphones")
                    .font(.system(size: 16))
                    .foregroundColor(ACColors.textTertiary)
            }
        }
    }

    private var audioButtonBackground: Color {
        if isCurrentlyPlaying {
            return ACColors.primary
        } else if isCurrentlyPaused {
            return ACColors.warning
        } else {
            return ACColors.borderLight
        }
    }

    // MARK: - Actions

    private func handleAudioTap() {
        if isCurrentlyPlaying {
            // Pausar
            audioPreviewService.pause()
        } else if isCurrentlyPaused {
            // Reanudar
            audioPreviewService.resume()
        } else {
            // Iniciar reproducción de preview de este stop
            let textToPlay = stop.scriptEs.isEmpty ? stop.description : stop.scriptEs
            if !textToPlay.isEmpty {
                audioPreviewService.playPreview(stopId: stop.id, text: textToPlay)
            }
        }
    }
}

// MARK: - Route Distance Calculator

class RouteDistanceCalculator: ObservableObject {
    @Published var totalDistance: CLLocationDistance = 0
    @Published var segmentDistances: [CLLocationDistance] = []
    @Published var isCalculating = false

    var formattedDistance: String {
        if totalDistance < 1000 {
            return "\(Int(totalDistance))"
        } else {
            return String(format: "%.1f", totalDistance / 1000)
        }
    }

    var distanceUnit: String {
        totalDistance < 1000 ? "m" : "km"
    }

    /// Tiempo estimado caminando (5 km/h = 83.3 m/min)
    var estimatedMinutes: Int {
        Int(totalDistance / 83.3)
    }

    func calculateTotalDistance(through stops: [CLLocationCoordinate2D]) {
        guard stops.count >= 2 else {
            totalDistance = 0
            segmentDistances = []
            return
        }

        isCalculating = true
        segmentDistances = Array(repeating: 0, count: stops.count - 1)

        var completedSegments = 0
        let totalSegments = stops.count - 1

        for i in 0..<totalSegments {
            calculateSegment(from: stops[i], to: stops[i + 1], index: i) { distance in
                DispatchQueue.main.async {
                    self.segmentDistances[i] = distance
                    completedSegments += 1

                    if completedSegments == totalSegments {
                        self.totalDistance = self.segmentDistances.reduce(0, +)
                        self.isCalculating = false
                        Log("Distancia total calculada: \(self.formattedDistance) \(self.distanceUnit)", level: .debug, category: .route)
                    }
                }
            }
        }
    }

    private func calculateSegment(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, index: Int, completion: @escaping (CLLocationDistance) -> Void) {
        let request = MKDirections.Request()
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                completion(route.distance)
            } else {
                // Fallback: distancia euclidiana
                completion(originLocation.distance(from: destLocation))
            }
        }
    }

    func formattedSegmentDistance(at index: Int) -> String? {
        guard index < segmentDistances.count else { return nil }
        let distance = segmentDistances[index]
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

#Preview {
    RoutesListView()
}
