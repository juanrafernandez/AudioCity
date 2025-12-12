//
//  MainTabView.swift
//  AudioCityPOC
//
//  Vista principal con navegación por tabs
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var activeRouteViewModel = RouteViewModel()
    @State private var previousTab = 0

    // Estados para el sheet de optimización (global)
    @State private var showOptimizeSheet = false
    @State private var isCalculatingRoute = false
    @State private var nearestStopInfo: (name: String, distance: Int, originalOrder: Int)?

    // Para observar cambios de isRouteReady de manera confiable
    @State private var routeReadyCancellable: AnyCancellable?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Tab 1: Explorar mapa (siempre muestra MapExploreView, con overlay de ruta activa si aplica)
                MapExploreView(activeRouteViewModel: activeRouteViewModel)
                    .tabItem {
                        Label("Explorar", systemImage: selectedTab == 0 ? "map.fill" : "map")
                    }
                    .tag(0)

                // Tab 2: Rutas
                RoutesListView(
                    sharedViewModel: activeRouteViewModel,
                    onRouteStarted: {
                        // Esto se llama cuando la ruta está lista
                        withAnimation(ACAnimation.spring) {
                            selectedTab = 0
                        }
                    },
                    onShowOptimizeSheet: { stopInfo in
                        // Mostrar sheet de optimización a nivel global
                        nearestStopInfo = stopInfo
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showOptimizeSheet = true
                        }
                    },
                    onStartRouteDirectly: {
                        // Iniciar sin optimización, mostrar loading
                        isCalculatingRoute = true
                    }
                )
                .tabItem {
                    Label("Rutas", systemImage: selectedTab == 1 ? "headphones" : "headphones")
                }
                .tag(1)

                // Tab 3: Mis Rutas
                MyRoutesView()
                    .tabItem {
                        Label("Crear", systemImage: selectedTab == 2 ? "plus.circle.fill" : "plus.circle")
                    }
                    .tag(2)

                // Tab 4: Historial
                HistoryView()
                    .tabItem {
                        Label("Historial", systemImage: selectedTab == 3 ? "clock.fill" : "clock")
                    }
                    .tag(3)

                // Tab 5: Perfil
                ProfileView()
                    .tabItem {
                        Label("Perfil", systemImage: selectedTab == 4 ? "person.fill" : "person")
                    }
                    .tag(4)
            }
            .tint(ACColors.primary)

            // Mini player flotante cuando hay ruta activa (excepto en tab de explorar)
            if activeRouteViewModel.isRouteActive && selectedTab != 0 && !showOptimizeSheet {
                VStack {
                    Spacer()
                    ActiveRouteMiniPlayer(viewModel: activeRouteViewModel) {
                        // Al tocar, ir al mapa
                        withAnimation(ACAnimation.spring) {
                            selectedTab = 0
                        }
                    }
                    .padding(.horizontal, ACSpacing.containerPadding)
                    .padding(.bottom, 90) // Espacio para el tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Sheet de optimización global (se muestra sobre todo)
            if showOptimizeSheet {
                OptimizeRouteSheetGlobal(
                    nearestStopInfo: nearestStopInfo,
                    isCalculating: $isCalculatingRoute,
                    onKeepOriginal: {
                        isCalculatingRoute = true
                        activeRouteViewModel.startRoute(optimized: false)
                    },
                    onOptimize: {
                        isCalculatingRoute = true
                        activeRouteViewModel.startRoute(optimized: true)
                    },
                    onDismiss: {
                        if !isCalculatingRoute {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showOptimizeSheet = false
                            }
                        }
                    }
                )
                .zIndex(1000)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Loading overlay cuando se inicia sin sheet de optimización
            if isCalculatingRoute && !showOptimizeSheet {
                RouteLoadingOverlayGlobal()
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showOptimizeSheet)
        .onAppear {
            // Observar isRouteReady con Combine para mayor fiabilidad
            routeReadyCancellable = activeRouteViewModel.$isRouteReady
                .dropFirst() // Ignorar valor inicial
                .filter { $0 == true }
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    print("🎯 MainTabView: isRouteReady cambió a true")

                    // Centrar el mapa en la ruta ANTES de cerrar
                    centerExploreMapOnActiveRoute()

                    // Pequeña pausa para que se vea que terminó de calcular
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Cerrar sheet y navegar
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showOptimizeSheet = false
                            isCalculatingRoute = false
                            selectedTab = 0
                        }
                    }
                }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // Detener audio de preview cuando se cambia de tab
            AudioPreviewService.shared.stop()
        }
    }

    /// Centra el mapa de exploración en la ruta activa
    private func centerExploreMapOnActiveRoute() {
        let stops = activeRouteViewModel.stops
        guard !stops.isEmpty else { return }

        let coordinates = stops.map { $0.coordinate }

        // Incluir ubicación del usuario si está disponible
        var allCoordinates = coordinates
        if let userLocation = ExploreViewModel.shared.locationService.userLocation {
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

        let latDelta = (maxLat - minLat) * 1.3
        let lonDelta = (maxLon - minLon) * 1.3

        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.005),
            longitudeDelta: max(lonDelta, 0.005)
        )

        let region = MKCoordinateRegion(center: center, span: span)
        ExploreViewModel.shared.activeRouteCameraPosition = .region(region)
        ExploreViewModel.shared.hasPositionedActiveRoute = true

        print("🗺️ MainTabView: Mapa centrado en ruta activa")
    }
}

