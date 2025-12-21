//
//  ProfileView.swift
//  AudioCityPOC
//
//  Vista de perfil/configuración
//

import SwiftUI
import CoreLocation

struct ProfileView: View {
    @StateObject private var locationService = LocationService()
    @EnvironmentObject private var pointsService: PointsService
    @EnvironmentObject private var historyService: HistoryService
    @EnvironmentObject private var authService: AuthService
    @State private var showingPointsHistory = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var isLoggingOut = false
    @State private var isDeletingAccount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ACSpacing.sectionSpacing) {
                    // Sección de cuenta de usuario
                    accountSection

                    // Sección de puntos y nivel
                    pointsSection

                    // Estadísticas rápidas
                    statsSection

                    // Historial de rutas
                    historySection

                    // Información de la app
                    infoSection

                    // Permisos
                    permissionsSection

                    // Debug info
                    debugSection

                    Spacer(minLength: ACSpacing.mega)
                }
                .padding(.top, ACSpacing.base)
            }
            .background(ACColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPointsHistory) {
                PointsHistoryView()
            }
            .alert("Cerrar sesión", isPresented: $showingLogoutConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    logout()
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
            .alert("Eliminar cuenta", isPresented: $showingDeleteAccountConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar cuenta", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Esta acción es irreversible. Se eliminarán todos tus datos, rutas creadas, historial y puntos.")
            }
        }
        .onAppear {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocationPermission()
            }
        }
        .overlay {
            // Notificación de level up
            if let newLevel = pointsService.recentLevelUp {
                LevelUpNotification(level: newLevel) {
                    pointsService.clearLevelUpNotification()
                }
            }
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: ACSpacing.lg) {
            // Información del usuario
            HStack(alignment: .center, spacing: ACSpacing.lg) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(ACColors.primaryLight)
                        .frame(width: 80, height: 80)

                    if let photoURL = authService.currentUser?.photoURL,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(ACColors.primary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundColor(ACColors.primary)
                    }
                }

                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    Text(authService.currentUser?.displayName ?? "Usuario")
                        .font(ACTypography.headlineLarge)
                        .foregroundColor(ACColors.textPrimary)

                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(ACTypography.bodySmall)
                            .foregroundColor(ACColors.textSecondary)
                    }

                    // Proveedor de autenticación
                    HStack(spacing: ACSpacing.xs) {
                        Image(systemName: providerIcon)
                            .font(.system(size: 12))
                        Text(providerName)
                            .font(ACTypography.caption)
                    }
                    .foregroundColor(ACColors.textTertiary)
                }

                Spacer()
            }

            // Botones de acción
            VStack(spacing: ACSpacing.sm) {
                // Cerrar sesión
                Button(action: { showingLogoutConfirmation = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(ACColors.warning)
                        Text("Cerrar sesión")
                            .font(ACTypography.labelMedium)
                            .foregroundColor(ACColors.textPrimary)
                        Spacer()
                        if isLoggingOut {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(ACColors.textTertiary)
                        }
                    }
                    .padding(ACSpacing.md)
                    .background(ACColors.background)
                    .cornerRadius(ACRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoggingOut)

                // Eliminar cuenta
                Button(action: { showingDeleteAccountConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(ACColors.error)
                        Text("Eliminar cuenta")
                            .font(ACTypography.labelMedium)
                            .foregroundColor(ACColors.error)
                        Spacer()
                        if isDeletingAccount {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(ACColors.textTertiary)
                        }
                    }
                    .padding(ACSpacing.md)
                    .background(ACColors.background)
                    .cornerRadius(ACRadius.md)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isDeletingAccount)
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
        .padding(.horizontal, ACSpacing.containerPadding)
    }

    // MARK: - Points Section
    private var pointsSection: some View {
        VStack(spacing: ACSpacing.lg) {
            // Nivel y puntos
            HStack(alignment: .center, spacing: ACSpacing.lg) {
                // Icono de nivel
                ZStack {
                    Circle()
                        .fill(levelColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: pointsService.stats.currentLevel.icon)
                        .font(.system(size: 36))
                        .foregroundColor(levelColor)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    Text(pointsService.stats.currentLevel.name)
                        .font(ACTypography.headlineLarge)
                        .foregroundColor(ACColors.textPrimary)

                    HStack(spacing: ACSpacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(ACColors.gold)
                            .font(.system(size: 14))
                        Text("\(pointsService.stats.totalPoints) puntos")
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textSecondary)
                    }
                }

                Spacer()
            }

            // Barra de progreso al siguiente nivel
            if let nextLevel = pointsService.stats.currentLevel.nextLevel {
                VStack(alignment: .leading, spacing: ACSpacing.sm) {
                    HStack {
                        Text("Siguiente: \(nextLevel.name)")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textSecondary)
                        Spacer()
                        Text("\(pointsService.stats.pointsToNextLevel) pts")
                            .font(ACTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ACColors.textSecondary)
                    }

                    ACProgressBar(
                        progress: pointsService.stats.progressToNextLevel,
                        height: 8,
                        color: levelColor
                    )
                }
            } else {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(ACColors.gold)
                    Text("¡Has alcanzado el nivel máximo!")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.success)
                        .fontWeight(.medium)
                }
            }

            // Botón para ver historial
            Button(action: { showingPointsHistory = true }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(ACColors.primary)
                    Text("Ver historial de puntos")
                        .font(ACTypography.labelMedium)
                        .foregroundColor(ACColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(ACColors.textTertiary)
                }
                .padding(ACSpacing.md)
                .background(ACColors.background)
                .cornerRadius(ACRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
        .padding(.horizontal, ACSpacing.containerPadding)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            Text("Estadísticas")
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)
                .padding(.horizontal, ACSpacing.containerPadding)

            HStack(spacing: ACSpacing.md) {
                ACETACard(
                    value: "\(pointsService.stats.routesCreated)",
                    unit: "",
                    label: "Creadas",
                    icon: "map.fill",
                    color: ACColors.info
                )

                ACETACard(
                    value: "\(pointsService.stats.routesCompleted)",
                    unit: "",
                    label: "Completadas",
                    icon: "checkmark.circle.fill",
                    color: ACColors.success
                )

                ACETACard(
                    value: "\(pointsService.stats.currentStreak)",
                    unit: "",
                    label: "Racha",
                    icon: "flame.fill",
                    color: ACColors.warning
                )
            }
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }

    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack {
                HStack(spacing: ACSpacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(ACColors.info)

                    Text("Historial")
                        .font(ACTypography.headlineSmall)
                        .foregroundColor(ACColors.textPrimary)
                }

                Spacer()

                if !historyService.history.isEmpty {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        HStack(spacing: ACSpacing.xxs) {
                            Text("Ver todo")
                                .font(ACTypography.labelSmall)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(ACColors.primary)
                    }
                }
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Stats
            ACHistoryStatsRow(stats: historyService.getStats())
                .padding(.horizontal, ACSpacing.containerPadding)

            // Recent routes (max 3)
            if !historyService.history.isEmpty {
                VStack(spacing: ACSpacing.sm) {
                    ForEach(Array(historyService.history.prefix(3))) { record in
                        ACHistoryRecordCard(record: record)
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            } else {
                // Empty state
                HStack(spacing: ACSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(ACColors.infoLight)
                            .frame(width: 48, height: 48)

                        Image(systemName: "map")
                            .font(.system(size: 20))
                            .foregroundColor(ACColors.info)
                    }

                    VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                        Text("Sin rutas completadas")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textPrimary)

                        Text("Aquí aparecerán las rutas que completes")
                            .font(ACTypography.bodySmall)
                            .foregroundColor(ACColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(ACSpacing.cardPadding)
                .background(ACColors.surface)
                .cornerRadius(ACRadius.lg)
                .acShadow(ACShadow.sm)
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            Text("Información")
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)
                .padding(.horizontal, ACSpacing.containerPadding)

            HStack {
                HStack(spacing: ACSpacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundColor(ACColors.info)
                    Text("Versión")
                        .font(ACTypography.bodyMedium)
                        .foregroundColor(ACColors.textPrimary)
                }
                Spacer()
                Text("1.0.0")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
            }
            .padding(ACSpacing.cardPadding)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }

    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            Text("Permisos")
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)
                .padding(.horizontal, ACSpacing.containerPadding)

            VStack(spacing: ACSpacing.sm) {
                HStack {
                    HStack(spacing: ACSpacing.sm) {
                        Image(systemName: "location.fill")
                            .foregroundColor(locationStatusColor)
                        Text("Ubicación")
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)
                    }
                    Spacer()
                    ACStatusBadge(
                        text: locationStatusText,
                        status: locationBadgeStatus
                    )
                }

                if locationService.authorizationStatus != .authorizedAlways {
                    ACButton("Solicitar permisos", icon: "location.circle.fill", style: .secondary, size: .small, isFullWidth: true) {
                        locationService.requestLocationPermission()
                    }
                }
            }
            .padding(ACSpacing.cardPadding)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }

    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            Text("Debug")
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)
                .padding(.horizontal, ACSpacing.containerPadding)

            VStack(alignment: .leading, spacing: ACSpacing.md) {
                if let userLocation = locationService.userLocation {
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        Text("Ubicación actual")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                        Text("Lat: \(String(format: "%.6f", userLocation.coordinate.latitude))")
                            .font(ACTypography.captionSmall)
                            .foregroundColor(ACColors.textSecondary)
                        Text("Lon: \(String(format: "%.6f", userLocation.coordinate.longitude))")
                            .font(ACTypography.captionSmall)
                            .foregroundColor(ACColors.textSecondary)
                    }
                }

                HStack {
                    Text("Tracking activo")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textPrimary)
                    Spacer()
                    ACStatusBadge(
                        text: locationService.isTracking ? "Sí" : "No",
                        status: locationService.isTracking ? .active : .error
                    )
                }
            }
            .padding(ACSpacing.cardPadding)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }

    // MARK: - Computed Properties

    private var levelColor: Color {
        switch pointsService.stats.currentLevel {
        case .explorer: return ACColors.Levels.explorer
        case .traveler: return ACColors.Levels.traveler
        case .localGuide: return ACColors.Levels.localGuide
        case .expert: return ACColors.Levels.expert
        case .master: return ACColors.Levels.master
        }
    }

    private var locationStatusText: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "Siempre"
        case .authorizedWhenInUse:
            return "Al usar la app"
        case .denied, .restricted:
            return "Denegado"
        case .notDetermined:
            return "No determinado"
        @unknown default:
            return "Desconocido"
        }
    }

    private var locationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return ACColors.success
        case .authorizedWhenInUse:
            return ACColors.warning
        case .denied, .restricted:
            return ACColors.error
        case .notDetermined:
            return ACColors.textTertiary
        @unknown default:
            return ACColors.textTertiary
        }
    }

    private var locationBadgeStatus: ACStatusBadge.BadgeStatus {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .active
        case .authorizedWhenInUse:
            return .pending
        case .denied, .restricted:
            return .error
        case .notDetermined:
            return .inactive
        @unknown default:
            return .inactive
        }
    }

    private var providerIcon: String {
        guard let provider = authService.currentUser?.authProvider else {
            return "person.circle"
        }
        switch provider {
        case .apple:
            return "apple.logo"
        case .google:
            return "g.circle"
        case .email:
            return "envelope.fill"
        }
    }

    private var providerName: String {
        guard let provider = authService.currentUser?.authProvider else {
            return "Cuenta"
        }
        switch provider {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .email:
            return "Email"
        }
    }

    // MARK: - Actions

    private func logout() {
        isLoggingOut = true
        do {
            try authService.signOut()
        } catch {
            Log("Error al cerrar sesión: \(error.localizedDescription)", level: .error, category: .auth)
        }
        isLoggingOut = false
    }

    private func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await authService.deleteAccount()
            } catch {
                Log("Error al eliminar cuenta: \(error.localizedDescription)", level: .error, category: .auth)
            }
            isDeletingAccount = false
        }
    }
}

