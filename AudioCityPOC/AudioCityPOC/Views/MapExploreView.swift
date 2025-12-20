//
//  MapExploreView.swift
//  AudioCityPOC
//
//  Vista de mapa para explorar todos los puntos de audio
//  Cuando hay una ruta activa, muestra la ruta trazada y actualiza la distancia al próximo punto
//

import SwiftUI
import MapKit
import Combine

struct MapExploreView: View {
    @ObservedObject private var viewModel = ExploreViewModel.shared
    @ObservedObject private var tripService = TripService.shared

    // RouteViewModel compartido para mostrar ruta activa (opcional)
    var activeRouteViewModel: RouteViewModel?

    // Callback para navegar a la pantalla de rutas
    var onNavigateToRoute: ((String) -> Void)?

    @State private var showStopDetail = false
    @State private var nextStop: Stop? = nil
    @State private var lastRouteUpdateTime: Date = .distantPast

    // Búsqueda de direcciones
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @StateObject private var searchCompleter = SearchCompleterDelegate()


    // Computed: Si hay ruta activa
    private var hasActiveRoute: Bool {
        activeRouteViewModel?.isRouteActive == true
    }

    // Computed: Paradas de la ruta activa
    private var activeRouteStops: [Stop] {
        activeRouteViewModel?.stops ?? []
    }

    // Computed: Distancia al próximo punto
    private var distanceToNextStop: Double {
        activeRouteViewModel?.distanceToNextStop ?? 0
    }