// MARK: - Optimize Route Sheet Global
struct OptimizeRouteSheetGlobal: View {
    let nearestStopInfo: (name: String, distance: Int, originalOrder: Int)?
    @Binding var isCalculating: Bool
    let onKeepOriginal: () -> Void
    let onOptimize: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dimmed
                Color.black.opacity(ACOpacity.medium)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        if !isCalculating {
                            onDismiss()
                        }
                    }

                // Sheet posicionado desde el fondo
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: ACSpacing.lg) {
                        // Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(ACColors.border)
                            .frame(width: 36, height: 5)
                            .padding(.top, ACSpacing.sm)

                        if isCalculating {
                            // Estado: Calculando
                            CalculatingStateView()
                                .transition(.opacity)
                        } else {
                            // Estado: Selección
                            SelectionStateView(
                                nearestStopInfo: nearestStopInfo,
                                onOptimize: onOptimize,
                                onKeepOriginal: onKeepOriginal
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, ACSpacing.md)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    .frame(maxWidth: .infinity)
                    .background(ACColors.surface)
                    .cornerRadius(ACRadius.xxl, corners: [.topLeft, .topRight])
                    .animation(.easeInOut(duration: 0.3), value: isCalculating)
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }
}

// MARK: - Selection State View
private struct SelectionStateView: View {
    let nearestStopInfo: (name: String, distance: Int, originalOrder: Int)?
    let onOptimize: () -> Void
    let onKeepOriginal: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 64, height: 64)

                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 28))
                    .foregroundColor(ACColors.primary)
            }

            // Title
            Text("Optimizar recorrido")
                .font(ACTypography.headlineMedium)
                .foregroundColor(ACColors.textPrimary)

            // Message
            if let info = nearestStopInfo {
                Text("Estás más cerca de **\"\(info.name)\"** (parada \(info.originalOrder), a \(info.distance)m).\n\n¿Quieres reordenar la ruta para empezar por el punto más cercano?")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.lg)
            }

            // Buttons
            VStack(spacing: ACSpacing.sm) {
                Button(action: onOptimize) {
                    HStack(spacing: ACSpacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Optimizar ruta")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ACSpacing.md)
                    .background(ACColors.primary)
                    .cornerRadius(ACRadius.md)
                }

                Button(action: onKeepOriginal) {
                    Text("Seguir orden original")
                        .font(ACTypography.labelMedium)
                        .foregroundColor(ACColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ACSpacing.md)
                }
            }
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }
}

// MARK: - Calculating State View
private struct CalculatingStateView: View {
    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            // Animated icon
            ZStack {
                // Pulsing background
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.5 : 1.0)

                // Rotating icon
                Image(systemName: "location.circle")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(ACColors.primary)
                    .rotationEffect(.degrees(rotation))
            }

            // Title
            Text("Calculando ruta...")
                .font(ACTypography.headlineMedium)
                .foregroundColor(ACColors.textPrimary)

            // Subtitle
            Text("Preparando tu ruta personalizada")
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)
                .multilineTextAlignment(.center)

            // Progress indicator
            ProgressView()
                .tint(ACColors.primary)
                .scaleEffect(1.2)
                .padding(.top, ACSpacing.sm)
        }
        .padding(.bottom, ACSpacing.xl)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Route Loading Overlay Global
struct RouteLoadingOverlayGlobal: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)

            VStack(spacing: ACSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ACColors.primary)

                Text("Calculando ruta...")
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)
            }
            .padding(ACSpacing.xl)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.lg)
        }
    }
}

#Preview {
    MainTabView()
}
