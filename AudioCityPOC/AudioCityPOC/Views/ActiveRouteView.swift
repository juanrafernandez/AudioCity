//
//  ActiveRouteView.swift
//  AudioCityPOC
//
//  Vista de ruta activa con mapa, ruta trazada y overlay de información
//  Diseño inspirado en Transit App: números grandes, colores bold, información clara
//

import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: - Active Route View

struct ActiveRouteView: View {
    @ObservedObject var viewModel: RouteViewModel
    @State private var cameraPosition: MapCameraPosition
    @State private var nextStop: Stop? = nil
    @State private var showingStopsList = false

    // Usar la distancia del viewModel (datos precalculados)
    private var distanceToNextStop: Double {
        viewModel.distanceToNextStop
    }

    // Distancia total formateada (solo ruta, sin segmento usuario)
    private var formattedTotalDistance: String {
        let distance = viewModel.totalRouteDistance
        if distance < 1000 {
            return "\(Int(distance)) m total"
        } else {
            return String(format: "%.1f km total", distance / 1000)
        }
    }

    // Distancia total desde el usuario formateada
    private var formattedTotalDistanceFromUser: String {
        let distance = viewModel.totalDistanceFromUser
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    // Distancia recorrida (suma de segmentos de paradas visitadas)
    private var distanceWalked: CLLocationDistance {
        let visitedCount = viewModel.getVisitedCount()
        guard visitedCount > 0, viewModel.routeDistances.count > 1 else { return 0 }
        // Segmento 0 es usuario→parada1, segmento 1 es parada1→parada2, etc.
        // Cuando visitas parada1, has recorrido segmento 0
        // Cuando visitas parada2, has recorrido segmentos 0 y 1
        let segmentsWalked = min(visitedCount, viewModel.routeDistances.count)
        return viewModel.routeDistances.prefix(segmentsWalked).reduce(0, +)
    }

    private var formattedDistanceWalked: String {
        if distanceWalked < 1000 {
            return "\(Int(distanceWalked)) m"
        } else {
            return String(format: "%.1f km", distanceWalked / 1000)
        }
    }

    init(viewModel: RouteViewModel) {
        self.viewModel = viewModel

        // Centrar en la ubicación del usuario si está disponible, sino en el inicio de la ruta
        let initialCenter: CLLocationCoordinate2D
        if let userLocation = viewModel.locationService.userLocation {
            initialCenter = userLocation.coordinate
        } else {
            initialCenter = viewModel.currentRoute?.startLocation.coordinate ??
                CLLocationCoordinate2D(latitude: 40.3974, longitude: -3.6924)
        }
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )))
    }

    var body: some View {
        ZStack {
            // Mapa con ruta trazada
            mapWithRoute

            // Overlay de información
            VStack(spacing: 0) {
                // Card superior: Info de ruta activa (estilo Transit)
                routeInfoCard
                    .padding(.horizontal, ACSpacing.containerPadding)
                    .padding(.top, ACSpacing.sm)

                Spacer()

                // Card inferior: Próxima parada con distancia grande
                bottomCard
            }

            // Lista de paradas (sheet con animación desde abajo)
            if showingStopsList {
                stopsListOverlay
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingStopsList)
        .onAppear {
            updateNextStop()
        }
        .onChange(of: viewModel.locationService.userLocation) { _, location in
            handleLocationUpdate(location)
        }
        .onChange(of: viewModel.stops.map { $0.hasBeenVisited }) { _, _ in
            updateNextStop()
        }
    }

    // MARK: - Map with Route

    private var mapWithRoute: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                // Ubicación del usuario
                UserAnnotation()

                // Rutas caminando (todos los segmentos) - usando datos precalculados del viewModel
                ForEach(Array(viewModel.routePolylines.enumerated()), id: \.offset) { index, polyline in
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

                // Pins de las paradas
                ForEach(viewModel.stops.sorted(by: { $0.order < $1.order })) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        StopMapPin(
                            number: stop.order,
                            state: stopState(for: stop),
                            isNext: nextStop?.id == stop.id
                        )
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
            }
            .ignoresSafeArea(edges: .top)

            // Botón de centrar en ubicación del usuario - posicionado manualmente para evitar el status bar
            Button(action: centerOnUserLocation) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(ACColors.info)
                    .frame(width: 44, height: 44)
                    .background(ACColors.surface)
                    .cornerRadius(8)
                    .acShadow(ACShadow.sm)
            }
            .padding(.top, 100) // Debajo del card de info de ruta
            .padding(.trailing, ACSpacing.containerPadding)
        }
    }

    // MARK: - Center on User Location

    private func centerOnUserLocation() {
        if let userLocation = viewModel.locationService.userLocation {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                ))
            }
        }
    }

    // MARK: - Route Info Card (Top) - Estilo Transit

    private var routeInfoCard: some View {
        HStack(spacing: ACSpacing.md) {
            // Indicador de ruta activa con pulso
            ZStack {
                Circle()
                    .fill(ACColors.primary.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(ACColors.primary)
                    .frame(width: 24, height: 24)

                Image(systemName: "headphones")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            // Info de ruta
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text("RUTA EN MARCHA")
                    .font(ACTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundColor(ACColors.primary)

                Text(viewModel.currentRoute?.name ?? "")
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)
                    .lineLimit(1)

                // Distancias: recorrida / total
                if viewModel.totalDistanceFromUser > 0 {
                    HStack(spacing: ACSpacing.xs) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 10))
                        Text("\(formattedDistanceWalked) / \(formattedTotalDistanceFromUser)")
                            .font(ACTypography.captionSmall)
                    }
                    .foregroundColor(ACColors.textSecondary)
                }
            }

            Spacer()

            // Progreso - Estilo Transit con número grande
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.getVisitedCount())")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ACColors.primary)
                    Text("/\(viewModel.stops.count)")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textSecondary)
                }
            }

            // Botón cerrar
            Button(action: { viewModel.endRoute() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ACColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(ACColors.borderLight)
                    .cornerRadius(14)
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.lg)
        .onAppear { startPulseAnimation() }
    }

    @State private var pulseScale: CGFloat = 1.0

    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.4
        }
    }

    // MARK: - Bottom Card - Estilo Transit

    private var bottomCard: some View {
        VStack(spacing: 0) {
            // Próxima parada o completado
            if let next = nextStop {
                nextStopSection(stop: next)
            } else if viewModel.getVisitedCount() == viewModel.stops.count {
                routeCompletedSection
            }

            // Barra de progreso visual
            progressDotsBar
                .padding(.top, ACSpacing.md)

            // Botón ver todas las paradas
            Button(action: { showingStopsList = true }) {
                HStack(spacing: ACSpacing.xs) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14))
                    Text("Ver todas las paradas")
                        .font(ACTypography.labelSmall)
                }
                .foregroundColor(ACColors.textSecondary)
                .padding(.vertical, ACSpacing.md)
            }
        }
        .padding(.horizontal, ACSpacing.containerPadding)
        .padding(.top, ACSpacing.lg)
        .padding(.bottom, ACSpacing.md)
        .background(
            ACColors.surface
                .cornerRadius(ACRadius.xxl, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
    }

    // MARK: - Next Stop Section - Estilo Transit con número grande

    private func nextStopSection(stop: Stop) -> some View {
        VStack(spacing: ACSpacing.md) {
            // Header con distancia GRANDE estilo Transit
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("PRÓXIMA PARADA")
                        .font(ACTypography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundColor(ACColors.textTertiary)

                    Text(stop.name)
                        .font(ACTypography.headlineMedium)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(2)

                    Text(stop.category)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                // Distancia GRANDE estilo Transit
                distanceBadge
            }

            // Mensaje de proximidad o controles de audio
            if distanceToNextStop < 50 {
                proximityAlert
            } else if viewModel.audioService.isPlaying || viewModel.audioService.isPaused {
                audioControlsSection
            }
        }
    }

    // MARK: - Distance Badge - Estilo Transit

    private var distanceBadge: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Distancia grande
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if distanceToNextStop < 1000 {
                    Text("\(Int(distanceToNextStop))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(distanceColor)
                    Text("m")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(distanceColor.opacity(0.8))
                } else {
                    Text(String(format: "%.1f", distanceToNextStop / 1000))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(distanceColor)
                    Text("km")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(distanceColor.opacity(0.8))
                }
            }

            // Icono de caminando
            HStack(spacing: ACSpacing.xxs) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 12))
                Text(distanceToNextStop < 50 ? "Llegando" : "caminando")
                    .font(ACTypography.captionSmall)
            }
            .foregroundColor(distanceColor.opacity(0.8))
        }
        .padding(ACSpacing.md)
        .background(distanceBackgroundColor)
        .cornerRadius(ACRadius.lg)
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

    // MARK: - Proximity Alert

    private var proximityAlert: some View {
        HStack(spacing: ACSpacing.md) {
            ZStack {
                Circle()
                    .fill(ACColors.success)
                    .frame(width: 40, height: 40)

                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text("Has llegado")
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)
                Text("El audio se reproducirá automáticamente")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)
            }

            Spacer()
        }
        .padding(ACSpacing.md)
        .background(ACColors.successLight)
        .cornerRadius(ACRadius.md)
    }

    // MARK: - Audio Controls

    private var audioControlsSection: some View {
        HStack(spacing: ACSpacing.md) {
            // Indicador de reproducción
            if viewModel.audioService.isPlaying {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        AudioWaveBar(delay: Double(i) * 0.15)
                    }
                }
                .frame(width: 24)
            }

            Text(viewModel.audioService.isPaused ? "En pausa" : "Reproduciendo...")
                .font(ACTypography.bodySmall)
                .foregroundColor(ACColors.textSecondary)

            Spacer()

            // Botón play/pause
            Button(action: {
                if viewModel.audioService.isPaused {
                    viewModel.resumeAudio()
                } else {
                    viewModel.pauseAudio()
                }
            }) {
                Image(systemName: viewModel.audioService.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(ACColors.primary)
                    .cornerRadius(22)
            }

            // Botón stop
            Button(action: { viewModel.stopAudio() }) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(ACColors.borderLight)
                    .cornerRadius(18)
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.background)
        .cornerRadius(ACRadius.md)
    }

    // MARK: - Route Completed

    private var routeCompletedSection: some View {
        VStack(spacing: ACSpacing.lg) {
            ZStack {
                Circle()
                    .fill(ACColors.successLight)
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ACColors.success)
            }

            VStack(spacing: ACSpacing.xs) {
                Text("Ruta completada")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("Has visitado todas las paradas")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
            }

            ACButton("Finalizar ruta", style: .primary, size: .large, isFullWidth: true) {
                viewModel.endRoute()
            }
        }
        .padding(.vertical, ACSpacing.lg)
    }

    // MARK: - Progress Dots Bar

    private var progressDotsBar: some View {
        HStack(spacing: ACSpacing.xs) {
            ForEach(viewModel.stops.sorted(by: { $0.order < $1.order })) { stop in
                Circle()
                    .fill(dotColor(for: stop))
                    .frame(width: nextStop?.id == stop.id ? 14 : 10, height: nextStop?.id == stop.id ? 14 : 10)
                    .overlay {
                        if stop.hasBeenVisited {
                            Image(systemName: "checkmark")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(ACAnimation.spring, value: nextStop?.id)

                if stop.order < viewModel.stops.count {
                    Rectangle()
                        .fill(stop.hasBeenVisited ? ACColors.success : ACColors.border)
                        .frame(height: 2)
                }
            }
        }
    }

    private func dotColor(for stop: Stop) -> Color {
        if stop.hasBeenVisited {
            return ACColors.success
        } else if nextStop?.id == stop.id {
            return ACColors.primary
        } else {
            return ACColors.border
        }
    }

    // MARK: - Stops List Overlay

    private var stopsListOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showingStopsList = false
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(ACColors.border)
                        .frame(width: 36, height: 5)
                        .padding(.top, ACSpacing.sm)

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                            Text("Paradas de la ruta")
                                .font(ACTypography.headlineSmall)
                                .foregroundColor(ACColors.textPrimary)

                            // Distancia total de la ruta
                            if viewModel.totalRouteDistance > 0 {
                                HStack(spacing: ACSpacing.xs) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 10))
                                    Text(formattedTotalDistance)
                                        .font(ACTypography.captionSmall)
                                }
                                .foregroundColor(ACColors.textSecondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showingStopsList = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ACColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(ACColors.borderLight)
                                .cornerRadius(14)
                        }
                    }
                    .padding(ACSpacing.cardPadding)

                    Divider()

                    // Lista
                    ScrollView {
                        VStack(spacing: 0) {
                            let sortedStops = viewModel.stops.sorted(by: { $0.order < $1.order })
                            ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                                let isLast = index == sortedStops.count - 1
                                StopListRow(
                                    stop: stop,
                                    isVisited: stop.hasBeenVisited,
                                    isNext: nextStop?.id == stop.id,
                                    isCurrent: viewModel.currentStop?.id == stop.id,
                                    distanceToNext: isLast ? nil : viewModel.formattedSegmentDistance(at: index + 1)
                                )
                            }
                        }
                        .padding(.horizontal, ACSpacing.containerPadding)
                        .padding(.top, ACSpacing.sm)
                        .padding(.bottom, ACSpacing.mega + 80) // Extra padding for tabBar
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                }
                .background(ACColors.surface)
                .cornerRadius(ACRadius.xxl, corners: [.topLeft, .topRight])
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func stopState(for stop: Stop) -> StopMapPin.PinState {
        if stop.hasBeenVisited {
            return .visited
        } else if nextStop?.id == stop.id {
            return .next
        } else {
            return .pending
        }
    }

    private func updateNextStop() {
        nextStop = viewModel.stops
            .filter { !$0.hasBeenVisited }
            .sorted(by: { $0.order < $1.order })
            .first
    }

    @State private var lastRouteUpdateTime: Date = .distantPast

    private func handleLocationUpdate(_ location: CLLocation?) {
        guard let userLocation = location else { return }

        // Actualizar el segmento y distancia usuario→próxima parada cada 30 segundos
        if let next = nextStop {
            if Date().timeIntervalSince(lastRouteUpdateTime) > 30 {
                lastRouteUpdateTime = Date()
                viewModel.updateUserSegment(
                    from: userLocation.coordinate,
                    to: next.coordinate
                )
            }
        }

        // Centrar mapa en el usuario
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }
}