// MARK: - Level Up Notification
struct LevelUpNotification: View {
    let level: UserLevel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            Spacer()

            VStack(spacing: ACSpacing.lg) {
                // Icono con efecto de brillo
                ZStack {
                    Circle()
                        .fill(ACColors.gold.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(ACColors.gold.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: level.icon)
                        .font(.system(size: 50))
                        .foregroundColor(ACColors.gold)
                }

                VStack(spacing: ACSpacing.sm) {
                    Text("¡Nivel alcanzado!")
                        .font(ACTypography.headlineMedium)
                        .foregroundColor(ACColors.textPrimary)

                    Text(level.name)
                        .font(ACTypography.displayMedium)
                        .foregroundColor(ACColors.gold)
                }

                ACButton("Continuar", style: .primary, size: .large, isFullWidth: true) {
                    onDismiss()
                }
            }
            .padding(ACSpacing.xxl)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.xxl)
            .acShadow(ACShadow.xl)
            .padding(.horizontal, ACSpacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Points History View
struct PointsHistoryView: View {
    @EnvironmentObject private var pointsService: PointsService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if pointsService.transactions.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .background(ACColors.background)
            .navigationTitle("Historial de Puntos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(ACColors.primary)
                }
            }
        }
    }

    private var emptyStateView: some View {
        ACEmptyState(
            icon: "star.circle",
            title: "Sin actividad",
            description: "Completa rutas y crea contenido para ganar puntos"
        )
    }

    private var historyList: some View {
        ScrollView {
            VStack(spacing: ACSpacing.sectionSpacing) {
                // Resumen
                HStack {
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        Text("Total acumulado")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                        HStack(spacing: ACSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(ACColors.gold)
                            Text("\(pointsService.stats.totalPoints) puntos")
                                .font(ACTypography.headlineLarge)
                                .foregroundColor(ACColors.textPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: ACSpacing.xs) {
                        Text("Nivel actual")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                        HStack(spacing: ACSpacing.xs) {
                            Image(systemName: pointsService.stats.currentLevel.icon)
                            Text(pointsService.stats.currentLevel.name)
                        }
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)
                    }
                }
                .padding(ACSpacing.cardPadding)
                .background(ACColors.surface)
                .cornerRadius(ACRadius.lg)
                .padding(.horizontal, ACSpacing.containerPadding)

                // Transacciones agrupadas por fecha
                ForEach(pointsService.getTransactionsGroupedByDate(), id: \.date) { group in
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text(group.date)
                            .font(ACTypography.headlineSmall)
                            .foregroundColor(ACColors.textPrimary)
                            .padding(.horizontal, ACSpacing.containerPadding)

                        VStack(spacing: ACSpacing.sm) {
                            ForEach(group.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding(.horizontal, ACSpacing.containerPadding)
                    }
                }

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.base)
        }
        .background(ACColors.background)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: PointsTransaction

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Icono
            ZStack {
                Circle()
                    .fill(ACColors.infoLight)
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.action.icon)
                    .font(.system(size: 16))
                    .foregroundColor(ACColors.info)
            }

            // Contenido
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(transaction.action.displayName)
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)

                if let routeName = transaction.routeName {
                    Text(routeName)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Puntos
            Text("+\(transaction.points)")
                .font(ACTypography.titleMedium)
                .foregroundColor(ACColors.success)
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.md)
    }
}

#Preview {
    ProfileView()
}
