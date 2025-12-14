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
    @ObservedObject private var tripService = TripService.shared
    @ObservedObject private var exploreViewModel = ExploreViewModel.shared
    @StateObject private var favoritesService = FavoritesService()
    @State private var showingTripOnboarding = false
    @State private var showingAllRoutes = false
    @State private var showingAllTrips = false
    @State private var selectedTrip: Trip?
    @State private var userLocation: CLLocation?

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
            .navigationTitle(viewModel.currentRoute?.name ?? "Rutas")
            .navigationBarTitleDisplayMode(.large)
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
            // Obtener ubicación actual para ordenar por proximidad
            userLocation = exploreViewModel.locationService.userLocation
            if userLocation == nil {
                exploreViewModel.locationService.requestSingleLocation { location in
                    userLocation = location
                }
            }
            // Iniciar tracking de ubicación para que esté disponible al iniciar ruta
            if viewModel.locationService.authorizationStatus == .authorizedWhenInUse ||
               viewModel.locationService.authorizationStatus == .authorizedAlways {
                viewModel.locationService.startTracking()
            }
        }
        .onReceive(exploreViewModel.locationService.$userLocation) { location in
            if let location = location, userLocation == nil {
                userLocation = location
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
        .sheet(isPresented: $showingAllTrips) {
            AllTripsView(tripService: tripService)
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip, tripService: tripService)
        }
        // El callback onRouteStarted ahora se llama desde RouteDetailContentV2
        // después de cerrar el sheet de optimización
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
                // Mis Viajes Section
                myTripsSection
                    .padding(.horizontal, ACSpacing.containerPadding)

                // Rutas Favoritas (horizontal scroll)
                if !favoriteRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Tus Favoritas",
                        icon: "heart.fill",
                        iconColor: ACColors.primary,
                        routes: favoriteRoutes
                    )
                }

                // Top Rutas (horizontal scroll)
                if !topRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Top Rutas",
                        icon: "star.fill",
                        iconColor: ACColors.gold,
                        routes: topRoutes
                    )
                }

                // Rutas de Moda (horizontal scroll)
                if !trendingRoutes.isEmpty {
                    routeSectionHorizontal(
                        title: "Populares",
                        icon: "flame.fill",
                        iconColor: ACColors.warning,
                        routes: trendingRoutes
                    )
                }

                // Botón Todas las Rutas
                allRoutesButton
                    .padding(.horizontal, ACSpacing.containerPadding)

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.base)
        }
        .background(ACColors.background)
    }

    // MARK: - My Trips Section
    private var upcomingTrips: [Trip] {
        tripService.trips
            .filter { !$0.isPast }
            .sorted { trip1, trip2 in
                if trip1.isCurrent != trip2.isCurrent {
                    return trip1.isCurrent
                }
                return (trip1.startDate ?? .distantFuture) < (trip2.startDate ?? .distantFuture)
            }
    }

    private var totalTripsCount: Int { tripService.trips.count }
    private var visibleTrips: [Trip] { Array(upcomingTrips.prefix(2)) }

    private var myTripsSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: ACSpacing.sm) {
                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ACColors.secondary)

                    Text("Mis Viajes")
                        .font(ACTypography.headlineMedium)
                        .foregroundColor(ACColors.textPrimary)

                    if totalTripsCount > 0 {
                        Text("\(visibleTrips.count)/\(totalTripsCount)")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                    }
                }

                Spacer()

                ACButton("Planificar", icon: "plus", style: .primary, size: .small) {
                    showingTripOnboarding = true
                }
            }

            // Content
            if tripService.trips.isEmpty {
                emptyTripsCard
            } else {
                VStack(spacing: ACSpacing.sm) {
                    ForEach(visibleTrips) { trip in
                        TripCardV2(trip: trip) {
                            selectedTrip = trip
                        }
                    }

                    if totalTripsCount > 2 {
                        Button(action: { showingAllTrips = true }) {
                            HStack(spacing: ACSpacing.xs) {
                                Text("Ver todos los viajes")
                                    .font(ACTypography.labelMedium)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(ACColors.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ACSpacing.sm)
                        }
                    }
                }
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }

    private var emptyTripsCard: some View {
        Button(action: { showingTripOnboarding = true }) {
            HStack(spacing: ACSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ACColors.secondaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 20))
                        .foregroundColor(ACColors.secondary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Planifica tu primer viaje")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)

                    Text("Selecciona destino y rutas para tenerlas offline")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ACRadius.md)
                    .stroke(ACColors.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
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
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack {
                HStack(spacing: ACSpacing.sm) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(ACTypography.headlineMedium)
                        .foregroundColor(ACColors.textPrimary)
                }

                Spacer()

                Button(action: { showingAllRoutes = true }) {
                    HStack(spacing: ACSpacing.xxs) {
                        Text("Ver todas")
                            .font(ACTypography.labelSmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(ACColors.primary)
                }
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.md) {
                    ForEach(routes) { route in
                        ACCompactRouteCard(
                            title: route.name,
                            subtitle: route.city,
                            duration: "\(route.durationMinutes) min",
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

    // MARK: - All Routes Button
    private var allRoutesButton: some View {
        Button(action: { showingAllRoutes = true }) {
            HStack(spacing: ACSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ACColors.primaryLight)
                        .frame(width: 44, height: 44)

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(ACColors.primary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Explorar todas las rutas")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)

                    Text("\(viewModel.availableRoutes.count) rutas con buscador y filtros")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.cardPadding)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    /// Ordena rutas por proximidad a la ubicación del usuario
    private func sortByProximity(_ routes: [Route]) -> [Route] {
        guard let location = userLocation else { return routes }

        return routes.sorted { route1, route2 in
            let distance1 = location.distance(from: CLLocation(
                latitude: route1.startLocation.latitude,
                longitude: route1.startLocation.longitude
            ))
            let distance2 = location.distance(from: CLLocation(
                latitude: route2.startLocation.latitude,
                longitude: route2.startLocation.longitude
            ))
            return distance1 < distance2
        }
    }

    private var favoriteRoutes: [Route] {
        sortByProximity(favoritesService.filterFavorites(from: viewModel.availableRoutes))
    }

    private var topRoutes: [Route] {
        let filtered = viewModel.availableRoutes
            .filter { !favoritesService.isFavorite($0.id) }
        return Array(sortByProximity(filtered).prefix(5))
    }

    private var trendingRoutes: [Route] {
        [
            Route(
                id: "mock-tapas-lavapies",
                name: "Ruta de la Tapa por Lavapiés",
                description: "Descubre los mejores bares de tapas del barrio más multicultural",
                city: "Madrid",
                neighborhood: "Lavapiés",
                durationMinutes: 90,
                distanceKm: 2.5,
                difficulty: "Fácil",
                numStops: 8,
                language: "es",
                isActive: true,
                createdAt: "",
                updatedAt: "",
                thumbnailUrl: "",
                startLocation: Route.Location(latitude: 40.4093, longitude: -3.7010, name: "Plaza Lavapiés"),
                endLocation: Route.Location(latitude: 40.4093, longitude: -3.7010, name: "Plaza Lavapiés")
            ),
            Route(
                id: "mock-navidad-madrid",
                name: "Ruta de Navidad",
                description: "Luces, belenes y mercadillos navideños",
                city: "Madrid",
                neighborhood: "Centro",
                durationMinutes: 120,
                distanceKm: 4.0,
                difficulty: "Fácil",
                numStops: 10,
                language: "es",
                isActive: true,
                createdAt: "",
                updatedAt: "",
                thumbnailUrl: "",
                startLocation: Route.Location(latitude: 40.4168, longitude: -3.7038, name: "Puerta del Sol"),
                endLocation: Route.Location(latitude: 40.4153, longitude: -3.7074, name: "Plaza Mayor")
            ),
            Route(
                id: "mock-blackfriday",
                name: "Ruta Black Friday",
                description: "Las mejores tiendas y outlets",
                city: "Madrid",
                neighborhood: "Salamanca",
                durationMinutes: 150,
                distanceKm: 3.5,
                difficulty: "Media",
                numStops: 12,
                language: "es",
                isActive: true,
                createdAt: "",
                updatedAt: "",
                thumbnailUrl: "",
                startLocation: Route.Location(latitude: 40.4260, longitude: -3.6833, name: "Serrano"),
                endLocation: Route.Location(latitude: 40.4230, longitude: -3.6900, name: "Goya")
            )
        ]
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

// MARK: - Trip Card V2
struct TripCardV2: View {
    let trip: Trip
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .fill(ACColors.secondaryLight)
                        .frame(width: 56, height: 56)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ACColors.secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    HStack {
                        Text(trip.destinationCity)
                            .font(ACTypography.titleMedium)
                            .foregroundColor(ACColors.textPrimary)

                        if trip.isCurrent {
                            ACStatusBadge(text: "Activo", status: .active)
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
            .background(ACColors.background)
            .cornerRadius(ACRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
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
                print("⚠️ No se pudo obtener ubicación, iniciando sin optimización")
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
                        print("📏 Distancia total calculada: \(self.formattedDistance) \(self.distanceUnit)")
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
