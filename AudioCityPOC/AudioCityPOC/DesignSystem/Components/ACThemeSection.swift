//
//  ACThemeSection.swift
//  AudioCityPOC
//
//  Componente de sección de rutas agrupadas por temática
//

import SwiftUI

// MARK: - Theme Section

/// Sección de rutas agrupadas por temática con scroll horizontal
struct ACThemeSection: View {
    let theme: RouteTheme
    let routes: [Route]
    let onSelectRoute: (Route) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header con icono y nombre de la temática
            headerView
                .padding(.horizontal, ACSpacing.containerPadding)

            // Scroll horizontal de rutas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.md) {
                    ForEach(routes) { route in
                        ACCompactRouteCard(
                            title: route.name,
                            subtitle: route.neighborhood,
                            duration: route.durationFormatted,
                            stopsCount: route.numStops,
                            thumbnailUrl: route.thumbnailUrl
                        ) {
                            onSelectRoute(route)
                        }
                    }
                }
                .padding(.horizontal, ACSpacing.containerPadding)
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: ACSpacing.sm) {
            // Icono de la temática
            Image(systemName: theme.icon)
                .font(.system(size: 18))
                .foregroundColor(theme.color)

            // Nombre de la temática
            Text(theme.displayName)
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)

            // Contador de rutas
            Text("\(routes.count)")
                .font(ACTypography.caption)
                .foregroundColor(ACColors.textTertiary)
                .padding(.horizontal, ACSpacing.sm)
                .padding(.vertical, ACSpacing.xxs)
                .background(ACColors.borderLight)
                .cornerRadius(ACRadius.full)

            Spacer()
        }
    }
}

// MARK: - Theme Section Header Only

/// Header de sección de temática (sin rutas, para uso separado)
struct ACThemeSectionHeader: View {
    let theme: RouteTheme
    let count: Int
    var showSeeAll: Bool = false
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            Image(systemName: theme.icon)
                .font(.system(size: 18))
                .foregroundColor(theme.color)

            Text(theme.displayName)
                .font(ACTypography.headlineSmall)
                .foregroundColor(ACColors.textPrimary)

            Text("\(count)")
                .font(ACTypography.caption)
                .foregroundColor(ACColors.textTertiary)
                .padding(.horizontal, ACSpacing.sm)
                .padding(.vertical, ACSpacing.xxs)
                .background(ACColors.borderLight)
                .cornerRadius(ACRadius.full)

            Spacer()

            if showSeeAll, let action = onSeeAll {
                Button(action: action) {
                    HStack(spacing: ACSpacing.xxs) {
                        Text("Ver todas")
                            .font(ACTypography.labelSmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(ACColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Theme Sections") {
    ScrollView {
        VStack(spacing: ACSpacing.sectionSpacing) {
            // Ejemplo con rutas mock
            ACThemeSection(
                theme: .historicas,
                routes: [
                    Route(
                        id: "1",
                        name: "Barrio de las Letras",
                        description: "Recorrido literario",
                        city: "Madrid",
                        neighborhood: "Centro",
                        durationMinutes: 45,
                        distanceKm: 2.5,
                        difficulty: "easy",
                        numStops: 5,
                        language: "es",
                        isActive: true,
                        createdAt: "",
                        updatedAt: "",
                        thumbnailUrl: "",
                        startLocation: Route.Location(latitude: 0, longitude: 0, name: ""),
                        endLocation: Route.Location(latitude: 0, longitude: 0, name: ""),
                        rating: 4.5,
                        usageCount: 200,
                        theme: .historicas
                    ),
                    Route(
                        id: "2",
                        name: "Madrid de los Austrias",
                        description: "Historia real",
                        city: "Madrid",
                        neighborhood: "Sol",
                        durationMinutes: 60,
                        distanceKm: 3.0,
                        difficulty: "medium",
                        numStops: 8,
                        language: "es",
                        isActive: true,
                        createdAt: "",
                        updatedAt: "",
                        thumbnailUrl: "",
                        startLocation: Route.Location(latitude: 0, longitude: 0, name: ""),
                        endLocation: Route.Location(latitude: 0, longitude: 0, name: ""),
                        rating: 4.8,
                        usageCount: 350,
                        theme: .historicas
                    )
                ]
            ) { route in
                print("Selected: \(route.name)")
            }

            // Header standalone
            ACThemeSectionHeader(
                theme: .gastronomicas,
                count: 5,
                showSeeAll: true
            ) {
                print("See all")
            }
            .padding(.horizontal, ACSpacing.containerPadding)
        }
        .padding(.vertical)
    }
    .background(ACColors.background)
}