// MARK: - Stop Map Pin

struct StopMapPin: View {
    let number: Int
    let state: PinState
    let isNext: Bool

    enum PinState {
        case visited, next, pending

        var color: Color {
            switch self {
            case .visited: return ACColors.success
            case .next: return ACColors.primary
            case .pending: return ACColors.textTertiary
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Glow para próxima parada
                if isNext {
                    Circle()
                        .fill(state.color.opacity(0.3))
                        .frame(width: 44, height: 44)
                }

                Circle()
                    .fill(state.color)
                    .frame(width: isNext ? 36 : 28, height: isNext ? 36 : 28)
                    .shadow(color: state.color.opacity(0.4), radius: 4, y: 2)

                if state == .visited {
                    Image(systemName: "checkmark")
                        .font(.system(size: isNext ? 14 : 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: isNext ? 14 : 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Pin tail
            Triangle()
                .fill(state.color)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
    }
}

// MARK: - Stop List Row

struct StopListRow: View {
    let stop: Stop
    let isVisited: Bool
    let isNext: Bool
    let isCurrent: Bool
    var distanceToNext: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ACSpacing.md) {
                // Número/Check
                ZStack {
                    Circle()
                        .fill(isVisited ? ACColors.success : (isNext ? ACColors.primary : ACColors.border))
                        .frame(width: 36, height: 36)

                    if isVisited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(stop.order)")
                            .font(ACTypography.labelMedium)
                            .fontWeight(.bold)
                            .foregroundColor(isNext ? .white : ACColors.textSecondary)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    HStack {
                        Text(stop.name)
                            .font(isNext ? ACTypography.titleSmall : ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)

                        if isCurrent {
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(ACColors.primary)
                                        .frame(width: 2, height: 8)
                                }
                            }
                        }
                    }

                    Text(stop.category)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                // Estado
                if isVisited {
                    Text("Completada")
                        .font(ACTypography.captionSmall)
                        .foregroundColor(ACColors.success)
                } else if isNext {
                    Text("Siguiente")
                        .font(ACTypography.captionSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(ACColors.primary)
                }
            }
            .padding(ACSpacing.md)
            .background(isNext ? ACColors.primaryLight : ACColors.surface)
            .cornerRadius(ACRadius.md)

            // Distance to next stop
            if let distance = distanceToNext {
                HStack(spacing: ACSpacing.xs) {
                    Rectangle()
                        .fill(ACColors.border)
                        .frame(width: 2, height: 20)
                        .padding(.leading, 17)

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
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("Active Route") {
    ActiveRouteView(viewModel: RouteViewModel())
}