    // Computed: Progreso de la ruta
    private var routeProgress: (visited: Int, total: Int) {
        guard let vm = activeRouteViewModel else { return (0, 0) }
        return (vm.getVisitedCount(), vm.stops.count)
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ACLoadingState(message: "Cargando puntos de audio...")
            } else if let error = viewModel.errorMessage {
                ACErrorState(
                    title: "Error de conexión",
                    description: error,
                    retryAction: { viewModel.loadAllStops() }
                )
            } else {
                // Mapa con paradas
                mapView

                // Overlay con controles
                VStack(spacing: 0) {
                    // Buscador de direcciones (arriba)
                    VStack(spacing: 0) {
                        // Campo de búsqueda
                        HStack(spacing: ACSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ACColors.textTertiary)
                                .font(.system(size: 16))

                            TextField("Buscar dirección...", text: $searchText)
                                .font(ACTypography.bodyMedium)
                                .foregroundColor(ACColors.textPrimary)
                                .onTapGesture {
                                    isSearching = true
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                    isSearching = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ACColors.textTertiary)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, ACSpacing.md)
                        .padding(.vertical, ACSpacing.sm)
                        .background(ACColors.surface)
                        .cornerRadius(ACRadius.lg)
                        .acShadow(ACShadow.md)
                        .padding(.horizontal, ACSpacing.containerPadding)
                        .padding(.top, ACSpacing.md)

                        // Resultados de búsqueda
                        if isSearching && !searchResults.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(searchResults, id: \.self) { result in
                                        Button(action: {
                                            selectSearchResult(result)
                                        }) {
                                            HStack(spacing: ACSpacing.sm) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(ACColors.primary)
                                                    .font(.system(size: 20))

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(ACTypography.bodyMedium)
                                                        .foregroundColor(ACColors.textPrimary)
                                                        .lineLimit(1)

                                                    if !result.subtitle.isEmpty {
                                                        Text(result.subtitle)
                                                            .font(ACTypography.caption)
                                                            .foregroundColor(ACColors.textSecondary)
                                                            .lineLimit(1)
                                                    }
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal, ACSpacing.md)
                                            .padding(.vertical, ACSpacing.sm)
                                        }

                                        if result != searchResults.last {
                                            Divider()
                                                .padding(.leading, 44)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(ACColors.surface)
                            .cornerRadius(ACRadius.lg)
                            .acShadow(ACShadow.md)
                            .padding(.horizontal, ACSpacing.containerPadding)
                            .padding(.top, ACSpacing.xs)
                        }
                    }

                    Spacer()

                    // Botón de mi ubicación (siempre visible, arriba del overlay de ruta)
                    HStack {
                        Spacer()
                        Button(action: centerOnUserLocation) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(ACColors.info))
                                .acShadow(ACShadow.md)
                        }
                        .padding(.trailing, ACSpacing.containerPadding)
                    }
                    .padding(.bottom, ACSpacing.sm)

                    // Overlay de ruta activa con próxima parada
                    if hasActiveRoute, let next = nextStop {
                        activeRouteOverlay(nextStop: next)
                            .padding(.horizontal, ACSpacing.containerPadding)
                            .padding(.bottom, ACSpacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    // Parada seleccionada (solo si NO hay ruta activa)
                    else if let selectedStop = viewModel.selectedStop {
                        StopDetailCard(
                            stop: selectedStop,
                            isPlaying: viewModel.audioService.isPlaying,
                            isPaused: viewModel.audioService.isPaused,
                            onPlay: { viewModel.playStop(selectedStop) },
                            onPause: { viewModel.pauseAudio() },
                            onResume: { viewModel.resumeAudio() },
                            onStop: { viewModel.stopAudio() },
                            onClose: { viewModel.selectedStop = nil },
                            onViewRoute: {
                                // Detener audio y navegar a la ruta
                                viewModel.stopAudio()
                                viewModel.selectedStop = nil
                                onNavigateToRoute?(selectedStop.routeId)
                            }
                        )
                        .padding(.horizontal, ACSpacing.containerPadding)
                        .padding(.bottom, ACSpacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            // Solo cargar si no hay datos (evita recargas innecesarias)
            if viewModel.allStops.isEmpty {
                viewModel.loadAllStops()
            }

            // Solicitar permisos y ubicación única (sin tracking continuo)
            viewModel.locationService.requestLocationPermission()
            viewModel.requestCurrentLocation()
            updateNextStop()
        }
        .onReceive(viewModel.locationService.$userLocation) { location in
            // Solo actualizar ruta activa cuando cambia la ubicación (si hay tracking activo)
            if hasActiveRoute {
                handleActiveRouteLocationUpdate(location)
            }
        }
        .onChange(of: activeRouteViewModel?.stops.map { $0.hasBeenVisited } ?? []) { _, _ in
            updateNextStop()
        }
        .onChange(of: activeRouteViewModel?.isRouteActive) { _, isActive in
            if isActive == true {
                Log("Ruta activada, esperando polylines...", level: .debug, category: .route)
            }
        }
        .onChange(of: activeRouteViewModel?.routePolylines.count ?? 0) { _, count in
            if count > 0 && hasActiveRoute {
                Log("Polylines listos (\(count)), centrando mapa...", level: .debug, category: .route)
                // Pequeño delay para asegurar que el mapa está renderizado
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    centerMapOnRoute()
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                searchResults = []
            } else {
                searchCompleter.search(query: newValue)
            }
        }
        .onReceive(searchCompleter.$results) { results in
            searchResults = results
        }
        .onTapGesture {
            // Cerrar búsqueda al tocar el mapa
            if isSearching && searchText.isEmpty {
                isSearching = false
            }
        }
    }

    // MARK: - Search Functions

    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        // Buscar la ubicación completa
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                Log("No se pudo encontrar la ubicación", level: .warning, category: .location)
                return
            }

            DispatchQueue.main.async {
                // Centrar el mapa en la ubicación seleccionada
                let region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                viewModel.mapRegion = region
                viewModel.activeRouteCameraPosition = .region(region)

                // Limpiar búsqueda
                searchText = ""
                searchResults = []
                isSearching = false

                Log("Mapa centrado en: \(result.title)", level: .info, category: .location)
            }
        }
    }

    // MARK: - Map View
    @ViewBuilder
    private var mapView: some View {
        if hasActiveRoute {
            // Mapa con ruta trazada (polylines) cuando hay ruta activa
            activeRouteMapView
                .id("activeRoute-\(activeRouteViewModel?.currentRoute?.id ?? "")-\(activeRouteViewModel?.routePolylines.count ?? 0)")
        } else {
            // Mapa normal de exploración
            exploreMapView
        }
    }

    // MARK: - Explore Map (sin ruta activa)
    private var exploreMapView: some View {
        Map(coordinateRegion: $viewModel.mapRegion,
            showsUserLocation: true,
            annotationItems: viewModel.allStops) { stop in
            MapAnnotation(coordinate: stop.coordinate) {
                StopMarker(
                    stop: stop,
                    isSelected: viewModel.selectedStop?.id == stop.id,
                    isFromTrip: tripService.activeRouteIds.contains(stop.routeId)
                )
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedStop = stop
                        viewModel.mapRegion.center = stop.coordinate
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    // MARK: - Active Route Map (con polylines)
    private var activeRouteMapView: some View {
        Map(position: $viewModel.activeRouteCameraPosition) {
            // Ubicación del usuario
            UserAnnotation()

            // Polylines de la ruta (rutas caminando)
            if let vm = activeRouteViewModel {
                ForEach(Array(vm.routePolylines.enumerated()), id: \.offset) { index, polyline in
                    MapPolyline(polyline)
                        .stroke(
                            index == 0 ? ACColors.info : ACColors.primary,  // Azul para usuario→parada1, coral para el resto
                            style: StrokeStyle(
                                lineWidth: index == 0 ? 5 : 4,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                }
            }

            // Pins de las paradas de la ruta activa
            ForEach(activeRouteStops.sorted(by: { $0.order < $1.order })) { stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    ActiveRouteStopMarker(
                        stop: stop,
                        isVisited: stop.hasBeenVisited,
                        isNext: nextStop?.id == stop.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.activeRouteCameraPosition = .region(MKCoordinateRegion(
                                center: stop.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                            ))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // Log para debug
            if let vm = activeRouteViewModel {
                Log("ActiveRouteMap: \(vm.routePolylines.count) polylines, \(activeRouteStops.count) paradas", level: .debug, category: .route)
            }

            // Centrar el mapa en la ruta cuando aparece
            centerMapOnRoute()
        }
    }

    /// Centra el mapa para mostrar toda la ruta activa
    private func centerMapOnRoute() {
        guard !activeRouteStops.isEmpty else { return }

        // Calcular el bounding box de todas las paradas
        let coordinates = activeRouteStops.map { $0.coordinate }

        // Incluir ubicación del usuario si está disponible
        var allCoordinates = coordinates
        if let userLocation = viewModel.locationService.userLocation {
            allCoordinates.append(userLocation.coordinate)
        }

        guard !allCoordinates.isEmpty else { return }

        let minLat = allCoordinates.map { $0.latitude }.min() ?? 0
        let maxLat = allCoordinates.map { $0.latitude }.max() ?? 0
        let minLon = allCoordinates.map { $0.longitude }.min() ?? 0
        let maxLon = allCoordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Añadir padding al span
        let latDelta = (maxLat - minLat) * 1.3
        let lonDelta = (maxLon - minLon) * 1.3

        // Asegurar un zoom mínimo
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.005),
            longitudeDelta: max(lonDelta, 0.005)
        )

        viewModel.activeRouteCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        viewModel.hasPositionedActiveRoute = true

        Log("Mapa centrado en ruta: \(center.latitude), \(center.longitude)", level: .debug, category: .route)
    }

    // MARK: - Active Route Overlay

    private func activeRouteOverlay(nextStop: Stop) -> some View {
        VStack(spacing: ACSpacing.md) {
            // Header con progreso
            HStack {
                // Indicador de ruta activa
                ZStack {
                    Circle()
                        .fill(ACColors.primary)
                        .frame(width: 40, height: 40)

                    Image(systemName: "headphones")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text(activeRouteViewModel?.currentRoute?.name ?? "Ruta activa")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: ACSpacing.xs) {
                        Text("\(routeProgress.visited)/\(routeProgress.total) paradas")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textSecondary)
                    }
                }

                Spacer()

                // Distancia grande
                distanceBadge
            }

            Divider()
                .background(ACColors.border)

            // Próxima parada
            HStack(spacing: ACSpacing.md) {
                // Número de parada
                ZStack {
                    Circle()
                        .fill(ACColors.primary)
                        .frame(width: 32, height: 32)

                    Text("\(nextStop.order)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("PRÓXIMA PARADA")
                        .font(ACTypography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundColor(ACColors.textTertiary)

                    Text(nextStop.name)
                        .font(ACTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                // Controles de audio si está reproduciendo
                if let vm = activeRouteViewModel, vm.audioService.isPlaying || vm.audioService.isPaused {
                    audioControls
                }
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.xl)
        .acShadow(ACShadow.lg)
    }

    // MARK: - Distance Badge

    private var distanceBadge: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if distanceToNextStop < 1000 {
                    Text("\(Int(distanceToNextStop))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(distanceColor)
                    Text("m")
                        .font(ACTypography.caption)
                        .foregroundColor(distanceColor.opacity(0.8))
                } else {
                    Text(String(format: "%.1f", distanceToNextStop / 1000))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(distanceColor)
                    Text("km")
                        .font(ACTypography.caption)
                        .foregroundColor(distanceColor.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, ACSpacing.sm)
        .padding(.vertical, ACSpacing.xs)
        .background(distanceBackgroundColor)
        .cornerRadius(ACRadius.md)
    }

    private var distanceColor: Color {
        if distanceToNextStop < 50 {
            return ACColors.success
        } else if distanceToNextStop < 200 {
            return ACColors.warning
        } else {
            return ACColors.primary
        }
    }

    private var distanceBackgroundColor: Color {
        if distanceToNextStop < 50 {
            return ACColors.successLight
        } else if distanceToNextStop < 200 {
            return ACColors.warningLight
        } else {
            return ACColors.primaryLight
        }
    }

    // MARK: - Audio Controls

    private var audioControls: some View {
        HStack(spacing: ACSpacing.sm) {
            Button(action: {
                if activeRouteViewModel?.audioService.isPaused == true {
                    activeRouteViewModel?.resumeAudio()
                } else {
                    activeRouteViewModel?.pauseAudio()
                }
            }) {
                Image(systemName: activeRouteViewModel?.audioService.isPaused == true ? "play.fill" : "pause.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(ACColors.primary)
                    .cornerRadius(18)
            }

            Button(action: {
                activeRouteViewModel?.stopAudio()
            }) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ACColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(ACColors.borderLight)
                    .cornerRadius(16)
            }
        }
    }

    // MARK: - Actions

    private func centerOnUserLocation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            viewModel.centerOnUserLocation()
            // También centrar el mapa de ruta activa
            if let userLocation = viewModel.locationService.userLocation {
                viewModel.activeRouteCameraPosition = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
            }
        }
    }

    private func updateNextStop() {
        guard let vm = activeRouteViewModel else {
            nextStop = nil
            return
        }
        nextStop = vm.stops
            .filter { !$0.hasBeenVisited }
            .sorted(by: { $0.order < $1.order })
            .first
    }

    private func handleActiveRouteLocationUpdate(_ location: CLLocation?) {
        guard let userLocation = location,
              let vm = activeRouteViewModel,
              let next = nextStop else { return }

        // Actualizar el segmento y distancia usuario→próxima parada cada 10 segundos
        if Date().timeIntervalSince(lastRouteUpdateTime) > 10 {
            lastRouteUpdateTime = Date()
            vm.updateUserSegment(
                from: userLocation.coordinate,
                to: next.coordinate
            )
            Log("Distancia actualizada a \(next.name)", level: .debug, category: .location)
        }
    }
}

// MARK: - Active Route Stop Marker

struct ActiveRouteStopMarker: View {
    let stop: Stop
    let isVisited: Bool
    let isNext: Bool

    private var pinColor: Color {
        if isVisited {
            return ACColors.success
        } else if isNext {
            return ACColors.primary
        } else {
            return ACColors.textTertiary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Glow para próxima parada
                if isNext {
                    Circle()
                        .fill(pinColor.opacity(0.3))
                        .frame(width: 44, height: 44)
                }

                Circle()
                    .fill(pinColor)
                    .frame(width: isNext ? 36 : 28, height: isNext ? 36 : 28)
                    .shadow(color: pinColor.opacity(0.4), radius: 4, y: 2)

                if isVisited {
                    Image(systemName: "checkmark")
                        .font(.system(size: isNext ? 14 : 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stop.order)")
                        .font(.system(size: isNext ? 14 : 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Pin tail
            Triangle()
                .fill(pinColor)
                .frame(width: 10, height: 6)
                .offset(y: -1)

            // Nombre si es la próxima
            if isNext {
                Text(stop.name)
                    .font(ACTypography.captionSmall)
                    .fontWeight(.semibold)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xs)
                    .background(pinColor)
                    .foregroundColor(.white)
                    .cornerRadius(ACRadius.sm)
                    .offset(y: ACSpacing.xs)
            }
        }
        .animation(ACAnimation.spring, value: isNext)
    }
}

// MARK: - Stop Marker
struct StopMarker: View {
    let stop: Stop
    let isSelected: Bool
    var isFromTrip: Bool = false

    /// Color del pin según estado
    private var pinColor: Color {
        if isSelected {
            return ACColors.Map.stopSelected
        } else if isFromTrip {
            return ACColors.secondary
        } else {
            return ACColors.Map.stopPin
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Glow cuando está seleccionado
                if isSelected {
                    Circle()
                        .fill(pinColor.opacity(0.3))
                        .frame(width: 52, height: 52)
                }

                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: pinColor.opacity(0.4), radius: 4, y: 2)

                Image(systemName: isFromTrip ? "suitcase.fill" : "headphones")
                    .foregroundColor(.white)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
            }

            // Pin tail
            Triangle()
                .fill(pinColor)
                .frame(width: 14, height: 8)
                .offset(y: -2)

            if isSelected {
                Text(stop.name)
                    .font(ACTypography.captionSmall)
                    .fontWeight(.semibold)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xs)
                    .background(pinColor)
                    .foregroundColor(.white)
                    .cornerRadius(ACRadius.sm)
                    .offset(y: ACSpacing.xs)
            }
        }
        .animation(ACAnimation.spring, value: isSelected)
    }
}

// MARK: - Stop Detail Card
struct StopDetailCard: View {
    let stop: Stop
    let isPlaying: Bool
    let isPaused: Bool
    let onPlay: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onClose: () -> Void
    var onViewRoute: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(alignment: .top) {
                // Icono
                ZStack {
                    Circle()
                        .fill(ACColors.primaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: "headphones")
                        .font(.system(size: 20))
                        .foregroundColor(ACColors.primary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text(stop.name)
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)

                    Text(stop.category)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ACColors.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ACColors.borderLight)
                        .cornerRadius(14)
                }
            }

            // Descripción
            Text(stop.description)
                .font(ACTypography.bodySmall)
                .foregroundColor(ACColors.textSecondary)
                .lineLimit(3)

            // Metadatos
            HStack(spacing: ACSpacing.md) {
                ACMetaBadge(icon: "clock", text: "\(stop.audioDurationSeconds)s")
                ACMetaBadge(icon: "location.circle", text: "\(Int(stop.triggerRadiusMeters))m")
            }

            Divider()
                .background(ACColors.border)

            // Controles de audio y ver ruta
            HStack(spacing: ACSpacing.sm) {
                if !isPlaying && !isPaused {
                    // Botón escuchar preview
                    Button(action: onPlay) {
                        HStack(spacing: ACSpacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Escuchar")
                                .font(ACTypography.labelMedium)
                        }
                        .foregroundColor(ACColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ACSpacing.sm)
                        .background(ACColors.primaryLight)
                        .cornerRadius(ACRadius.md)
                    }

                    // Botón ver ruta
                    if let onViewRoute = onViewRoute {
                        Button(action: onViewRoute) {
                            HStack(spacing: ACSpacing.xs) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 14))
                                Text("Ver ruta")
                                    .font(ACTypography.labelMedium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ACSpacing.sm)
                            .background(ACColors.primary)
                            .cornerRadius(ACRadius.md)
                        }
                    }
                } else {
                    // Pause/Resume
                    Button(action: isPaused ? onResume : onPause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(ACColors.primary))
                    }

                    // Stop
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(ACColors.error))
                    }

                    Spacer()

                    // Indicador de reproducción
                    if !isPaused {
                        HStack(spacing: 3) {
                            ForEach(0..<3) { index in
                                AudioWaveBar(delay: Double(index) * 0.2)
                            }
                        }
                        .frame(width: 40)
                    }

                    // Botón ver ruta (también cuando reproduce)
                    if let onViewRoute = onViewRoute {
                        Button(action: onViewRoute) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ACColors.primary)
                                .frame(width: 44, height: 44)
                                .background(ACColors.primaryLight)
                                .cornerRadius(ACRadius.md)
                        }
                    }
                }
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.xl)
        .acShadow(ACShadow.lg)
    }
}

// MARK: - Search Completer Delegate

class SearchCompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Log("Error en búsqueda: \(error.localizedDescription)", level: .error, category: .location)
    }
}

#Preview {
    MapExploreView()
}
